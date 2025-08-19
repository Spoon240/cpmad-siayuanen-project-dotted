import 'package:flutter/material.dart';
import '../../widgets/common_bot_nav.dart';
import '../../widgets/stylesheet.dart';
import '../../services/firestore_service.dart';


class PortionPage extends StatefulWidget {
  final Map<String, dynamic> item;
  const PortionPage({super.key, required this.item});

  @override
  State<PortionPage> createState() => _PortionPageState();
}

class _PortionPageState extends State<PortionPage> {
  late double grams; // user-chosen grams
  late Map<String, num> per100; // nutrients per 100g

  late final TextEditingController _gramsCtrl;

  static const double minG = 0;
  static const double maxG = 500;

  String? _gramsError; // shown under the field

  bool _saving = false;


  @override
  void initState() {
    super.initState();
    per100 = Map<String, num>.from(widget.item['nutrientsPer100g'] ?? {});
    final pkg = widget.item['packageWeightG'];
    grams = (pkg is num && pkg > 0) ? pkg.toDouble() : 100.0; // sensible default
    _gramsCtrl = TextEditingController(text: grams.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    super.dispose();
  }

  // keep everything in sync
  // 1) setGrams: only auto-clear error if change did NOT come from the text field
  void setGrams(double g, {bool fromField = false}) {
    final clamped = (g.clamp(minG, maxG)) as double;

    if (!fromField && _gramsError != null && clamped >= minG && clamped <= maxG) {
      setState(() => _gramsError = null);
    }

    if (clamped == grams) {
      if (!fromField) {
        final txt = clamped.toStringAsFixed(0);
        _gramsCtrl.value = TextEditingValue(
          text: txt,
          selection: TextSelection.collapsed(offset: txt.length),
        );
      }
      return;
    }

    setState(() => grams = clamped);

    if (!fromField) {
      final txt = grams.toStringAsFixed(0);
      _gramsCtrl.value = TextEditingValue(
        text: txt,
        selection: TextSelection.collapsed(offset: txt.length),
      );
    }
  }

  Map<String, double> _calc(double g) {
    final f   = g / 100.0;
    final cal = (per100['calories'] ?? 0).toDouble() * f;
    final p   = (per100['protein']  ?? 0).toDouble() * f;
    final c   = (per100['carbs']    ?? 0).toDouble() * f;
    final fat = (per100['fat']      ?? 0).toDouble() * f;
    return {
      'calories': cal,
      'protein': p,
      'carbs': c,
      'fat': fat,
    };
  }

    void _onSavePressed() async{
      // close keyboard
      FocusScope.of(context).unfocus();

      // validate grams from the field (not the clamped state)
      final typed = double.tryParse(_gramsCtrl.text);
      if (typed == null) {
        setState(() => _gramsError = 'Numbers only');
        return;
      }
      if (typed <= 0) {
        setState(() => _gramsError = 'Grams cannot be zero');
        return;
      }
      if (typed > maxG) {
        setState(() => _gramsError = 'Please enter between ${minG.toInt()+1} and ${maxG.toInt()} g');
        return;
      }

      // compute macros for chosen grams
      final m = _calc(grams);
      final calories = m['calories']!.round();
      final protein  = double.parse(m['protein']!.toStringAsFixed(1));
      final carbs    = double.parse(m['carbs']!.toStringAsFixed(1));
      final fats     = double.parse(m['fat']!.toStringAsFixed(1));

      // combined name + grams (your chosen style)
      final baseName   = (widget.item['name'] ?? '').toString().trim();
      final displayName = '$baseName - ${grams.round()}g';

      try {
        setState(() => _saving = true);

        await FirestoreService().addFood(
          name: displayName,
          protein: protein,
          carbs: carbs,
          fats: fats,
          calories: calories,
          autoCalc: true,
          origin: 'barcode',
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food saved')),
        );
        Navigator.pop(context, true);
      } 
      catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }

    }

  @override
  Widget build(BuildContext context) {
    final name  = (widget.item['name']  ?? '') as String;
    final brand = (widget.item['brand'] ?? '') as String;
    final pkg   = widget.item['packageWeightG'];
    final macros = _calc(grams);

    List<Widget> _presetChips() {
      final chips = <Widget>[
        ActionChip(label: const Text('50g'), onPressed: () => setGrams(50)),
        ActionChip(label: const Text('100g'), onPressed: () => setGrams(100)),
      ];
      if (pkg is num && pkg > 0) {
        chips.insert(0, ActionChip(label: Text('1 bar (${pkg}g)'), onPressed: () => setGrams(pkg.toDouble())));
        chips.insert(1, ActionChip(label: const Text('½ bar'), onPressed: () => setGrams(pkg.toDouble() * 0.5)));
        chips.insert(2, ActionChip(label: const Text('¼ bar'), onPressed: () => setGrams(pkg.toDouble() * 0.25)));
      }
      return chips;
    }

    return Scaffold(
      appBar: buildCreateFoodAppBar("Choose Portion"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(name, style: AppTextStyles.headingSmall),
            if (brand.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(brand, style: AppTextStyles.body),
              ),
            const SizedBox(height: 8),
            Text(
              'Per 100g: ${per100['calories'] ?? 0} kcal  |  P: ${per100['protein'] ?? 0}g  C: ${per100['carbs'] ?? 0}g  F: ${per100['fat'] ?? 0}g',
              style: AppTextStyles.label
            ), // header

            const SizedBox(height: 16),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _presetChips(),
            ), // chips

            const SizedBox(height: 16),

            // Grams input + slider
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Portion (grams)'),
                      Slider(
                        value: grams,
                        min: minG, 
                        max: maxG, 
                        divisions: (maxG - minG).toInt(),
                        label: '${grams.toStringAsFixed(0)} g',
                        onChanged: (g) => setGrams(g), // set grams
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _gramsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),

                    decoration: const InputDecoration(
                      labelText: 'g',
                      border: OutlineInputBorder(),
                    ),
                    
                    onChanged: (v) {
                      final n = double.tryParse(v);
                      if (n == null) {
                        setState(() => _gramsError = 'Numbers only');
                        return;
                      }
                      if (n < minG || n > maxG) {
                        setState(() => _gramsError = 'Please enter between ${minG.toStringAsFixed(0)} and ${maxG.toStringAsFixed(0)} g');
                        return;
                      }
                      if (n == 0){
                        setState(() => _gramsError = 'Cannot be zero');
                        return;
                      }
                      else {  
                        if (_gramsError != null) setState(() => _gramsError = null);
                      }
                      setGrams(n, fromField: true);
                    },
                    onEditingComplete: () {
                      setGrams(double.tryParse(_gramsCtrl.text) ?? grams);
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MacroTile('Calories', macros['calories']!.round().toString()),
                    _MacroTile('Protein',  '${macros['protein']!.toStringAsFixed(1)} g'),
                    _MacroTile('Carbs',    '${macros['carbs']!.toStringAsFixed(1)} g'),
                    _MacroTile('Fat',      '${macros['fat']!.toStringAsFixed(1)} g'),
                  ],
                ),
              ),
            ),

            const Spacer(),

            if (_gramsError != null) // error mesage
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                _gramsError!,
                style: AppTextStyles.bodyError,
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              // Save button  
              child: ElevatedButton(
                onPressed: (_gramsError != null || _saving) ? null : _onSavePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7E7A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
            ),

            
          ],
        ),
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final String value;
  const _MacroTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.body),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodyHintSmall),
      ],
    );
  }
}
