import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
              'Nutrient Breakdown',
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
                  maxY: (protein > fats && protein > carbs)
                      ? protein * 1.2
                      : (fats > carbs ? fats * 1.2 : carbs * 1.2),
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
                          y: protein,
                          colors: [Colors.red],
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          y: fats,
                          colors: [Colors.green],
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          y: carbs,
                          colors: [Colors.blue],
                          width: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
