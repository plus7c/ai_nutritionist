import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Store user data
  Future<void> storeUserData(String userId, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(userId).set(userData);
  }

  // Add a food journal entry
  Future<void> addFoodJournalEntry(String userId, Map<String, dynamic> entry) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('foodJournal')
        .add(entry);
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
    return doc.data() as Map<String, dynamic>?;
  }

  // Get food journal entries
  Stream<QuerySnapshot> getFoodJournalEntries(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('foodJournal')
        .orderBy('dateTime', descending: true)
        .limit(10)
        .snapshots();
  }


  // Helper method to get a reference to a user's document
  DocumentReference _getUserDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

// Update height
  Future<void> updateHeight(String userId, Map<String, int> height) async {
    await _getUserDoc(userId).update({
      'height': {
        'feet': height['feet'],
        'inches': height['inches'],
      }
    });
  }

  // Update weight
  Future<void> updateWeight(String userId, double weight) async {
    await _getUserDoc(userId).update({'bodyWeight': weight});
  }

  // Update gender
  Future<void> updateGender(String userId, String gender) async {
    await _getUserDoc(userId).update({'gender': gender});
  }

  // Update waist circumference
  Future<void> updateWaistCircumference(String userId, double waistCircumference) async {
    await _getUserDoc(userId).update({'waistCircumference': waistCircumference});
  }

  Future<void> updateAge(String userId, int age) async {
    await _getUserDoc(userId).update({'age': age});
  }

  Future<void> updateField(String userId, String field, dynamic value) async {
  await _getUserDoc(userId).update({field: value});
  }

  Future<dynamic> getField(String userId, String field) async {
    DocumentSnapshot doc = await _getUserDoc(userId).get();
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    return data != null ? data[field] : null;
  }


  // Update allergies
  Future<void> updateAllergies(String userId, List<String> allergies) async {
    await _getUserDoc(userId).update({'allergies': allergies});
  }
  // Update allergies
  Future<void> updateGoals(String userId, List<String> allergies) async {
    await _getUserDoc(userId).update({'goal': allergies});
  }

  // Add a single allergy
  Future<void> addAllergy(String userId, String allergy) async {
    await _getUserDoc(userId).update({
      'allergies': FieldValue.arrayUnion([allergy])
    });
  }

  // Remove a single allergy
  Future<void> removeAllergy(String userId, String allergy) async {
    await _getUserDoc(userId).update({
      'allergies': FieldValue.arrayRemove([allergy])
    });
  }

  // Update previous health conditions
  Future<void> updatePreviousHealthConditions(String userId, List<String> conditions) async {
    await _getUserDoc(userId).update({'previousHealthConditions': conditions});
  }

  // Update physical activity level
  Future<void> updatePhysicalActivityLevel(String userId, String level) async {
    await _getUserDoc(userId).update({'physicalActivityLevel': level});
  }

  // Update dietary preferences
  Future<void> updateDietaryPreferences(String userId, String preferences) async {
    await _getUserDoc(userId).update({'dietaryPreferences': preferences});
  }

  // Update email
  Future<void> updateEmail(String userId, String email) async {
    await _getUserDoc(userId).update({'email': email});
  }

  // Update username
  Future<void> updateUsername(String userId, String username) async {
    await _getUserDoc(userId).update({'username': username});
  }
}

final FirestoreService _firestoreService = FirestoreService();

// Store user data
void storeUserData(String userId) async {
  await _firestoreService.storeUserData(userId, {
    'username': 'johndoe',
    'email': 'john@example.com',
    'gender': 'male',
    'height': 180,
    'waistCircumference': 85,
    'bodyWeight': 75,
    'allergies': ['peanuts', 'shellfish'],
    'previousHealthConditions': ['asthma'],
    'physicalActivityLevel': 'moderate',
    'dietaryPreferences': 'vegetarian',
  });
}

// Add a food journal entry
void addFoodJournalEntry(String userId) async {
  await _firestoreService.addFoodJournalEntry(userId, {
    'dateTime': Timestamp.now(),
    'portionSize': {
      'metric': 'grams',
      'amount': 200,
    },
    'mealType': 'lunch',
    'moodAfterEating': 'good',
    'physicalSensations': ['energized'],
    'hungerFullness': 7,
    'nutritionalInformation': {
      'calories': 300,
      'macronutrients': {
        'protein': 20,
        'carbs': 40,
        'fat': 10,
      },
    },
  });
}

// Get user data
void getUserData(String userId) async {
  Map<String, dynamic>? userData = await _firestoreService.getUserData(userId);
  if (userData != null) {
    print('User data: $userData');
  }
}

// Display food journal entries
Widget buildFoodJournalList(String userId) {
  return StreamBuilder<QuerySnapshot>(
    stream: _firestoreService.getFoodJournalEntries(userId),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const CircularProgressIndicator();
      return ListView(
        children: snapshot.data!.docs.map((doc) {
          Map<String, dynamic> entry = doc.data() as Map<String, dynamic>;
          return ListTile(
            title: Text('Meal: ${entry['mealType']}'),
            subtitle: Text('Date: ${entry['dateTime'].toDate()}'),
          );
        }).toList(),
      );
    },
  );


}