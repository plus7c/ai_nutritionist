import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pizza_ordering_app/stats/nutrients_section.dart';
import 'package:pizza_ordering_app/stats/variables.dart';

import '../firestore_helper.dart';
import 'bmi.dart';
import 'dateselect.dart';

class StatsPage extends StatefulWidget {
  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  double _bmi = 0;
  int _totalCaloriesEaten = 0;
  double _totalProtein = 0;
  double _totalFats = 0;
  double _totalCarbs = 0;
  List<FlSpot> _weightData = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    String userId = _auth.currentUser!.uid;

    // Fetch BMI
    var userData = await _firestoreService.getUserData(userId);
    Map<String, dynamic> heightData = userData?['height'];
    int feet = heightData['feet'];
    int inches = heightData['inches'];
    int totalHeightInches = (feet * 12) + inches;

    setState(() {
      _bmi = calculateBMI(userData?['weight'], totalHeightInches);
    });

    // Fetch daily meals for the selected date
    DateTime startOfDay = _selectedDate.startOfDay;
    DateTime endOfDay = _selectedDate.endOfDay;

    QuerySnapshot mealLogs = await _firestore.collection('users').doc(userId).collection('loggedmeals')
        .where('timeOfLogging', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timeOfLogging', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    int totalCalories = 0;
    double totalProtein = 0.0;
    double totalFats = 0.0;
    double totalCarbs = 0.0;

    for (var doc in mealLogs.docs) {
      var mealTypes = doc['mealTypes'] as List<dynamic>;
      for (var mealType in mealTypes) {
        var mealItems = mealType['mealItems'] as List<dynamic>;
        for (var mealItem in mealItems) {
          totalCalories += mealItem['calories'] as int;
          totalProtein += mealItem['protein'] as double;
          totalFats += mealItem['fats'] as double;
          totalCarbs += mealItem['carbs'] as double;
        }
      }
    }

    // Fetch weight statistics
    QuerySnapshot weightLogs = await _firestore.collection('users').doc(userId).collection('weightLogs').get();
    List<FlSpot> weightData = [];

    for (var doc in weightLogs.docs) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      double weight = doc['weight'];
      weightData.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), weight));
    }

    setState(() {
      _totalCaloriesEaten = totalCalories;
      _totalProtein = totalProtein;
      _totalFats = totalFats;
      _totalCarbs = totalCarbs;
      _weightData = weightData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Daily Stats',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        leading: Icon(Icons.query_stats_sharp),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateSelectButton(
                selectedDate: _selectedDate,
                onPressed: () => _selectDate(context),
              ),
              SizedBox(height: 16),
              DailyStats(totalCaloriesEaten: _totalCaloriesEaten),
              SizedBox(height: 16),
              BMICard(bmi: _bmi),
              SizedBox(height: 16),
              // WeightStatistics(weightData: _weightData),
              SizedBox(height: 16),
              NutrientsSection(protein: _totalProtein, fats: _totalFats, carbs: _totalCarbs)
            ],
          ),
        ),
      ),
    );
  }
}

class DailyStats extends StatelessWidget {
  final int totalCaloriesEaten;

  const DailyStats({required this.totalCaloriesEaten});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatItem(
                  label: 'Daily calories',
                  value: '$calorieGoal',
                ),
                CircularProgressIndicator(
                  value: totalCaloriesEaten / 2181,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                StatItem(
                  label: 'Eaten',
                  value: '$totalCaloriesEaten',
                ),
              ],
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                '${2181 - totalCaloriesEaten} Kcal available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String label;
  final String value;

  const StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

extension DateTimeExtension on DateTime {
  DateTime get startOfDay => DateTime(year, month, day, 0, 0, 0);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}