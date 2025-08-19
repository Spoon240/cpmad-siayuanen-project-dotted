import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/stylesheet.dart';
import '../controllers/diary_provider.dart';
import 'logActions/exerciseSheet.dart';
import 'logActions/foodSheet.dart';

class FoodLogPage extends StatefulWidget {
  const FoodLogPage({super.key});

  @override
  State<FoodLogPage> createState() => _FoodLogPageState();
}

class _FoodLogPageState extends State<FoodLogPage> {
  Future<void> _openFoodPicker(BuildContext context, String meal) async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const FoodPickerSheet(),
    );

    if (picked != null && context.mounted) {
      await context.read<DiaryProvider>().addFood(
        name: (picked['name'] ?? '').toString(),
        calories: (picked['calories'] ?? 0) as num,
        meal: meal,
        protein: picked['protein'] as num?,
        carbs: picked['carbs'] as num?,
        fats: picked['fats'] as num?,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to diary')),
      );
    }
  }

  Future<void> _openExercisePicker(BuildContext context) async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const ExercisePickerSheet(),
    );

    if (picked != null && context.mounted) {
      await context.read<DiaryProvider>().addExercise(
        name: (picked['name'] ?? '').toString(),
        calories: (picked['calories'] ?? 0) as num,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // listen to provider
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: true);

    final exercises = diaryProvider.exercises;


    List<Widget> asLines(Iterable<Map<String, dynamic>> list) {
      return list.map((e) {
        final name = e['name'] ?? '';
        final calories = (e['calories'] ?? 0).round().toString();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name.toString(),
                style: AppTextStyles.bodyHintSmall2,
                overflow: TextOverflow.ellipsis, // prevent overflow
              ),
            ),
            Text(
              '$calories kcal',
              style: AppTextStyles.bodyHintSmall2,
            ),
          ],
        );
      }).toList();
    }

    final breakfast = diaryProvider.meal('breakfast');
    final lunch     = diaryProvider.meal('lunch');
    final dinner    = diaryProvider.meal('dinner');
    final snacks    = diaryProvider.meal('snacks');

    final goal = diaryProvider.goal ?? 0;
    final totalFoodCal = diaryProvider.totalFoodCalories.round();
    final totalExerciseCal = diaryProvider.totalExerciseCalories.round();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header using provider values
              CaloriesRemainingHeader(goal, totalFoodCal, totalExerciseCal),
              const SizedBox(height: 10),

              mealSection(
                title: 'Breakfast',
                total: breakfast.fold<num>(0, (s, e) => s + (e['calories'] ?? 0)),
                loggedFoods: asLines(breakfast),
                onAddFood: () => _openFoodPicker(context, 'breakfast'),
                isMeals: true,
              ),
              const SizedBox(height: 10),

              mealSection(
                title: 'Lunch',
                total: lunch.fold<num>(0, (s, e) => s + (e['calories'] ?? 0)),
                loggedFoods: asLines(lunch),
                onAddFood: () => _openFoodPicker(context, 'lunch'),
                isMeals: true,
              ),
              const SizedBox(height: 10),

              mealSection(
                title: 'Dinner',
                total: dinner.fold<num>(0, (s, e) => s + (e['calories'] ?? 0)),
                loggedFoods: asLines(dinner),
                onAddFood: () => _openFoodPicker(context, 'dinner'),
                isMeals: true,
              ),
              const SizedBox(height: 10),

              mealSection(
                title: 'Snacks',
                total: snacks.fold<num>(0, (s, e) => s + (e['calories'] ?? 0)),
                loggedFoods: asLines(snacks),
                onAddFood: () => _openFoodPicker(context, 'snacks'),
                isMeals: true,
              ),
              const SizedBox(height: 10),

              mealSection(
                title: 'Exercise',
                total: diaryProvider.totalExerciseCalories,
                loggedFoods: asLines(exercises),
                onAddFood: () => _openExercisePicker(context),
                isMeals: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// CALORIES REMAINING
// GOALS - CALORIES + EXERCISE = REMAINING
Widget CaloriesRemainingHeader(int goal, num food, num exercise) {
  final int remaining = goal - food.round() + exercise.round();
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Calories Remaining', style: AppTextStyles.body),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _labelNameType('Goals', goal),
            const Text('-', style: AppTextStyles.equation),
            _labelNameType('Calories', food.round()),
            const Text('+', style: AppTextStyles.equation),
            _labelNameType('Exercise', exercise.round()),
            const Text('=', style: AppTextStyles.equation),
            _labelNameType('Remaining', remaining),
          ],
        )
      ],
    ),
  );
}

Widget _labelNameType(String label, int value) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(value.toString(), style: AppTextStyles.equation),
      Text(label, style: AppTextStyles.equationSmall),
    ],
  );
}


// FOR FOOD LOGGED IN MEAL(BREAKFAST, LUNCH, DINNER, SNACK, EXECERISE)
Widget mealSection({required String title, required num total, required List<Widget> loggedFoods, required VoidCallback onAddFood, required bool isMeals,}) {
  return Container(
    color: const Color.fromARGB(255, 216, 216, 216),
    padding: const EdgeInsets.fromLTRB(18, 15, 18, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.body),
            Text(total.round().toString(), style: AppTextStyles.body),
          ],
        ),
        const Divider(thickness: 1, height: 15, color: Colors.grey),

        if (loggedFoods.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: loggedFoods
                .map((foodRow) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: foodRow,
                    ))
                .toList(),
          ),
        const SizedBox(height: 0),
        TextButton(
          onPressed: onAddFood,
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(
            isMeals ? 'Add Food' : 'Add Exercise',
            style: AppTextStyles.link,
          ),
        ),
      ],
    ),
  );
}
