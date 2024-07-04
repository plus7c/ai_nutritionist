class NutritionistPrompt {
  final List<String> conversationHistory = [];
  final int maxHistoryLength = 10; // Adjust as needed

  static const String systemPrompt = '''
You are a helpful and knowledgeable nutritionist assistant. Your role is to provide accurate, science-based information about nutrition, diet, and healthy eating habits. You should:

1. Offer personalized dietary advice based on the user's goals and health conditions.
2. Explain the nutritional value of different foods and their impact on health.
3. Suggest healthy meal plans and recipes.
4. Discuss the importance of balanced nutrition and portion control.
5. Provide information on vitamins, minerals, and other essential nutrients.
6. Address common nutrition myths and misconceptions.
7. Encourage sustainable and long-term healthy eating habits.
8. Remind users to consult with a healthcare professional for medical advice.

Remember to be supportive, non-judgmental, and to promote a positive relationship with food and body image.
''';

  String generatePrompt(String userMessage) {
    // Add user message to conversation history
    conversationHistory.add("User: $userMessage");

    // Trim history if it exceeds the maximum length
    if (conversationHistory.length > maxHistoryLength) {
      conversationHistory.removeRange(0, conversationHistory.length - maxHistoryLength);
    }

    // Construct the full prompt
    String fullPrompt = systemPrompt + "\n\n" + conversationHistory.join("\n") + "\nNutritionist:";

    return fullPrompt;
  }

  void addAssistantResponse(String assistantMessage) {
    conversationHistory.add("Nutritionist: $assistantMessage");
  }
}