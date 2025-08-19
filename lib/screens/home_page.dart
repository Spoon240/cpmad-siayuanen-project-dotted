import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../widgets/stylesheet.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/firestore_service.dart';
import 'main_screen.dart';
import 'setUp_page.dart';

import '../controllers/diary_provider.dart';
import 'package:provider/provider.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onTabChange});
  final void Function(int) onTabChange;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // listen to provider
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: true);

    // Convert to doubles for the chart
    final goal = (diaryProvider.goal ?? 0).toDouble();
    final food = diaryProvider.totalFoodCalories.toDouble();
    final exercise = diaryProvider.totalExerciseCalories.toDouble();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(          
              children: [
                Container(
                  height: 230,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBE4E4),
                    borderRadius: BorderRadius.circular(15),
                  ),
          
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Calories", style: AppTextStyles.calBox,),
                                Text("Remaining = Goals - Food + Exercise", style: AppTextStyles.calBoxHint,),
                              ],
                            ),
                            
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SetUpPage(fromSplash: true)),
                                );
                              },
                  
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical:3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8DBEB3), // background color
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Text("edit", style: AppTextStyles.calBoxbutton),
                              ),
                            ),
                          ],
                        ), // header with button
          
                        
                        SizedBox(height: 25,),
          
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              pieChart(goal, food, exercise),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _statRow(Icons.track_changes, "Base Goal", goal),
                                  const SizedBox(height: 8),
                                  _statRow(Icons.restaurant, "Food", food),
                                  const SizedBox(height: 8),
                                  _statRow(Icons.fitness_center, "Exercise", exercise),
                        
                    
                                ],
                              ),
                            ]
                          ),
                        ),
          
                      ],
                    ),
                  ),
                 
                ), // macro tracker (label text, pie chart, headers)
          
          
                const SizedBox(height: 12),
          
          
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Dashboard", style: AppTextStyles.h2,),
          
                    GestureDetector(
                      onTap: () {
                        showWeightInputSheet(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B7E7A),
                          borderRadius: BorderRadius.circular(8),
                          shape: BoxShape.rectangle,
                          
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 12),
                      ),
                    )
                  ],
                ), // dashboard text + Weight log button
          
          
                const SizedBox(height: 12),
          
          
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBE4E4),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(23, 15, 23, 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: WeightLineChartFromUserData(),
                        ), // weight line chart
          
                        const Text(
                          "Recent Weights (kg)",
                          style: AppTextStyles.smallText,
                        ),
                      ],
                    ),
                  ),
                ), // weight line chart
          
          
                const SizedBox(height: 12),
          
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // fallbackMacros(context),
                    // MacroBreakDownCards(context: context, macroType: "Carbs", percentage: 40.0),
                    // MacroBreakDownCards(context: context, macroType: "Protein", percentage: 30.0),
                    // MacroBreakDownCards(context: context, macroType: "Fats", percentage: 30.0),
                    scrollableMacros(),
          
                    toLogging(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

    );
  }

  ////////////////////
  ////////////////////
  ////////////////////


  /// model sheet
  void showWeightInputSheet(BuildContext context){
    final TextEditingController _weightController = TextEditingController();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text("Log Today's Weight", style: AppTextStyles.bodyH,),

                SizedBox(height: 15,),

                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: "Enter weight (kg)",
                    hintStyle: AppTextStyles.bodyHint,
                    filled: true,
                    fillColor: Color.fromARGB(255, 210, 210, 210),
                    
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7E7A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final weight = double.tryParse(_weightController.text);
                      if (weight != null) {
                        try{
                          await FirestoreService().saveUserWeight(weight);
                          Navigator.pop(context);
                          Fluttertoast.showToast(msg: "Weight saved successfully.");
                        }
                        catch(e){
                          Fluttertoast.showToast(msg: "Error saving weight: $e");
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MainScreen()),
                        );
                      }
                      else{
                        Fluttertoast.showToast(msg: "Please enter a valid value for weight.");
                      }
                    },

                    child: const Text("Save", style: AppTextStyles.buttonText),
                  ),
                ),

              ],
            ),
          )
        );
      },
    );
  }

  // Bottom Row (FIRESTORE) 1.1
  Widget MacroBreakDownCards({context, required String macroType, required double percentage,}){
    return  Container(
      height: 170,
      width: MediaQuery.of(context).size.width * 0.43,

      decoration: BoxDecoration(
        color: const Color(0xFFDBE4E4),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(Icons.food_bank, size: 60,),
            Text(macroType, style: AppTextStyles.h1,),
            Text("${percentage.toStringAsFixed(1)}%", style: AppTextStyles.tags,),
          ],
        ),
      ),
    );
  }

  /// Bottom Row (HARDCODED) 1.2
  Widget fallbackMacros(context){
    return Container(
      height: 170,
      width: MediaQuery.of(context).size.width * 0.43,

      decoration: BoxDecoration(
        color: const Color(0xFFDBE4E4),
        borderRadius: BorderRadius.circular(20),
      ),

      child: const Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Text("Complete logging", style: AppTextStyles.bodyHint,),
            Text("to see details", style: AppTextStyles.bodyHint,),
          ],
        ),
      ),
    );
  }

  // 1.1 + 1.2 BOTTOM ROW
  Widget scrollableMacros() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return fallbackMacros(context);
    }

    return FutureBuilder(
      future: FirestoreService().getMacroGoals(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 170,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return fallbackMacros(context);
        }

        final macroData = snapshot.data;
        if (macroData == null) {
          return fallbackMacros(context);
        }

        final List<Widget> cards = [];

        final Map<String, dynamic> macros = {
          'Carbs': macroData['carbs'],
          'Protein': macroData['protein'],
          'Fats': macroData['fat'] ?? macroData['fats'],
        };

        macros.forEach((key, value) {
          final percent = (value is Map && value['percent'] is num)
              ? (value['percent'] as num).toDouble()
              : 0.0;

          cards.add(MacroBreakDownCards(
            context: context,
            macroType: key,
            percentage: percent,
          ));
        });

        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.45,
          height: 170,
          child: PageView(
            scrollDirection: Axis.vertical,
            children: cards,
          ),
        );
      },
    );
  }


  /// Bottom Row widget (LOG NOW +)
  Widget toLogging(context){
    return Container(
      height: 170,
      width: MediaQuery.of(context).size.width * 0.43,
      decoration: BoxDecoration(
        color: const Color(0xFFDBE4E4),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Log Now", style: AppTextStyles.bodyH),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: () {
                widget.onTabChange(1);
              },
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFF6B7E7A),
                child: Icon(Icons.add, size: 28, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ----------------------
  // line chart for weight
  // ----------------------
  Widget WeightLineChartFromUserData() {
    return FutureBuilder<List<FlSpot>>(
      future: FirestoreService().getUserWeightSpots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } 
        else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final fullData = snapshot.data!;
          final dataToShow = fullData.length > 7
              ? fullData.sublist(fullData.length - 7)
              : fullData;

          return LineChart(
            LineChartData(
              minX: 0,
              maxX: dataToShow.length.toDouble() - 1,
              minY: dataToShow.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 1,
              maxY: dataToShow.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1,

              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),

              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, 
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= dataToShow.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          dataToShow[index].y.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7E7A),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),

              lineBarsData: [
                LineChartBarData(
                  spots: dataToShow.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.y);
                  }).toList(),
                  isCurved: true,
                  color: const Color(0xFF6B7E7A),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF6B7E7A).withOpacity(0.2),
                  ),
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          );
        } 
        else {
          return const Center(child: Text("No weight data yet. Please Log."));
        }
      },
    );
  }


  // DONUT CHART
  Widget pieChart(double goal, double food, double exercise) {
    final double remaining = goal - food + exercise;

    // Build chart sections based on remaining
    List<PieChartSectionData> sections;

    if (remaining >= 0) {
      // Normal case: Remaining is positive or zero
      sections = [
        PieChartSectionData(
          value: food,
          color: const Color(0xFF6F8F8A),
          showTitle: false,
          radius: 20,
        ),
        PieChartSectionData(
          value: remaining,
          color: const Color(0xFF3F3F3F),
          showTitle: false,
          radius: 20,
        ),
      ];
    } 
    else {
      // Over calorie case: Show goal as normal + extra overage in red
      final double overage = food - (goal + exercise);

      sections = [
        PieChartSectionData(
          value: goal + exercise,
          color: const Color(0xFF6F8F8A),
          showTitle: false,
          radius: 20,
        ),
        PieChartSectionData(
          value: overage,
          color: const Color.fromARGB(255, 196, 132, 127),
          showTitle: false,
          radius: 20,
        ),
      ];
    }

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              centerSpaceRadius: 50,
              sectionsSpace: 0,
              sections: sections,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                remaining.abs().toStringAsFixed(0),
                style: AppTextStyles.h2.copyWith(
                  color: remaining >= 0
                      ? Colors.black
                      : const Color.fromARGB(255, 100, 48, 43),
                ),
              ),
              Text(
                remaining >= 0 ? "Remaining" : "Over By",
                style: AppTextStyles.bodyHintSmall.copyWith(
                  color: remaining >= 0
                      ? Colors.grey
                      : const Color.fromARGB(255, 100, 48, 43),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // LABELS FOR PIE CHART
  Widget _statRow(IconData icon, String label, num value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 25, color: Colors.grey[800]),
        const SizedBox(width: 25),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodyHintSmall2),
            Text(value.toString(), style: AppTextStyles.bodyHintSmall2),
            
          ],
        ),
      ],
    );
  }
}
