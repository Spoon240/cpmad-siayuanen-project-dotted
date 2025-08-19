import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../widgets/stylesheet.dart';
import '../../widgets/common_bot_nav.dart';
import 'dart:async';
import 'searchBarcode_Portion_page.dart';

class BarcodeSearchScreen extends StatefulWidget {
  const BarcodeSearchScreen({super.key});

  @override
  State<BarcodeSearchScreen> createState() => _BarcodeSearchScreenState();
}

class _BarcodeSearchScreenState extends State<BarcodeSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _searched = false;
  List<Map<String, dynamic>> _results = [];
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel(); // cleanup
    super.dispose();
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }



  Future<void> _search() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final res = await FirestoreService().getBarcodeFood(_controller.text.trim());
      if (!mounted) return;
      setState(() {
        _searched = true;
        _results = res != null ? [res] : [];
      });
    } 
    catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }


  void _onBarcodeChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.trim().isNotEmpty) {
        final resList = await FirestoreService().searchBarcodesByPrefix(value.trim());
        if (!mounted) return;
        setState(() {
          _searched = true;
          _results = resList; // store multiple
        });
      } 
      else {
        setState(() => _results = []);
      }
    });
  }

  String _subtitleFor(Map<String, dynamic> item) {
    final per100 = Map<String, dynamic>.from(item['nutrientsPer100g'] ?? {});
    final cal = (per100['calories'] ?? 0).toString();
    final p = (per100['protein'] ?? 0).toString();
    final c = (per100['carbs'] ?? 0).toString();
    final f = (per100['fat'] ?? 0).toString();

    final pkg = item['packageWeightG'];
    String perPkg = '';
    if (pkg is num) {
      final pkgCal = ((per100['calories'] ?? 0) * (pkg / 100)).round();
      perPkg = '\n~$pkgCal kcal per ${pkg}g package';
    }

    return '${cal} kcal / 100g | P: ${p}g  C: ${c}g  F: ${f}g$perPkg';
  }


  InputDecoration _inputStyle(String label, Icon icon) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(18),
      prefixIcon: icon,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCreateFoodAppBar("Search by Barcode"),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 2),
              const Text("Barcode Number", style: AppTextStyles.bodyH),
              const SizedBox(height: 10),

              TextFormField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: _inputStyle(
                  'Enter barcode number',
                  const Icon(Icons.qr_code_scanner, color: Colors.grey),
                ),
                validator: _required,
                onChanged: _onBarcodeChanged, // <-- triggers debounce search
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7E7A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Search",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_searched && _results.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Item not found. We currently don’t have this barcode.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  ),
                ),

              ..._results.map((item) => Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF6B7E7A),
                    child: Icon(Icons.fastfood, color: Colors.white),
                  ),
                  title: Text(item['name'], style: AppTextStyles.body),
                  subtitle: Text(_subtitleFor(item), style: AppTextStyles.bodyHintSmall),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => PortionPage(item: item)),
                    );


                  },
                ),
              )).toList()
            ],
          ),
        ),
      ),
    );
  }
}






// Future<void> updateBarcodeRecord() async {
//   final firestore = FirebaseFirestore.instance;

//   // Replace with your barcode document ID if using barcode as doc id
//   const barcode = "8888000123456";

//   await firestore.collection('barcodes').doc(barcode).set({
//     "barcode": barcode,
//     "name": "Brand X Protein Bar (Chocolate)",
//     "brand": "Brand X",
//     "nutrientsPer100g": {
//       "calories": 350,
//       "protein": 33,
//       "carbs": 37,
//       "fat": 12,
//     },
//     "packageWeightG": 60, // 1 bar = 60g
//     "updatedAt": DateTime.now().millisecondsSinceEpoch,
//   });

//   print("Barcode $barcode updated successfully!");
// }