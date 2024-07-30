import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firestore_helper.dart';
import '../gemini_engine/gemini_stats_section.dart';
import '../stats/bmi.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');

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
        String geminiRecommendation = await getGeminiRecommendationForBMI(bmi);
        await userDocRef.collection('healthstatus').doc('bmirecommendation').set({
          'lastupdatedtime': now,
          'recommendationstring': geminiRecommendation,
        });
        return '';
    }

    if (!healthStatusDoc.exists) {
      // If the document doesn't exist, create it with initial values
      String geminiRecommendation = await getGeminiRecommendationForBMI(bmi);
      await userDocRef.collection('healthstatus').doc('bmirecommendation').set({
        'lastupdatedtime': now,
        'recommendationstring': geminiRecommendation,
      });
      return geminiRecommendation;
    } else {
      // Document exists, check the lastupdatedtime
      Map<String, dynamic> data = healthStatusDoc.data() as Map<String, dynamic>;
      Timestamp lastUpdated = data['lastupdatedtime'] as Timestamp;
      String recommendation = data['recommendationstring'] as String;

      // Check if the last update was more than 24 hours ago
      if (now.difference(lastUpdated.toDate()).inHours > 24) {
        String geminiRecommendation = await getGeminiRecommendationForBMI(bmi);
        // If more than 24 hours, update the lastupdatedtime and generate a new recommendation
        // For this example, we're just updating the time. In a real app, you'd recalculate the recommendation here.
        await userDocRef.collection('healthstatus').doc('bmirecommendation').update({
          'lastupdatedtime': now,
          'recommendationstring': geminiRecommendation,
        });
        return 'Updated bmi recommendation to: $geminiRecommendation';
      } else {
        // If less than 24 hours, return the existing recommendation
        return recommendation;
      }
    }
  } catch (e) {
    print('Error fetching BMI recommendation: $e');
    return 'Error fetching recommendation. Please try again later.';
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
    Analyze the following health data and provide:
    1. A health score out of 100
    2. A detailed recommendation (about 3-4 sentences)

    User Health Data:
    - Username: ${healthData['username']}
    - Gender: ${healthData['gender']}
    - Date of Birth: ${healthData['dateOfBirth']}
    - Weight: ${healthData['weight']} lbs
    - Height: ${healthData['height']['feet']} feet ${healthData['height']['inches']} inches
    - Goals: ${healthData['goals'].join(', ')}

    Please format your response as follows (even if you find errors):
    Score: [numerical score]
    Recommendation: [your detailed recommendation]
    Errors: true/false
    """;

  final promptVal = [Content.text(prompt)];
  final response = await model.generateContent(promptVal);
  String? aiResponse = response.text;

  if (aiResponse == null) {
    throw Exception('Failed to get a response from Gemini');
  }

  // Parse the AI response
  final lines = aiResponse.split('\n');
  int score = 0;
  String recommendation = '';
  bool errors = false;

  for (var line in lines) {
    if (line.startsWith('Score:')) {
      score = int.tryParse(line.split(':')[1].trim()) ?? 0;
    } else if (line.startsWith('Recommendation:')) {
      recommendation = line.split(':')[1].trim();
    } else if (line.startsWith('Errors:')) {
      errors = line.split(':')[1].trim() == 'true';
    }
  }

  return HealthStatus(score: score, recommendation: recommendation, errors: errors);
}

Future<HealthStatus> GetOverallHealthStatus() async {
  DateTime now = DateTime.now();
  String userId = _auth.currentUser!.uid;

  try {
    DocumentReference userDocRef = _firestore.collection('users').doc(userId);
    DocumentSnapshot userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      throw Exception('User document not found');
    }

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    // Fetch the last health status
    DocumentSnapshot healthStatusDoc = await userDocRef.collection('healthstatus').doc('overallhealthstatus').get();

    // Check if the document doesn't exist or if it exists but has errors
    if (!healthStatusDoc.exists || (healthStatusDoc.exists && (healthStatusDoc.data() as Map<String, dynamic>)['errors'] == true)) {
      Map<String, dynamic> healthData = {
        'username': userData['username'],
        'gender': userData['gender'],
        'dateOfBirth': userData['dateOfBirth'],
        'weight': userData['weight'],
        'height': userData['height'],
        'goals': userData['goals'],
        'allergies': userData['allergies'],
      };

      // Call Gemini API to get health analysis
      HealthStatus newStatus = await analyzeHealth(healthData);

      // Update Firestore with new health status
      await userDocRef.collection('healthstatus').doc('overallhealthstatus').set({
        'lastupdatedtime': now,
        'score': newStatus.score,
        'recommendation': newStatus.recommendation,
        'errors': newStatus.errors
      });

      return newStatus;
    }

    // If the document exists and doesn't have errors, check if it's outdated
    if (now.difference((healthStatusDoc.data() as Map<String, dynamic>)['lastupdatedtime'].toDate()).inHours > 24) {
      // If health status is older than 24 hours, calculate a new one

      Map<String, dynamic> healthData = {
        'username': userData['username'],
        'gender': userData['gender'],
        'dateOfBirth': userData['dateOfBirth'],
        'weight': userData['weight'],
        'height': userData['height'],
        'goals': userData['goals'],
        'allergies': userData['allergies'],
      };

      // Call Gemini API to get health analysis
      HealthStatus newStatus = await analyzeHealth(healthData);

      // Update Firestore with new health status
      await userDocRef.collection('healthstatus').doc('overallhealthstatus').set({
        'lastupdatedtime': now,
        'score': newStatus.score,
        'recommendation': newStatus.recommendation,
        'errors': newStatus.errors
      });

      return newStatus;
    } else {
      // If health status is recent and doesn't have errors, return the stored data
      Map<String, dynamic> statusData = healthStatusDoc.data() as Map<String, dynamic>;
      return HealthStatus(
          score: statusData['score'],
          recommendation: statusData['recommendation'],
          errors: statusData['errors']
      );
    }
  } catch (e) {
    print('Error fetching overall health status: $e');
    return HealthStatus(score: 0, recommendation: 'Error fetching health status. Please try again later.', errors: true);
  }
}