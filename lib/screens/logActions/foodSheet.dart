import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../widgets/stylesheet.dart';

class FoodPickerSheet extends StatefulWidget {
  const FoodPickerSheet({super.key});

  @override
  State<FoodPickerSheet> createState() => FoodPickerSheetState();
}

class FoodPickerSheetState extends State<FoodPickerSheet>{
  late final Future<List<Map<String, dynamic>>> _myFoodsFuture;
  late final Future<List<Map<String, dynamic>>> _globalFoodsFuture;

  @override
  void initState() {
    super.initState();
    _myFoodsFuture = FirestoreService().fetchFoods();
    _globalFoodsFuture = FirestoreService().fetchGlobalFoods(); // new
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 2,
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
            const Text('Pick a food', style: AppTextStyles.body),
            const SizedBox(height: 6),

            // Tabs
            const TabBar(
              labelColor: Colors.black,          // text color for the active tab
              unselectedLabelColor: Colors.grey, // text color for inactive tabs
              indicatorColor: Colors.black, 
              labelStyle: AppTextStyles.bodyH,
              tabs: [
                Tab(text: 'My Foods',),
                Tab(text: 'Global'),
              ],
            ),

            // Content
            SizedBox(
              height: 360,
              child: TabBarView(
                children: [
                  // My Foods tab
                  _FoodsList(future: _myFoodsFuture, emptyText: 'No foods created yet'),
                  // Global tab
                  _FoodsList(future: _globalFoodsFuture, emptyText: 'No global foods found'),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Reusable list widget for both tabs
class _FoodsList extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final String emptyText;

  const _FoodsList({required this.future, required this.emptyText, super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Center(child: Text(emptyText, style: AppTextStyles.bodyHint));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, i) => const Divider(height: 1, thickness: 1.2),
          itemBuilder: (context, i) {
            final m = items[i];
            final name = (m['name'] ?? '').toString();
            final cals = (m['calories'] ?? 0) as num;

            return ListTile(
              title: Text(name, style: AppTextStyles.body),
              subtitle: Text('${cals.round()} kcal', style: AppTextStyles.bodyHintSmall2),
              onTap: () => Navigator.pop(context, {
                'name': name,
                'calories': cals,
                'protein': (m['protein'] ?? 0) as num,
                'carbs'  : (m['carbs']   ?? 0) as num,
                'fats'   : (m['fats']    ?? 0) as num,
              }),
            );
          },
        );
      },
    );
  }
}