import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeightStatistics extends StatelessWidget {
  final List<FlSpot> weightData;

  const WeightStatistics({super.key, required this.weightData});

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
            const Text(
              'Your Weight Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 12),
            // Weight statistics graph
            SizedBox(
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
                      color: Colors.blue,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true)
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true)
                    ),
                  ),
                ),
              )
                  : const Center(child: Text('No weight data available', style: TextStyle(fontSize: 16, color: Colors.grey))),
            ),
          ],
        ),
      ),
    );
  }
}
