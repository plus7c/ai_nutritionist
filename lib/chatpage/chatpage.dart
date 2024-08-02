import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pizza_ordering_app/prompt.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  late types.User _user;
  final _aiUser = const types.User(
    id: 'gemini-ai',
    firstName: 'Gemini',
    lastName: 'AI',
  );
  var _nutritionistPrompt = NutritionistPrompt();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    auth.User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      // If not signed in, sign in anonymously
      firebaseUser = (await _auth.signInAnonymously()) as auth.User?;
    }
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
    await _firestore.collection('users').doc(_user.id).collection('messages').add({
      'author': message.author.toJson(),
      'createdAt': message.createdAt,
      'id': message.id,
      'type': message.type.name,
      'data': message is types.TextMessage ? {'text': message.text} : null,
    });
  }

  Future<void> _generateAIResponse(types.Message userMessage) async {
    final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');

    String generatedPrompt = await _nutritionistPrompt.generatePrompt((userMessage as types.TextMessage).text);
    final prompt = [Content.text(generatedPrompt)];

    try {
      final responseStream = await model.generateContentStream(prompt);

      String fullResponse = '';
      String tempMessageId = const Uuid().v4();

      _addMessage(types.TextMessage(
        author: _aiUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: tempMessageId,
        text: '',
      ));

      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          fullResponse += chunk.text!;

          setState(() {
            final index = _messages.indexWhere((m) => m.id == tempMessageId);
            if (index != -1) {
              _messages[index] = (_messages[index] as types.TextMessage).copyWith(
                text: fullResponse,
              );
            }
          });
        }
      }

      if (fullResponse.isEmpty) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == tempMessageId);
          if (index != -1) {
            _messages[index] = (_messages[index] as types.TextMessage).copyWith(
              text: "I'm sorry, I couldn't generate a response. Please try again.",
            );
          }
        });
      } else {
        _nutritionistPrompt.addAssistantResponse(fullResponse);
        _saveMessageToFirestore(_messages.first);
      }
    } catch (e) {
      print('Error generating AI response: $e');
      _addMessage(types.TextMessage(
        author: _aiUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: "An error occurred while generating a response. Please try again later.",
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
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
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
    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('chats')
        .doc(_user.id)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    List<types.Message> loadedMessages = snapshot.docs.map((doc) {
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
    }).toList();

    if (loadedMessages.isEmpty) {
      types.Message aiGreetingMessage = types.TextMessage(
        author: _aiUser,
        id: const Uuid().v4(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        text: 'Hi there! I\'m your AI Nutrition assistant. Ready to start your journey towards a healthier you. How can I be of help? 😊',
      );
      loadedMessages.add(aiGreetingMessage);
      _saveMessageToFirestore(aiGreetingMessage);
    }

    setState(() {
      _messages = loadedMessages;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      flexibleSpace: Container(
      ),
      centerTitle: true,
      title: Text(
        'AI Nutrition Assistant',
        style: TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
      leading: Icon(Icons.health_and_safety),
      elevation: 8,
    ),
    body: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background_image.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.7),
            BlendMode.lighten,
          ),
        ),
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
          userAvatarNameColors: [Colors.green, Colors.green, Colors.orange],
          inputBackgroundColor: Colors.grey[200]!,
          inputTextColor: Colors.black87,
          inputTextCursorColor: Colors.green,
          messageBorderRadius: 20,
          sendButtonIcon: Icon(Icons.send, color: Colors.green),
          deliveredIcon: Icon(Icons.check_circle, color: Colors.green),
          errorColor: Colors.redAccent,
          seenIcon: Icon(Icons.remove_red_eye, color: Colors.greenAccent),
        ),
      ),
    ),
  );
}