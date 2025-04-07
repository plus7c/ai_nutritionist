import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firestore_helper.dart';
import '../gemini_engine/gemini_stats_section.dart' as tongyi;
import '../stats/bmi.dart';
import 'dart:async';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirestoreService _firestoreService = FirestoreService();

Future<String> getBMIRecommendation({bool triggeredFromProfilePage = false}) async {
  DateTime now = DateTime.now();
  String userId = _auth.currentUser!.uid;

  try {
    // Reference to the user's document
    DocumentReference userDocRef = _firestore.collection('users').doc(userId);

    // Fetch the healthstatus document
    DocumentSnapshot healthStatusDoc = await userDocRef.collection('healthstatus').doc('bmirecommendation').get();
    var userData = await _firestoreService.getUserData(userId);
    Map<String, dynamic> heightData = userData?['height'];
    int feet = heightData['feet'];
    int inches = heightData['inches'];
    int totalHeightInches = (feet * 12) + inches;
    var bmi = calculateBMI(userData?['weight'], totalHeightInches);

    if(triggeredFromProfilePage)
    {
        // 使用千问API获取BMI建议
        String aiRecommendation = await tongyi.getBMIRecommendation(bmi);
        await userDocRef.collection('healthstatus').doc('bmirecommendation').set({
          'lastupdatedtime': now,
          'recommendationstring': aiRecommendation,
        });
        return '';
    }

    if (!healthStatusDoc.exists) {
      // If the document doesn't exist, create it with initial values
      // 使用千问API获取BMI建议
      String aiRecommendation = await tongyi.getBMIRecommendation(bmi);
      await userDocRef.collection('healthstatus').doc('bmirecommendation').set({
        'lastupdatedtime': now,
        'recommendationstring': aiRecommendation,
      });
      return aiRecommendation;
    } else {
      // Document exists, check the lastupdatedtime
      Map<String, dynamic> data = healthStatusDoc.data() as Map<String, dynamic>;
      Timestamp lastUpdated = data['lastupdatedtime'] as Timestamp;
      String recommendation = data['recommendationstring'] as String;

      // Check if the last update was more than 24 hours ago
      if (now.difference(lastUpdated.toDate()).inHours > 24) {
        // 使用千问API获取BMI建议
        String aiRecommendation = await tongyi.getBMIRecommendation(bmi);
        // If more than 24 hours, update the lastupdatedtime and generate a new recommendation
        await userDocRef.collection('healthstatus').doc('bmirecommendation').update({
          'lastupdatedtime': now,
          'recommendationstring': aiRecommendation,
        });
        return '已更新BMI建议: $aiRecommendation';
      } else {
        // If less than 24 hours, return the existing recommendation
        return recommendation;
      }
    }
  } catch (e) {
    print('获取BMI建议时出错: $e');
    return '获取建议时出错，请稍后再试。';
  }
}

class HealthStatus {
  final int score;
  final String recommendation;
  final bool errors;

  HealthStatus({required this.score, required this.recommendation, required this.errors});
}

Future<HealthStatus> analyzeHealth(Map<String, dynamic> healthData) async {
  String prompt = """
    分析以下健康数据并提供：
    1. 健康评分（0-100）
    2. 详细建议（约3-4句话）

    用户健康数据：
    - 用户名：${healthData['username']}
    - 性别：${healthData['gender']}
    - 出生日期：${healthData['dateOfBirth']}
    - 体重：${healthData['weight']} 磅
    - 身高：${healthData['height']['feet']} 英尺 ${healthData['height']['inches']} 英寸
    - 目标：${healthData['goals'].join(', ')}

    请按照以下格式返回结果（即使发现错误）：
    评分：[数字评分]
    建议：[详细建议]
    错误：true/false
    """;

  // 调用千问API
  String aiResponse;
  try {
    aiResponse = await tongyi.generateAIResponse(prompt);
  } catch (e) {
    throw Exception('调用千问API失败: $e');
  }

  if (aiResponse.isEmpty) {
    throw Exception('无法从千问获取响应');
  }

  // 解析AI响应
  List<String> lines = aiResponse.split('\n');
  int score = 0;
  String recommendation = '';
  bool errors = false;

  for (var line in lines) {
    if (line.startsWith('评分:')) {
      score = int.tryParse(line.split(':')[1].trim()) ?? 0;
    } else if (line.startsWith('建议:')) {
      recommendation = line.split(':')[1].trim();
    } else if (line.startsWith('错误:')) {
      errors = line.split(':')[1].trim() == 'true';
    }
  }

  return HealthStatus(
    score: score,
    recommendation: recommendation,
    errors: errors,
  );
}

Future<HealthStatus> getOverallHealthStatus() async {
  String userId = _auth.currentUser!.uid;
  DateTime now = DateTime.now();
  
  try {
    var userData = await _firestoreService.getUserData(userId);
    if (userData == null) {
      throw Exception('无法获取用户数据');
    }

    // 检查是否有现有的健康状态记录
    DocumentSnapshot healthStatusDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('healthstatus')
        .doc('overallstatus')
        .get();

    // 如果不存在或者上次更新超过24小时，则生成新的健康状态
    if (!healthStatusDoc.exists || 
        now.difference((healthStatusDoc.data() as Map<String, dynamic>)['lastupdatedtime'].toDate()).inHours > 24) {
      
      // 准备健康数据
      Map<String, dynamic> healthData = {
        'username': userData['username'],
        'gender': userData['gender'],
        'dateOfBirth': userData['dateOfBirth'],
        'weight': userData['weight'],
        'height': userData['height'],
        'goals': userData['goals'],
        'allergies': userData['allergies'],
      };

      // 调用千问API获取健康分析
      HealthStatus newStatus = await analyzeHealth(healthData);

      // 更新Firestore的健康状态
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('healthstatus')
          .doc('overallstatus')
          .set({
        'score': newStatus.score,
        'recommendation': newStatus.recommendation,
        'lastupdatedtime': now,
        'errors': newStatus.errors,
      });

      return newStatus;
    } else {
      // 使用现有的健康状态
      Map<String, dynamic> data = healthStatusDoc.data() as Map<String, dynamic>;
      return HealthStatus(
        score: data['score'],
        recommendation: data['recommendation'],
        errors: data['errors'] ?? false,
      );
    }
  } catch (e) {
    print('获取整体健康状态时出错: $e');
    return HealthStatus(score: 0, recommendation: '获取健康状态时出错，请稍后再试。', errors: true);
  }
}