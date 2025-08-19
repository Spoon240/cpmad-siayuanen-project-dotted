import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../widgets/stylesheet.dart';
import '../widgets/common_bot_nav.dart';

class ReportPage extends StatelessWidget {
  final double carbsG;
  final double proteinG;
  final double fatG;
  final num calories;
  final String date;

  const ReportPage({super.key, required this.carbsG, required this.proteinG, required this.fatG, required this.calories, required this.date,});

  @override
  Widget build(BuildContext context) {
    const carbColor    = Color.fromARGB(255, 35, 90, 148);
    const proteinColor = Color.fromARGB(255, 237, 115, 88);
    const fatColor     = Color.fromARGB(255, 47, 131, 72);

    final carbCals    = carbsG * 4;
    final proteinCals = proteinG * 4;
    final fatCals     = fatG * 9;

    final totalGrams = carbsG + proteinG + fatG;
    final carbPct    = totalGrams > 0 ? (carbsG    / totalGrams) * 100 : 0;
    final proteinPct = totalGrams > 0 ? (proteinG  / totalGrams) * 100 : 0;
    final fatPct     = totalGrams > 0 ? (fatG      / totalGrams) * 100 : 0;

    return Scaffold(
      appBar: buildCreateFoodAppBar(_displayDate(date)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 35),
          Center(
            child: SizedBox(
              height: 250, width: 250,
              child: pieChart(carbsG, proteinG, fatG, calories),
            ),
          ),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
            child: Column(
              children: [
                records(color: carbColor,    label: "Carbs",   grams: carbsG,    calories: carbCals,    percentage: carbPct),
                const SizedBox(height: 20),
                records(color: proteinColor, label: "Protein", grams: proteinG,  calories: proteinCals, percentage: proteinPct),
                const SizedBox(height: 20),
                records(color: fatColor,     label: "Fats",    grams: fatG,      calories: fatCals,     percentage: fatPct),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayDate(String iso) {
    final p = iso.split('-');
    if (p.length == 3) {
      final y = p[0], m = int.tryParse(p[1]) ?? 0, d = int.tryParse(p[2]) ?? 0;
      return '$d-$m-$y';
    }
    return iso;
  }
}

String _n0(num n) => n.toStringAsFixed(0); // whole number
String _n1(num n) => n.toStringAsFixed(1); // 1 decimal place

Widget pieChart(double carbs, double protein, double fat, num calories) {
  return Stack(
    alignment: Alignment.center,
    children: [
      PieChart(
        PieChartData(
          startDegreeOffset: -90,
          centerSpaceRadius: 80,
          sectionsSpace: 0,
          sections: [
            PieChartSectionData(value: carbs,   color: const Color.fromARGB(255, 35, 90, 148), showTitle: false),
            PieChartSectionData(value: protein, color: const Color.fromARGB(255, 237, 115, 88), showTitle: false),
            PieChartSectionData(value: fat,     color: const Color.fromARGB(255, 47, 131, 72), showTitle: false),
          ],
        ),
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_n0(calories), style: AppTextStyles.h1), // total kcal rounded
          const SizedBox(height: 2),
          const Text("Total Calories", style: AppTextStyles.body),
          const Text("Before Exercise", style: AppTextStyles.body),

        ],
      ),
    ],
  );
}

Widget records({required Color color, required String label, required num grams, required num calories, required num percentage}){
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      )),
      Text(
        '${_n1(grams)}g | ${_n0(calories)}kcal | ${_n0(percentage)}%',
        style: AppTextStyles.bodyH,
      ),
    ],
  );
}
