import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/stylesheet.dart';
import '../services/firestore_service.dart';
import '../widgets/add_sheet.dart';


class FoodLibraryPage extends StatefulWidget {
  const FoodLibraryPage({super.key});

  @override
  State<FoodLibraryPage> createState() => _FoodLibraryPageState();
}

class _FoodLibraryPageState extends State<FoodLibraryPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  bool _selectMode = false;
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await FirestoreService().fetchFoods();
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } 
    catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _enterSelect(String id) {
    setState(() {
      _selectMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectMode = false;
      } 
      else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _confirmDelete() async {
    if (_selectedIds.isEmpty) return;

    final response = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete selected?'),
        content: Text('This will delete ${_selectedIds.length} item(s).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (response != true) return;
    try {
      setState(() => _loading = true);

      final errors = <String>[];

      for (final m in _items) {
        final id = (m['id'] ?? '').toString();
        if (id.isEmpty) continue;

        if (_selectedIds.contains(id)) {
          try {
            await FirestoreService().deleteFood(id);
          } 
          catch (e) {
            errors.add('Failed $id: $e');
          }
        }
      }

      if (!mounted) return;
      _clearSelection();
      await _loadFoods();

      if (errors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted successfully')),
        );
      } 
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Some items could not be deleted'))
        );
      }
    } 
    catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }

  }


  Future<void> _openEditFoodDialog(Map<String, dynamic> m) async {
    final id    = (m['id'] ?? '').toString();
    final name  = (m['name'] ?? '').toString();
    final pCtrl = TextEditingController(text: ((m['protein']  ?? 0) as num).toString());
    final cCtrl = TextEditingController(text: ((m['carbs']    ?? 0) as num).toString());
    final fCtrl = TextEditingController(text: ((m['fats']     ?? 0) as num).toString());

    int calcKcal() => _calcCalories(_num(pCtrl.text), _num(cCtrl.text), _num(fCtrl.text));
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ct, set) => AlertDialog(
          scrollable: true,
          title: const Text('Edit Food (Macros only)'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name (read-only label)
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                _numField(
                  label: 'Protein (g)',
                  ctrl: pCtrl,
                  onChanged: (c) => set(() {}), // refresh kcal
                ),
                const SizedBox(height: 8),
                _numField(
                  label: 'Carbs (g)',
                  ctrl: cCtrl,
                  onChanged: (c) => set(() {}),
                ),
                const SizedBox(height: 8),
                _numField(
                  label: 'Fats (g)',
                  ctrl: fCtrl,
                  onChanged: (c) => set(() {}),
                ),

                const SizedBox(height: 12),

                // Calories (auto, read-only display)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Calories (auto)', style: TextStyle(fontSize: 13)),
                    Builder(
                      builder: (c) {
                        final kcal = calcKcal();
                        return Text('$kcal kcal', style: const TextStyle(fontWeight: FontWeight.w600));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Unfocus first to avoid framework assertions
                FocusScope.of(ct).unfocus();
                Navigator.pop(ct, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;

                final kcal = calcKcal();
                if (kcal <= 0) {
                  return;
                }

                FocusScope.of(ct).unfocus();
                Navigator.pop(ct, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final kcal = calcKcal();
      await FirestoreService().updateFoodMacrosAuto(
        id: id,
        protein: _num(pCtrl.text),
        carbs: _num(cCtrl.text),
        fats: _num(fCtrl.text),
        calories: kcal,
      );
      if (!mounted) return;
      await _loadFoods();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Food updated')));
    }

  }


  double _num(String s) => double.tryParse(s.trim()) ?? 0;
  int _calcCalories(num p, num c, num f) => (p * 4 + c * 4 + f * 9).round();

  Widget _numField({required String label, required TextEditingController ctrl, void Function(String)? onChanged}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        final s = (v ?? '').trim();
        if (s.isEmpty) return 'Required';
        final x = double.tryParse(s);
        if (x == null) return 'Numbers only';
        if (x < 0) return 'Must be ≥ 0';
        if (x > 2000) return 'Too large';
        return null;
      },
      onChanged: onChanged,
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (c) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error loading foods', style: AppTextStyles.bodyH),
                  const SizedBox(height: 6),
                  Text(_error!, style: AppTextStyles.bodyH_NotBold),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadFoods,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadFoods,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No foods yet')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadFoods,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final m = _items[i];
                final id   = (m['id'] ?? '').toString(); // ensure fetch includes id
                final name = (m['name'] ?? '').toString();
                final cal  = (m['calories'] ?? 0) as num;
                final p    = (m['protein']  ?? 0) as num;
                final c    = (m['carbs']    ?? 0) as num;
                final f    = (m['fats']     ?? 0) as num;
                final origin    = (m['origin'] ?? '').toString().toLowerCase();

                final selected = _selectedIds.contains(id);

                return GestureDetector(
                  onLongPress: () {
                    SystemSound.play(SystemSoundType.click); 
                    _enterSelect(id);
                  },
                  onTap: () {
                    if (_selectMode) {
                      SystemSound.play(SystemSoundType.click); 
                      _toggleSelect(id);
                    } 
                  },
                  child: Opacity(
                    opacity: selected ? 0.5 : 1.0,
                    child: Stack(
                      children: [
                        PillCard(
                          accentColor: const Color(0xFF2E6D62),
                          title: name,
                          subtitle: 'Calories ${cal.round()}   |   P $p g   C $c g   F $f g',
                        ),
                        if (_selectMode)
                          Positioned(
                            top: 8,
                            right: 12,
                            child: Icon(
                              selected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: selected ? const Color.fromARGB(255, 46, 37, 63) : const Color.fromARGB(255, 66, 66, 66),
                            ),
                          ),

                        if (!_selectMode && origin!='barcode')
                          Positioned(
                            top: 8,
                            right: 12,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _openEditFoodDialog(m),
                                child: Container(
                                  width: 32, 
                                  height: 32,
                                  child: const Icon(Icons.edit, size: 18, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),

      // FAB switches between Add and Delete
      floatingActionButton: _selectMode
          ? FloatingActionButton.extended(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text('Delete', style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFFB94B4B),
            )
          : FloatingActionButton.extended(
              onPressed: () => openAddSheet(context, onReload: _loadFoods),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add", style: AppTextStyles.buttonText),
              backgroundColor: const Color(0xFF6B7E7A),
            ),
      
    );
  }
}
