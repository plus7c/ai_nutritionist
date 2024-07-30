import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firestore_helper.dart';

class NutritionistPrompt {
  final List<String> conversationHistory = [];
  final int maxHistoryLength = 20; // Adjust as needed
  String? userHealthData;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  static const String systemPrompt = '''
You are a friendly and knowledgeable nutritionist assistant named Nutri. Your personality is warm, approachable, and supportive. You're here to help people on their journey to better health through nutrition. Remember these key points:
Also use the User's profile to answer questions accordingly. You have the age, height, weight, goals, allergies. Don't be redundant if you have answers.

1. Start conversations with a warm greeting and ask how you can help.
2. Offer advice one step at a time, avoiding information overload.
3. Use a conversational tone, as if chatting with a friend.
4. Be empathetic and understanding of the challenges people face with nutrition.
5. Encourage and praise efforts towards healthier choices.
6. When giving advice, explain the 'why' behind it in simple terms.
7. If asked about medical conditions, gently remind the user to consult healthcare professionals for personalized medical advice.

Your goal is to make nutrition feel approachable and manageable. Help users feel empowered to make positive changes, no matter how small. Always maintain a positive, non-judgmental attitude towards food and body image.
''';

  Future<String> fetchUserHealthData() async {
    String userId = _auth.currentUser!.uid;
    try {
      var userData = await _firestoreService.getUserData(userId);
      if (userData != null) {
        String userHealthString = '''
User Health Data:
- Username: ${userData['username']}
- Gender: ${userData['gender']}
- Date of Birth: ${userData['dateOfBirth']}
- Weight: ${userData['weight']} lbs
- Height: ${userData['height']['feet']} feet ${userData['height']['inches']} inches
- Goals: ${userData['goals'].join(', ')}
- Allergies: ${userData['allergies'].join(', ')}
''';
        // Setting the shared string
        userHealthData = userHealthString;
        return userHealthString;
      }
      return '';
    } catch (e) {
      print('Error fetching user health data: $e');
      return '';
    }
  }

  Future<String> generatePrompt(String userMessage) async {
    // Add user message to conversation history
    conversationHistory.add("User: $userMessage");

    // Trim history if it exceeds the maximum length
    if (conversationHistory.length > maxHistoryLength) {
      conversationHistory.removeRange(0, conversationHistory.length - maxHistoryLength);
    }

    // Construct the full prompt
    String fullPrompt = systemPrompt + "\n\n";

    // Add user health data if available
    if (userHealthData == null) {
      userHealthData = await fetchUserHealthData();
    }
    fullPrompt += userHealthData ?? '';

    fullPrompt += conversationHistory.join("\n") + "\nNutritionist:";

    return fullPrompt;
  }

  void addAssistantResponse(String assistantMessage) {
    conversationHistory.add("Nutritionist: $assistantMessage");
  }

  double calculateBMI(int weightLbs, double heightInches) {
    // BMI formula: (weight in kg / (height in meters)^2)
    double weightKg = weightLbs * 0.45359237;
    double heightMeters = heightInches * 0.0254;
    return weightKg / (heightMeters * heightMeters);
  }
}