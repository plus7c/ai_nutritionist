import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../gemini_engine/gemini_stats_section.dart';

class NutrientsSection extends StatefulWidget {
  final double protein;
  final double fats;
  final double carbs;

  const NutrientsSection({
    required this.protein,
    required this.fats,
    required this.carbs,
  });

  @override
  _NutrientsSectionState createState() => _NutrientsSectionState();
}

class _NutrientsSectionState extends State<NutrientsSection> {
  String _recommendation = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRecommendation();
  }

  Future<void> _fetchRecommendation() async {
    setState(() {
      _isLoading = true;
    });

    // Call to Gemini to get the recommendation
    // This is a mock function. Replace with actual API call to Gemini
    await Future.delayed(Duration(seconds: 2));  // Mocking network delay
    String recommendation = await getGeminiRecommendationForStats(widget.protein, widget.fats, widget.carbs);

    setState(() {
      _recommendation = recommendation;
      _isLoading = false;
    });
  }

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
              'Macro-Nutrient Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (widget.protein > widget.fats && widget.protein > widget.carbs)
                      ? widget.protein * 1.2
                      : (widget.fats > widget.carbs ? widget.fats * 1.2 : widget.carbs * 1.2),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String nutrient;
                        switch (group.x.toInt()) {
                          case 0:
                            nutrient = 'Protein';
                            break;
                          case 1:
                            nutrient = 'Fats';
                            break;
                          case 2:
                            nutrient = 'Carbs';
                            break;
                          default:
                            nutrient = '';
                            break;
                        }
                        return BarTooltipItem(
                          '$nutrient\n',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${rod.y.toString()}g',
                              style: TextStyle(
                                color: Colors.yellow,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: SideTitles(
                      showTitles: true,
                      getTextStyles: (context, value) => TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      margin: 8,
                      reservedSize: 40,
                      getTitles: (value) {
                        if (value % 10 == 0) {
                          return value.toInt().toString();
                        }
                        return '';
                      },
                    ),
                    bottomTitles: SideTitles(
                      showTitles: true,
                      getTextStyles: (context, value) => TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      margin: 16,
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
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          y: widget.protein,
                          colors: [Colors.red],
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          y: widget.fats,
                          colors: [Colors.green],
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          y: widget.carbs,
                          colors: [Colors.blue],
                          width: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Legend(color: Colors.red, text: 'Protein (g)'),
                Legend(color: Colors.green, text: 'Fats (g)'),
                Legend(color: Colors.blue, text: 'Carbs (g)'),
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

class Legend extends StatelessWidget {
  final Color color;
  final String text;

  const Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
