import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuickAddPage extends StatefulWidget {
  final String mealType;

  const QuickAddPage({super.key, required this.mealType});

  @override
  _QuickAddPageState createState() => _QuickAddPageState();
}

class _QuickAddPageState extends State<QuickAddPage> {
  final TextEditingController _caloriesController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Add', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _addFood,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.restaurant, color: Colors.blue),
              title: const Text('Meal', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(widget.mealType),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _caloriesController,
              decoration: InputDecoration(
                labelText: 'Calories',
                hintText: 'Enter calorie amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildPremiumFeature('Total Fat (g)'),
            _buildPremiumFeature('Total Carbohydrates (g)'),
            _buildPremiumFeature('Protein (g)'),
            _buildPremiumFeature('Time'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Handle Go Premium
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Go Premium'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(String label) {
    return ListTile(
      title: Text(label),
      trailing: const Icon(Icons.lock, color: Colors.yellow),
    );
  }

  Future<void> _addFood() async {
    String userId = _auth.currentUser!.uid;
    String calories = _caloriesController.text;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('loggedmeals')
        .add({
      'mealType': widget.mealType,
      'calories': int.parse(calories),
      'timestamp': Timestamp.now(),
    });

    Navigator.pop(context);
  }
}