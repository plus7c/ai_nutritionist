import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../prompt.dart';
import '../gemini_engine/gemini_stats_section.dart' as tongyi;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  late types.User _user;
  final _aiUser = const types.User(
    id: 'ai',
    firstName: 'AI',
    lastName: '',
  );
  final _nutritionistPrompt = NutritionistPrompt();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    auth.User? firebaseUser = _auth.currentUser;
    firebaseUser ??= (await _auth.signInAnonymously()) as auth.User?;
    setState(() {
      _user = types.User(
        id: firebaseUser!.uid,
        firstName: firebaseUser.displayName ?? 'User',
      );
    });
    _loadMessages();
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
    _saveMessageToFirestore(message);
    if (message.author.id == _user.id) {
      _generateAIResponse(message);
    }
  }

  Future<void> _saveMessageToFirestore(types.Message message) async {
    try {
      if (_auth.currentUser == null) {
        print('无法保存消息到 Firestore：用户未登录');
        return;
      }
      
      print('正在保存消息到 Firestore，用户ID: ${_user.id}');
      Map<String, dynamic> messageData = {
        'author': message.author.toJson(),
        'createdAt': message.createdAt,
        'id': message.id,
        'type': message.type.name,
        'data': message is types.TextMessage ? {'text': message.text} : null,
      };
      
      await _firestore.collection('users').doc(_user.id).collection('messages').add(messageData);
      print('消息保存成功');
    } catch (e) {
      print('保存消息到 Firestore 失败: $e');
      // 不抛出异常，以免影响用户体验
    }
  }

  Future<void> _generateAIResponse(types.Message userMessage) async {
    try {
      if (_auth.currentUser == null) {
        print('错误: 没有用户登录');
        _addMessage(types.TextMessage(
          author: _aiUser,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: AppLocalizations.of(context)!.noUserSignedInText,
        ));
        return;
      }

      print('正在生成提示...');
      String generatedPrompt = await _nutritionistPrompt.generatePrompt((userMessage as types.TextMessage).text);
      print('提示生成完成，长度: ${generatedPrompt.length}');
      
      // 添加一个临时消息，用于显示响应
      String tempMessageId = const Uuid().v4();
      _addMessage(types.TextMessage(
        author: _aiUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: tempMessageId,
        text: '',
      ));

      print('开始调用千问API');
      try {
        // 调用千问API获取回复
        String fullResponse = await tongyi.generateAIResponse(generatedPrompt);
        print('收到千问API响应，长度: ${fullResponse.length}');

        // 更新消息内容
        setState(() {
          final index = _messages.indexWhere((m) => m.id == tempMessageId);
          if (index != -1) {
            _messages[index] = (_messages[index] as types.TextMessage).copyWith(
              text: fullResponse,
            );
          }
        });
        
        if (fullResponse.isEmpty) {
          print('警告: 响应为空');
          setState(() {
            final index = _messages.indexWhere((m) => m.id == tempMessageId);
            if (index != -1) {
              _messages[index] = (_messages[index] as types.TextMessage).copyWith(
                text: AppLocalizations.of(context)!.responseGenerationFailedText,
              );
            }
          });
        } else {
          print('成功生成响应，长度: ${fullResponse.length}');
          _nutritionistPrompt.addAssistantResponse(fullResponse);
          
          try {
            print('尝试保存消息到 Firestore');
            await _saveMessageToFirestore(_messages.first);
            print('消息保存成功');
          } catch (e) {
            print('保存消息到 Firestore 失败: $e');
            // 即使保存失败，也不影响聊天功能
          }
        }
      } catch (e) {
        print('千问API调用出错: $e');
        setState(() {
          final index = _messages.indexWhere((m) => m.id == tempMessageId);
          if (index != -1) {
            _messages[index] = (_messages[index] as types.TextMessage).copyWith(
              text: AppLocalizations.of(context)!.errorGeneratingResponseText,
            );
          }
        });
      }
    } catch (e) {
      print('生成 AI 响应时出错: $e');
      if (e.toString().contains('permission-denied')) {
        print('Firestore 权限错误，可能需要更新安全规则');
      }
      
      _addMessage(types.TextMessage(
        author: _aiUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: AppLocalizations.of(context)!.errorGeneratingResponseText,
      ));
    }
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(AppLocalizations.of(context)!.photoButtonText),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(AppLocalizations.of(context)!.fileButtonText),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(AppLocalizations.of(context)!.cancelButtonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index = _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage = (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index = _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage = (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
      types.TextMessage message,
      types.PreviewData previewData,
      ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);
  }

  void _loadMessages() async {
    try {
      print('开始加载消息历史');
      
      // 检查用户是否已登录
      if (_auth.currentUser == null) {
        print('错误: 用户未登录，无法加载消息');
        return;
      }
      
      print('正在从 Firestore 加载消息，用户ID: ${_user.id}');
      
      // 修正 Firestore 路径 - 从 users 集合中获取消息，而不是 chats
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')  // 修改这里，使用与 _saveMessageToFirestore 相同的路径
          .doc(_user.id)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      print('成功获取消息，数量: ${snapshot.docs.length}');

      List<types.Message> loadedMessages = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          if (data['type'] == 'text') {
            return types.TextMessage(
              author: types.User.fromJson(data['author']),
              createdAt: data['createdAt'],
              id: data['id'],
              text: data['data']['text'],
            );
          }
          // Handle other message types if needed
          return types.TextMessage(
            author: types.User.fromJson(data['author']),
            createdAt: data['createdAt'],
            id: data['id'],
            text: 'Unsupported message type',
          );
        } catch (e) {
          print('解析消息时出错: $e');
          // 返回一个占位消息，避免整个列表加载失败
          return types.TextMessage(
            author: _aiUser,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            id: const Uuid().v4(),
            text: 'Error loading message',
          );
        }
      }).toList();

      if (loadedMessages.isEmpty) {
        print('没有找到历史消息，添加欢迎消息');
        types.Message aiGreetingMessage = types.TextMessage(
          author: _aiUser,
          id: const Uuid().v4(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          text: AppLocalizations.of(context)!.aiGreeting,
        );
        loadedMessages.add(aiGreetingMessage);
        
        try {
          await _saveMessageToFirestore(aiGreetingMessage);
        } catch (e) {
          print('保存欢迎消息失败: $e');
          // 继续执行，不影响用户体验
        }
      }

      setState(() {
        _messages = loadedMessages;
      });
      print('消息加载完成');
    } catch (e) {
      print('加载消息时出错: $e');
      // 如果加载失败，至少显示一个欢迎消息
      setState(() {
        _messages = [
          types.TextMessage(
            author: _aiUser,
            id: const Uuid().v4(),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            text: AppLocalizations.of(context)!.aiGreeting,
          )
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      flexibleSpace: Container(
      ),
      centerTitle: true,
      title: Text(AppLocalizations.of(context)!.chatPageTitle),
      leading: const Icon(Icons.health_and_safety),
      elevation: 8,
    ),
    body: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Chat(
        messages: _messages,
        onAttachmentPressed: _handleAttachmentPressed,
        onMessageTap: _handleMessageTap,
        onPreviewDataFetched: _handlePreviewDataFetched,
        onSendPressed: _handleSendPressed,
        showUserAvatars: true,
        showUserNames: true,
        user: _user,
        theme: DefaultChatTheme(
          backgroundColor: Colors.transparent,
          primaryColor: Colors.green,
          // secondaryColor: Colors.purple[100]!,
          userAvatarNameColors: const [Colors.green, Colors.green, Colors.orange],
          inputBackgroundColor: Colors.grey[200]!,
          inputTextColor: Colors.black87,
          inputTextCursorColor: Colors.green,
          messageBorderRadius: 20,
          sendButtonIcon: const Icon(Icons.send, color: Colors.green),
          deliveredIcon: const Icon(Icons.check_circle, color: Colors.green),
          errorColor: Colors.redAccent,
          seenIcon: const Icon(Icons.remove_red_eye, color: Colors.greenAccent),
        ),
      ),
    ),
  );
}