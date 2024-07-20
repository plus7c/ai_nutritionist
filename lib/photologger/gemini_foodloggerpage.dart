import 'dart:typed_data';
import 'package:firebase_vertexai/firebase_vertexai.dart';

final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');

class GeminiFoodLogger {
  static Future<String> callGemini(String type, Uint8List imageBytes) async {
    String prompt;
    switch (type) {
      case 'allergen':
        prompt = "Analyze this food image for potential allergens. "
            "Identify and list all visible ingredients that are common allergens, "
            "such as nuts, dairy, eggs, soy, wheat, fish, and shellfish. "
            "If any of these are present, highlight them. "
            "Also, note any potential cross-contamination risks based on the food's preparation or "
            "presentation. Provide a clear, concise list of allergen warnings for this dish.";
        break;
      case 'nutrients':
        prompt = "Provide a comprehensive nutritional analysis of the food in this image. "
            "Break down the macro and micronutrients, including protein, carbohydrates "
            "(specifying simple and complex), fats (distinguishing between saturated, unsaturated, "
            "and trans fats), fiber, vitamins (A, B complex, C, D, E, K), and minerals "
            "(calcium, iron, potassium, magnesium, zinc). Estimate portion size and "
            "provide approximate calorie count. If possible, compare the nutritional value "
            "to daily recommended intake percentages.";
        break;
      case 'learn':
        prompt = "Offer an educational overview of the food shown in this image. "
            "Include its origin, cultural significance, common preparation methods, "
            "and how it fits into various cuisines. Discuss any health benefits or "
            "concerns associated with this food. Explain its role in a balanced diet "
            "and any interesting scientific facts about its composition or effects on the body.";
        break;
      case 'fun_facts':
        prompt = "Provide engaging and surprising facts about the food in this image. "
            "Include historical anecdotes, unusual uses, record-breaking statistics, "
            "or quirky trivia. Discuss any myths or misconceptions about this food and "
            "provide scientific explanations to debunk or confirm them. Mention any "
            "appearances of this food in pop culture, literature, or art.";
        break;
      case 'generate_dish':
        prompt = "Based on the contents visible in this refrigerator image, "
            "suggest a creative, nutritionally balanced dish. Consider dietary preferences "
            "(vegetarian, vegan, low-carb, etc.) if apparent from the ingredients. "
            "Provide a detailed recipe including ingredients, proportions, preparation steps, "
            "cooking time, and any special techniques required. "
            "Explain how this dish maximizes the nutritional value of the available ingredients "
            "and minimizes food waste.";
        break;
      default:
        prompt = "Conduct a thorough analysis of the food in this image. "
            "Describe its appearance, likely ingredients, preparation method, "
            "and cuisine type. Estimate portion size and caloric content. "
            "Highlight any notable nutritional benefits or concerns. "
            "Discuss how this food might fit into various dietary plans and "
            "its potential effects on health and wellness.";
    }

    prompt += " Analyze only the food items clearly visible in the provided image. Do not make assumptions about ingredients that cannot be seen. Provide a confident, detailed response based solely on the image content without asking follow-up questions.";

    final promptVal = [Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])];
    final response = await model.generateContent(promptVal);
    String? aiResponse = response.text;

    return aiResponse ?? 'No response from Gemini.';
  }
}