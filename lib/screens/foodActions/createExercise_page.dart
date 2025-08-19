import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/stylesheet.dart';
import '../../widgets/common_bot_nav.dart';
import '../../services/firestore_service.dart';

class CreateExercisePage extends StatefulWidget {
  const CreateExercisePage({super.key});

  @override
  State<CreateExercisePage> createState() => _CreateExercisePageState();
}

class _CreateExercisePageState extends State<CreateExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cal  = TextEditingController();

  bool _saving = false;
  String _intensity = 'Moderate'; // required: Light | Moderate | Vigorous

  InputDecoration labels(String label, Icon icon, {bool isDropdown = false}) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
      filled: true,
      fillColor: Colors.white,

      // Adjust padding for dropdowns vs text fields
      contentPadding: isDropdown
          ? const EdgeInsets.symmetric(vertical: 15, horizontal: 12) // less vertical for dropdown
          : const EdgeInsets.symmetric(vertical: 18, horizontal: 12),

      prefixIcon: icon,
      helperText: ' ',

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _cal.dispose();
    super.dispose();
  }

  void _onSavePressed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _saving = true);

      await FirestoreService().addExercise(
        name: _name.text,
        caloriesBurned: int.parse(_cal.text.trim()),
        intensity: _intensity,
      );
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise saved')),
      );
      Navigator.pop(context, true); // or: Navigator.pop(context, id);
    } 
    catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCreateFoodAppBar("Create Exercise"),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 10),
              // Exercise name
              const Text("Exercise Name", style: AppTextStyles.bodyH,),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,),
                decoration: labels('Name', const Icon(Icons.airline_seat_recline_normal_outlined, color: Colors.grey)),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return 'Name is required';
                  if (s.length < 2) return 'Name is too short';
                  if (s.length > 60) return 'Keep it under 60 characters';
                  return null;
                },
              ),  // Exercise name
              const SizedBox(height: 7),//////

              // Calories burned + Intensity
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calories
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Calories", style: AppTextStyles.bodyH,),

                        TextFormField(
                          controller: _cal,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,),

                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: labels('Calories Burned', const Icon(Icons.local_fire_department_sharp, color: Colors.grey)),
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return 'Required';
                            final n = int.tryParse(s);
                            if (n == null) return 'Numbers only';
                            if (n <= 0) return 'Must be > 0';
                            if (n > 2000) return 'Seems too high';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ), // calories
                  const SizedBox(width: 12),


                  // Intensity
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[ 
                        const Text("Intensity", style: AppTextStyles.bodyH,),

                        DropdownButtonFormField<String>(
                          value: _intensity,
                          items: const [
                            DropdownMenuItem(value: 'Light',    child: Text('Light',    style: TextStyle(fontFamily: 'Poppins', fontSize: 12))),
                            DropdownMenuItem(value: 'Moderate', child: Text('Moderate', style: TextStyle(fontFamily: 'Poppins', fontSize: 12))),
                            DropdownMenuItem(value: 'Vigorous', child: Text('Vigorous', style: TextStyle(fontFamily: 'Poppins', fontSize: 12))),
                          ],
                          decoration: labels('Intensity', const Icon(Icons.fitness_center_outlined, color: Colors.grey), isDropdown: true),
                          onChanged: (v) => setState(() => _intensity = v ?? 'Moderate'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ]
                    ),
                  ), // intensity dropdown box

                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _onSavePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7E7A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _saving ? 'Saving…' : 'Save',
                    style: const TextStyle(
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
