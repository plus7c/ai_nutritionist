import 'package:flutter/material.dart';

import '../firebase_gemini_helper/firebase_gemini_helper.dart';
import '../gemini_engine/gemini_stats_section.dart';

class BMICard extends StatefulWidget {
  final double bmi;

  const BMICard({required this.bmi});

  @override
  State<BMICard> createState() => _BMICardState();
}

class _BMICardState extends State<BMICard> {
  bool _isLoading = false;
  String _recommendation = '';

  @override
  void initState() {
    super.initState();
    _fetchRecommendation();
  }

  @override
  void dispose() {
    super.dispose();
  }

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

  Future<void> _fetchRecommendation() async {
    setState(() {
      _isLoading = true;
    });

    // Call to Gemini to get the recommendation
    String recommendation = await getBMIRecommendation();

    setState(() {
      _recommendation = recommendation;
      _isLoading = false;
    });
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
    String bmiCategory = _getBMICategory(widget.bmi);
    Color bmiCategoryColor = _getBMICategoryColor(widget.bmi);

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
                  'Your BMI: ${widget.bmi.toStringAsFixed(1)}',
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
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemini Recommendation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _recommendation,
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

double calculateBMI(double weightLbs, int heightInches) {
  // Convert pounds to kilograms
  double weightKg = weightLbs * 0.453592;

  // Convert inches to meters
  double heightMeters = heightInches * 0.0254;

  // Calculate BMI
  double bmi = weightKg / (heightMeters * heightMeters);

  // Round BMI to one decimal place
  bmi = double.parse(bmi.toStringAsFixed(1));

  return bmi;
}
