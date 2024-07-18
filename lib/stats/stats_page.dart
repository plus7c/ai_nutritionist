import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../firestore_helper.dart';
import 'bmi.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    String userId = _auth.currentUser!.uid;

    // Fetch BMI
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    var userData = await _firestoreService.getUserData(userId);
    Map<String, dynamic> heightData = userData?['height'];
    int feet = heightData['feet'];
    int inches = heightData['inches'];

    // Convert inches to feet and add to the feet value
    double heightInFeet = feet + (inches / 12.0);
    setState(() {
      _bmi = userData?['weight'] / (heightInFeet * heightInFeet);
    });

    // Fetch daily meals
    DateTime startOfDay = DateTime.now().toUtc().startOfDay;
    DateTime endOfDay = DateTime.now().toUtc().endOfDay;

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
        title: Text('Your Daily Stats', style: TextStyle(color: Colors.black)),
        centerTitle: true,
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
              DailyStats(totalCaloriesEaten: _totalCaloriesEaten),
              SizedBox(height: 16),
              BMICard(bmi: _bmi),
              SizedBox(height: 16),
              WeightStatistics(weightData: _weightData),
              SizedBox(height: 16),
              NutrientsSection(
                protein: _totalProtein,
                fats: _totalFats,
                carbs: _totalCarbs,
              ),
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
                  value: '2181',
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

class WeightStatistics extends StatelessWidget {
  final List<FlSpot> weightData;

  const WeightStatistics({required this.weightData});

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Weight Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            SizedBox(height: 12),
            // Weight statistics graph
            Container(
              height: 200,
              child: weightData.isNotEmpty
                  ? LineChart(
                LineChartData(
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weightData,
                      isCurved: true,
                      barWidth: 4,
                      colors: [Colors.blue],
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: SideTitles(showTitles: true),
                    bottomTitles: SideTitles(showTitles: true),
                  ),
                ),
              )
                  : Center(child: Text('No weight data available', style: TextStyle(fontSize: 16, color: Colors.grey))),
            ),
          ],
        ),
      ),
    );
  }
}

class NutrientsSection extends StatelessWidget {
  final double protein;
  final double fats;
  final double carbs;

  const NutrientsSection({
    required this.protein,
    required this.fats,
    required this.carbs,
  });

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Protein, Fats, Carbohydrates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            SizedBox(height: 12),
            // Nutrients graph
            Container(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(y: protein, colors: [Colors.red]),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(y: fats, colors: [Colors.green]),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(y: carbs, colors: [Colors.blue]),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: SideTitles(showTitles: true),
                    bottomTitles: SideTitles(
                      showTitles: true,
                      getTitles: (double value) {
                        switch (value.toInt()) {
                          case 0:
                            return 'Protein';
                          case 1:
                            return 'Fats';
                          case 2:
                            return 'Carbs';
                        }
                        return '';
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BMICard extends StatelessWidget {
  final double bmi;

  const BMICard({required this.bmi});

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      return 'Healthy Weight';
    } else if (bmi >= 25 && bmi <= 29.9) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  Color _getBMICategoryColor(double bmi) {
    if (bmi < 18.5) {
      return Colors.blue;
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      return Colors.green;
    } else if (bmi >= 25 && bmi <= 29.9) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    String bmiCategory = _getBMICategory(bmi);
    Color bmiCategoryColor = _getBMICategoryColor(bmi);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Body Mass Index (BMI)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your BMI: ${bmi.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: bmiCategoryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bmiCategory,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  DateTime get startOfDay => DateTime(year, month, day, 0, 0, 0);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}

void main() {
  runApp(MaterialApp(
    home: StatsPage(),
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
  ));
}
