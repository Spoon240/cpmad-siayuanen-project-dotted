import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';
import '../../widgets/stylesheet.dart';
import '../../widgets/common_bot_nav.dart';

class CreateFoodPage extends StatefulWidget {
  const CreateFoodPage({super.key});
  @override
  State<CreateFoodPage> createState() => _CreateFoodPageState();
}

class _CreateFoodPageState extends State<CreateFoodPage> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final _name = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fats = TextEditingController();
  final _cal = TextEditingController(text: '0'); // auto calculate

  bool _autoCalcCalories = true;       // auto-calc kcal from P/C/F
  final double _tolerancePct = 0.05;   // 5% 

  @override
  void initState() {
    super.initState();
    // whenever macros change and auto-calc is ON, update calories
    void attach(TextEditingController textFields) {
      textFields.addListener(() {
        if (_autoCalcCalories) {
          final kcal = _calcFromMacros(
            _toNum(_protein.text), _toNum(_carbs.text), _toNum(_fats.text),
          );
          _cal.text = _trimZero(kcal.toStringAsFixed(0));
        }
        setState(() {});
      });
    }
    attach(_protein); attach(_carbs); attach(_fats);
  }
  
  
  @override
  void dispose() {
    _name.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fats.dispose();
    _cal.dispose();
    super.dispose();
  }

  void _onSavePressed() async{
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirestoreService().addFood(
        name: _name.text, // no need to trim here anymore
        protein: _toNum(_protein.text),
        carbs: _toNum(_carbs.text),
        fats: _toNum(_fats.text),
        calories: _toNum(_cal.text),
        autoCalc: _autoCalcCalories,
        origin: 'manual',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food saved')),
      );

      Navigator.pop(context);
    } 
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // turns text to number
  num _toNum(String n) {
    return num.tryParse(n.trim()) ?? 0;
  }

  // validators
  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  // for auto cal calories
  double _calcFromMacros(num p, num c, num f) => (4 * p + 4 * c + 9 * f).toDouble();
  
  String _trimZero(String s) {
    // If the string ends with ".0", remove it
    return s.replaceAll(RegExp(r'\.0$'), '');
  }


  String? _nonNegative(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Required';
    }
    final n = num.tryParse(v);
    if (n == null) return 'Numbers only';
    if (n < 0) return 'Cannot be negative';
    return null;
  }


  String? _caloriesValidator(String? cal) {
    final base = _nonNegative(cal);
    if (base != null) return base;

    // if auto-calc, we already set the value; no further checks
    if (_autoCalcCalories) return null;

    // if manual, ensure within tolerance of macro math
    final manual = _toNum(cal!);
    final expected = _calcFromMacros(_toNum(_protein.text), _toNum(_carbs.text), _toNum(_fats.text),);
    if (expected == 0) return null; // allow 0 macros case

    final diff = (manual - expected).abs();
    final allowed = expected * _tolerancePct;
    if (diff > allowed) {
      return 'Calories and macros mismatch (> ${(_tolerancePct * 100).round()}%). ';
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    final expected = _calcFromMacros(_toNum(_protein.text), _toNum(_carbs.text), _toNum(_fats.text));
    // final manual = _toNum(_cal.text);
    // final mismatch = !_autoCalcCalories && expected > 0 &&(manual - expected).abs() > expected * _tolerancePct;

    InputDecoration labels(String label, Icon icon) {
      return InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(18),

        // Icon passed from parameter
        prefixIcon: icon,

        helperText: ' ',

        // Borders
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: buildCreateFoodAppBar("Create Food"),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("Name", style: AppTextStyles.bodyH,),
              TextFormField(
                controller: _name,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,),
                decoration: labels('Name', const Icon(Icons.food_bank, color: Colors.grey)),
                validator: _required,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 0),

              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-calc calories from macros', style: AppTextStyles.bodyH),
                      value: _autoCalcCalories,
                      onChanged: (cal) {
                        setState(() {
                          _autoCalcCalories = cal; // remember ON or OFF

                          final exp = _trimZero(expected.toStringAsFixed(0)); // current expected kcal

                          if (cal) {
                            // Turning ON auto mode
                            //snap the Calories field to the exact expected value from P/C/F
                            _cal.text = exp;
                          } 
                          else {
                            // Turning OFF auto mode
                            // → give the user a starting point if Calories is empty or 0
                            if (_cal.text.trim().isEmpty || _cal.text.trim() == '0') {
                              _cal.text = exp;
                            }
                          }
                        });
                      },
                    ),
                  ),
                ],
              ), // switch

              const Text("Calories", style: AppTextStyles.bodyH,),
              TextFormField(
                controller: _cal,
                readOnly: _autoCalcCalories,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,),
                decoration: labels('Calories', const Icon(Icons.local_fire_department, color: Colors.grey)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _caloriesValidator,
              ),

              // Always show guidance under the field (helper separate from decoration)
              if (!_autoCalcCalories)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Expected ≈ ${expected.toStringAsFixed(0)} kcal (4P + 4C + 9F)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 20),


              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Protein", style: AppTextStyles.bodyH,),
                        TextFormField(
                          controller: _protein,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,),
                          decoration: labels('Protein', const Icon(Icons.set_meal_sharp, color: Colors.grey)),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: _nonNegative,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Carbs", style: AppTextStyles.bodyH,),
                        TextFormField(
                          controller: _carbs,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,),
                          decoration: labels('Carbs', const Icon(Icons.breakfast_dining, color: Colors.grey)),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: _nonNegative,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 0),

              const Text("Fats", style: AppTextStyles.bodyH,),
              TextFormField(
                controller: _fats,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,),
                decoration: labels('Fats',const Icon(Icons.water_drop_rounded, color: Colors.grey)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _nonNegative,
              ),
                  

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onSavePressed, // now runs your validation + snackbar
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7E7A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ), // button

            ],
          ),
        ),
      ),
    );
  }
}