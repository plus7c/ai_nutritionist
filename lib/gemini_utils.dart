import 'package:firebase_vertexai/firebase_vertexai.dart';
final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');
Future<String> generateOutputFromGemini(String prompt) async {

  final promptVal =  [Content.text(prompt)];
  final response = await model.generateContent(promptVal);
  String? aiResponse = response.text;
  return aiResponse!;
}

GenerativeModel getGeminiInstance(){
  return model;
}
