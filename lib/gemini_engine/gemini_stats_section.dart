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

Future<String> getGeminiRecommendationForStats(double protein, double fats, double carbs) async {
  String prompt = """
  Analyze the following nutrient intake data for today and provide a personalized recommendation based on the nutritional needs. 
  The recommendation should be focused on maintaining a balanced diet and addressing any deficiencies or excesses. 
  Keep the recommendation within 600 characters.
    
    Nutrient Data:
    - Protein: ${protein} grams
    - Fats: ${fats} grams
    - Carbs: ${carbs} grams
    
    Please provide actionable and concise advice to improve the user's dietary habits.

  """;
  final promptVal =  [Content.text(prompt)];
  final response = await model.generateContent(promptVal);
  String? aiResponse = response.text;
  return aiResponse!;
}

Future<String> getGeminiRecommendationForBMI(double bmi) async {
  String prompt = """
  Analyze the following Body Mass Index (BMI) value and provide a personalized recommendation based on the user's health status. 
  The recommendation should be focused on maintaining or achieving a healthy BMI and addressing any potential health concerns. 
  Keep the recommendation within 100 characters.
  
    BMI Value: ${bmi}
    
    Please provide actionable and concise advice to improve the user's health and well-being.

  """;
  final promptVal =  [Content.text(prompt)];
  final response = await model.generateContent(promptVal);
  String? aiResponse = response.text;
  return aiResponse!;
}
