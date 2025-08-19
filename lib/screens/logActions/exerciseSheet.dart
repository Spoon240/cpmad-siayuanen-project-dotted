import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../widgets/stylesheet.dart';

class ExercisePickerSheet extends StatefulWidget {
  const ExercisePickerSheet({super.key});

  @override
  State<ExercisePickerSheet> createState() => ExercisePickerSheetState();
}

class ExercisePickerSheetState extends State<ExercisePickerSheet> {
  late final Future<List<Map<String, dynamic>>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = FirestoreService().fetchExercises(); // your existing service
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Pick an exercise', style: AppTextStyles.body),
          const SizedBox(height: 6),

          SizedBox(
            height: 360,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _exercisesFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No exercises created yet', style: AppTextStyles.bodyHint),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1.2),
                  itemBuilder: (_, i) {
                    final m = items[i];
                    final name = (m['name'] ?? '').toString();
                    final cals = (m['calories_burned'] ?? m['calories'] ?? 0) as num;
                    final intensity = (m['intensity'] ?? '').toString();

                    return ListTile(
                      title: Text(name, style: AppTextStyles.body),
                      subtitle: Text(
                        '${cals.round()} kcal  ·  ${intensity.isEmpty ? '—' : intensity}',
                        style: AppTextStyles.bodyHintSmall2,
                      ),
                      onTap: () => Navigator.pop(context, {
                        'name': name,
                        'calories': cals,
                        'intensity': intensity,
                      }),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
