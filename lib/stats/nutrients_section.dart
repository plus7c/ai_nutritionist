import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../gemini_engine/gemini_stats_section.dart' as tongyi;

class NutrientsSection extends StatefulWidget {
  final double protein;
  final double fats;
  final double carbs;

  const NutrientsSection({super.key, 
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

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchRecommendation() async {
    setState(() {
      _isLoading = true;
    });

    // 调用千问API获取建议
    // 这里有模拟网络延迟
    String recommendation = await tongyi.getNutritionRecommendation(widget.protein, widget.fats, widget.carbs);

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
              AppLocalizations.of(context)!.nutrientsSectionTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
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
                            nutrient = AppLocalizations.of(context)!.proteinLabel;
                            break;
                          case 1:
                            nutrient = AppLocalizations.of(context)!.fatsLabel;
                            break;
                          case 2:
                            nutrient = AppLocalizations.of(context)!.carbsLabel;
                            break;
                          default:
                            nutrient = '';
                            break;
                        }
                        return BarTooltipItem(
                          '$nutrient\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${rod.toY.toString()}${AppLocalizations.of(context)!.gramSuffix}',
                              style: const TextStyle(
                                color: Colors.yellow,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          value % 10 == 0 ? value.toInt().toString() : '',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          String text;
                          switch (value.toInt()) {
                            case 0:
                              text = AppLocalizations.of(context)!.proteinLabel;
                              break;
                            case 1:
                              text = AppLocalizations.of(context)!.fatsLabel;
                              break;
                            case 2:
                              text = AppLocalizations.of(context)!.carbsLabel;
                              break;
                            default:
                              text = '';
                              break;
                          }
                          return Text(
                            text,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
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
                          toY: widget.protein,
                          color: Colors.red,
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: widget.fats,
                          color: Colors.blue,
                          width: 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: widget.carbs,
                          color: Colors.green,
                          width: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Legend(color: Colors.red, text: '${AppLocalizations.of(context)!.proteinLabel} (${AppLocalizations.of(context)!.gramSuffix})'),
                Legend(color: Colors.blue, text: '${AppLocalizations.of(context)!.fatsLabel} (${AppLocalizations.of(context)!.gramSuffix})'),
                Legend(color: Colors.green, text: '${AppLocalizations.of(context)!.carbsLabel} (${AppLocalizations.of(context)!.gramSuffix})'),
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

class Legend extends StatelessWidget {
  final Color color;
  final String text;

  const Legend({super.key, required this.color, required this.text});

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
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
