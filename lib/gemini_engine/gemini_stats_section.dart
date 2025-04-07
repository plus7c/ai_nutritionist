import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

// 千问模型客户端
final Dio _dio = Dio();

// API配置类
class AIConfig {
  static String get apiKey => dotenv.env['DASHSCOPE_API_KEY'] ?? '';
  static const String baseUrl = 'https://dashscope.aliyuncs.com/compatible-mode/v1';
}

// 生成AI响应
Future<String> generateAIResponse(String prompt) async {
  try {
    final response = await _dio.post(
      '${AIConfig.baseUrl}/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${AIConfig.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': 'qwen-plus',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful assistant.'
          },
          {
            'role': 'user',
            'content': prompt
          }
        ]
      },
    );
    
    if (response.statusCode == 200) {
      final data = response.data;
      return data['choices'][0]['message']['content'] ?? '无法获取回复';
    } else {
      throw Exception('API请求失败: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('千问API调用出错: $e');
    throw Exception('千问API调用出错: $e');
  }
}

// 营养建议
Future<String> getNutritionRecommendation(double protein, double fats, double carbs) async {
  // 保留模拟功能开关，默认关闭
  bool useMock = false;
  if (useMock) {
    return "使用模拟实现分析营养数据";
  }
  
  String prompt = """
  分析以下营养摄入数据并提供个性化建议，重点关注营养均衡和任何营养不足或过量的情况。
  建议内容请控制在600字以内。
    
  营养数据:
  - 蛋白质: $protein 克
  - 脂肪: $fats 克
  - 碳水化合物: $carbs 克
    
  请提供具体可行的建议来改善用户的饮食习惯。
  """;

  return await generateAIResponse(prompt);
}

// BMI建议
Future<String> getBMIRecommendation(double bmi) async {
  String prompt = """
  分析以下体重指数(BMI)数值并提供个性化建议，重点关注如何维持或达到健康的BMI值。
  建议内容请控制在100字以内。
  
  BMI值: $bmi
    
  请提供具体可行的建议来改善用户的健康状况。
  """;

  return await generateAIResponse(prompt);
}

// 分析食物图片
Future<String> analyzeFood(String base64Image) async {
  try {
    final response = await _dio.post(
      '${AIConfig.baseUrl}/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${AIConfig.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': 'qwen-vl-max',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful assistant.'
          },
          {
            'role': 'user',
            'content': '这是什么食物？请详细描述其营养成分和卡路里含量。'
          },
          {
            'role': 'user',
            'content': base64Image
          }
        ]
      },
    );
    
    if (response.statusCode == 200) {
      final data = response.data;
      return data['choices'][0]['message']['content'] ?? '无法分析图片';
    } else {
      throw Exception('API请求失败: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('千问图像分析API调用出错: $e');
    throw Exception('千问图像分析API调用出错: $e');
  }
}
