
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
