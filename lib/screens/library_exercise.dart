import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/stylesheet.dart';
import '../services/firestore_service.dart';
import '../widgets/add_sheet.dart';

class ExerciseLibrary extends StatefulWidget {
  const ExerciseLibrary({super.key});

  @override
  State<ExerciseLibrary> createState() => _ExerciseLibraryState();
}

class _ExerciseLibraryState extends State<ExerciseLibrary> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  bool _selectMode = false;
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  Future<void> _loadExercise() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await FirestoreService().fetchExercises();
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
            await FirestoreService().deleteExercise(id);
          } 
          catch (e) {
            errors.add('Failed $id: $e');
          }
        }
      }

      if (!mounted) return;
      _clearSelection();
      await _loadExercise();

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


  Future<void> _openEditExerciseDialog(Map<String, dynamic> item) async {
    final formKey   = GlobalKey<FormState>();
    final nameCtrl  = TextEditingController(text: (item['name']).toString());
    final calCtrl   = TextEditingController(text: (item['calories_burned']).toString());

    // Use your existing intensity values. Adjust the options if yours differ.
    const options = ['Light', 'Moderate', 'Vigorous'];
    String intensity = options.contains((item['intensity'] ?? '').toString())
        ? (item['intensity'] as String)
        : 'Moderate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, set) => AlertDialog(
            title: const Text('Edit Exercise'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  // Prevent overflow on small screens/keyboard open
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return 'Name is required';
                          if (s.length > 60) return 'Keep it under 60 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: calCtrl,
                        decoration: const InputDecoration(labelText: 'Calories burned'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: intensity,
                        decoration: const InputDecoration(labelText: 'Intensity'),
                        items: options
                            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                            .toList(),
                        onChanged: (v) => set(() => intensity = v ?? 'Moderate'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      final id = (item['id']).toString();
      await FirestoreService().updateExercise(
        id: id,
        name: nameCtrl.text.trim(),
        caloriesBurned: int.parse(calCtrl.text.trim()),
        intensity: intensity,
      );
      if (!mounted) return;
      await _loadExercise();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise updated')),
      );
    }
    nameCtrl.dispose();
    calCtrl.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (_) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error loading exercises', style: AppTextStyles.bodyH),
                  const SizedBox(height: 6),
                  Text(_error!, style: AppTextStyles.bodyH_NotBold),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadExercise,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadExercise,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No Exercise yet')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadExercise,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final exercise = _items[i];
                final id   = (exercise['id'] ?? '').toString();
                final name = (exercise['name'] ?? '').toString();
                final cal  = (exercise['calories_burned'] ?? 0) as num;
                final intensity = (exercise['intensity'] ?? '').toString();

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
                          accentColor: const Color(0xFFB94B4B), // red for exercise
                          title: name,
                          subtitle: 'Burns ${cal.round()} kcal  -  $intensity',
                        ),
                        if (_selectMode)
                          Positioned(
                            top: 8,
                            right: 12,
                            child: Icon(
                              selected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: selected
                                  ? const Color.fromARGB(255, 46, 37, 63)
                                  : const Color.fromARGB(255, 66, 66, 66),
                            ),
                          ),
                        if (!_selectMode)
                          Positioned(
                            top: 8,
                            right: 12,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _openEditExerciseDialog(exercise),
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

      floatingActionButton: _selectMode
          ? FloatingActionButton.extended(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text('Delete', style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFFB94B4B),
            )
          : FloatingActionButton.extended(
              onPressed: () => openAddSheet(context, onReload: _loadExercise),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add", style: AppTextStyles.buttonText),
              backgroundColor: const Color(0xFF6B7E7A),
            ),
    );
  }
}



