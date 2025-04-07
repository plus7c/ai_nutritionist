import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../firebase_gemini_helper/firebase_gemini_helper.dart' as firebase_helper;

class BMICard extends StatefulWidget {
  final double bmi;

  const BMICard({super.key, required this.bmi});

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
      return AppLocalizations.of(context)!.underweightText;
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      return AppLocalizations.of(context)!.normalWeightText;
    } else if (bmi >= 25 && bmi <= 29.9) {
      return AppLocalizations.of(context)!.overweightText;
    } else {
      return AppLocalizations.of(context)!.obeseText;
    }
  }

  Future<void> _fetchRecommendation() async {
    setState(() {
      _isLoading = true;
    });

    // 调用Firebase中的BMI推荐函数（它内部会调用tongyi.getBMIRecommendation）
    String recommendation = await firebase_helper.getBMIRecommendation();

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
              AppLocalizations.of(context)!.bmiTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.bmiValue(widget.bmi.toStringAsFixed(1)),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: bmiCategoryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bmiCategory,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.geminiRecommendation,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _recommendation,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
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
