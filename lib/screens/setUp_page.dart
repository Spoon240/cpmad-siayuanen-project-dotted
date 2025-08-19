import 'package:flutter/material.dart';
import '../widgets/stylesheet.dart';
import '../widgets/custom_input_fields.dart'; // using for buildNormalField

import 'main_screen.dart';
import 'package:pie_chart/pie_chart.dart';
import '../services/firestore_service.dart';
import '../widgets/common_bot_nav.dart';

class SetUpPage extends StatefulWidget {
  final bool fromSplash;
  const SetUpPage({super.key, required this.fromSplash});
  

  @override
  State<SetUpPage> createState() => _SetUpPageState();
}

class _SetUpPageState extends State<SetUpPage> {
  final TextEditingController _calorieController = TextEditingController();
  double carbsPercent = 40;
  double proteinPercent = 30;
  double fatPercent = 30;

  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final calorieGoal = await FirestoreService().fetchCurrentCalorieGoals();
      if (!mounted) return;

      if (calorieGoal != null) {
        // Expecting the same shape you save
        final total = (calorieGoal['totalCalories'] as num?)?.toDouble() ?? 0;
        final carbsPercentage = (calorieGoal['carbs']?['percent'] as num?)?.toDouble() ?? 40;
        final proteinPercentage  = (calorieGoal['protein']?['percent'] as num?)?.toDouble() ?? 30;
        final fatPercentage  = (calorieGoal['fat']?['percent'] as num?)?.toDouble() ?? 30;

        _calorieController.text = total > 0 ? total.toStringAsFixed(0) : '';
        carbsPercent = carbsPercentage;
        proteinPercent = proteinPercentage;
        fatPercent = fatPercentage;
      }

      setState(() => _loading = false);
    } 
    catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
  
  Future<void> _save() async {
    if (!isValid || _saving) return;

    setState(() => _saving = true);
    try {
      await FirestoreService().saveCalorieGoal(
        totalCalories: totalCalories,
        carbsPercentage: carbsPercent,
        proteinPercentage: proteinPercent,
        fatPercentage: fatPercent,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved Goals')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } 
    catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  double get totalCalories => double.tryParse(_calorieController.text) ?? 0;

  double get carbsGrams => (totalCalories * carbsPercent / 100) / 4;
  double get proteinGrams => (totalCalories * proteinPercent / 100) / 4;
  double get fatGrams => (totalCalories * fatPercent / 100) / 9;

  double get carbsCals => carbsGrams * 4;
  double get proteinCals => proteinGrams * 4;
  double get fatCals => fatGrams * 9;

  bool get isValid => totalCalories > 0;

  Map<String, double> get macroDataMap {
    return {
      'Carbs': carbsPercent,
      'Protein': proteinPercent,
      'Fat': fatPercent,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Goals", style: TextStyle(fontFamily: 'Poppins',
        fontSize: 16, fontWeight: FontWeight.w700,color: Colors.black,),),
        automaticallyImplyLeading: widget.fromSplash, // hide arrow if from splash
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),

      
      // backgroundColor: Color.fromARGB(255, 203, 217, 217),
      // Color(0xFFDBE4E4)
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Set Your Total Daily Calories!",
                  style: AppTextStyles.headingSmall,
                ),
                const Text(
                  "Don't worry you can always update it later.",
                  style: AppTextStyles.smallTextGrey,
                ),
          
                const SizedBox(height: 15),
          
                buildNormalField("e.g. 2500", Icons.local_fire_department, _calorieController),
          
                const SizedBox(height: 25),
          
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      PieChart(
                        dataMap: macroDataMap,
                        chartType: ChartType.disc,
                        chartRadius: 200,
                        colorList: [Color.fromARGB(255, 146, 167, 163), Color.fromARGB(255, 197, 216, 211), Color.fromARGB(255, 156, 187, 178)],
                        
                        chartValuesOptions: const ChartValuesOptions(
                          showChartValuesInPercentage: true,
                          showChartValuesOutside: false,
                          showChartValueBackground: false,
                        ),
                        
                        legendOptions: const LegendOptions(
                          showLegends: false,
                        ),
                      ),

                      const SizedBox(width: 16),
                        
                      MacroBreakdownText(),
                    ],
                  ),        
          
                const SizedBox(height: 30),
                _buildMacroSlider(
                  label: "Carbs",
                  value: carbsPercent,
                  onChanged: (val) {
                    setState(() {
                      carbsPercent = val.clamp(0, 100 - proteinPercent);
                      fatPercent = 100 - carbsPercent - proteinPercent;
                    });
                  },
                  color: const Color.fromARGB(255, 85, 113, 93),
                ),
          
                _buildMacroSlider(
                  label: "Protein",
                  value: proteinPercent,
                  onChanged: (val) {
                    setState(() {
                      proteinPercent = val.clamp(0, 100 - carbsPercent);
                      fatPercent = 100 - carbsPercent - proteinPercent;
                    });
                  },
                  color: const Color.fromARGB(255, 85, 113, 93),
                ),
          
                Text("Fat: ${fatPercent.toStringAsFixed(0)}%", style: AppTextStyles.body),
          
                const SizedBox(height: 24),
        
                Center(
                  child: ElevatedButton(
                    onPressed: (isValid && !_saving) ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7E7A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      _saving ? 'Saving…' : 'Save & Continue',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                  
                
              ],
            ),
          ),
        
      ),
    );
  }

  Widget _buildMacroSlider({required String label, required double value, required Function(double) onChanged, required Color color}){
    double maxCarbs = 100 - proteinPercent;
    double maxProtein = 100 - carbsPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${value.toStringAsFixed(0)}%", style: AppTextStyles.body),
        
        Slider(
          value: value, 
          onChanged: onChanged,
          min: 0,
          max: 100,
          divisions: 100,
          label: label,
          activeColor: color,
        )
      ],
    );
  }

  Widget MacroBreakdownText(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Macros", style: AppTextStyles.headingSmall),
        const SizedBox(height: 8),

        Text("Carbs - ${carbsGrams.toStringAsFixed(1)}g", style: AppTextStyles.body),
        Text("${carbsCals.toStringAsFixed(1)} cal", style: AppTextStyles.body),
        const SizedBox(height: 8),

        Text("Protein - ${proteinGrams.toStringAsFixed(1)}g", style: AppTextStyles.body),
        Text("${proteinCals.toStringAsFixed(1)} cal", style: AppTextStyles.body),
        const SizedBox(height: 8),
        
        Text("Fats - ${fatGrams.toStringAsFixed(1)}g", style: AppTextStyles.body),
        Text("${fatCals.toStringAsFixed(1)} cal", style: AppTextStyles.body),

        
      ],
    );
  }


}



                // Center(
                //   child: ElevatedButton(
                //     onPressed: isValid ? () async{
                //       await FirestoreService().saveCalorieGoal(
                //         totalCalories: totalCalories,
                //         carbsPercentage: carbsPercent,
                //         proteinPercentage: proteinPercent,
                //         fatPercentage: fatPercent,
                //       );
                //         Navigator.pushReplacement(
                //           context,
                //           MaterialPageRoute(builder: (context) => MainScreen()),
                //         );
                //       }
                //       : null, 
                      
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: Color(0xFF6B7E7A),
                //         shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(30),
                //       ),
                //     ),
                
                //     child: const Text(
                //       "Save & Continue",
                //       style: TextStyle(
                //         fontFamily: 'Poppins',
                //         fontSize: 14,
                //         fontWeight: FontWeight.w600,
                //         color: Colors.white,
                //       ),
                //     ),
                //   ),
                // ),