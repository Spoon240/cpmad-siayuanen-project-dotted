import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';



class DiaryProvider extends ChangeNotifier {
  // No constructor args needed now
  DiaryProvider();

  DateTime _day = DateTime.now();
  DateTime get day => _day;

  int? goal; // null while loading
  List<Map<String, dynamic>> _entries = const [];
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  StreamSubscription? _goalSub;

  Future<void> load() async {
    // Start live goal subscription so no need to fetch everytime
    _goalSub?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _goalSub = FirebaseFirestore.instance.collection('users').doc(uid).collection('goals').doc('current').snapshots()
        .listen((doc) {
          final data = doc.data();
          final g = (data?['calorieGoals']?['totalCalories'] as num?); // getting the total calories
          goal = g?.round();
          notifyListeners();
        });
    }

    _subscribeToDay(); // your existing entries stream
  }

  void _subscribeToDay() {
    _sub?.cancel();
    _sub = FirestoreService().streamDiaryEntries(_day).listen((list) {
      _entries = list;   // [{"id": "xxxxxx", "name": "Chicken Rice", "calories": 500, "type": "food"},]
      notifyListeners();
    });
  }

  set day(DateTime d) {
    _day = DateTime(d.year, d.month, d.day);
    _subscribeToDay();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _goalSub?.cancel();
    super.dispose();
  }


  // --------------
  // -------- getters
  List<Map<String, dynamic>> get entries => _entries; // [{"id": "xxxxxx", "name": "Chicken Rice", "calories": 500, "type": "food"}, ...]

  Iterable<Map<String, dynamic>> get foods => _entries.where((e) => e['type'] == 'food'); // get all food

  Iterable<Map<String, dynamic>> get exercises => _entries.where((e) => e['type'] == 'exercise'); // get all exercise

  num get totalFoodCalories => foods.fold<num>(0, (s, e) => s + (e['calories'] ?? 0)); // sum all food calories

  num get totalExerciseCalories => exercises.fold<num>(0, (s, e) => s + (e['calories'] ?? 0)); // sum all exercise calories

  int get remainingCalories => (goal ?? 0) - totalFoodCalories.round() + totalExerciseCalories.round();

  Iterable<Map<String, dynamic>> meal(String key) => foods.where((e) => (e['meal'] ?? '') == key);


  // --------------
  // --------------
  Future<void> addFood({
    required String name,
    required num calories,
    required String meal, // breakfast | lunch | dinner | snacks
    num? protein,
    num? carbs,
    num? fats,
  }) {
    return FirestoreService().addDiaryEntry(
      day: _day,
      type: 'food',
      name: name,
      calories: calories,
      meal: meal,
      protein: protein,
      carbs: carbs,
      fats: fats,
    );
  }

  Future<void> addExercise({required String name, required num calories,}) {
    return FirestoreService().addDiaryEntry(
      day: _day,
      type: 'exercise',
      name: name,
      calories: calories,
    );
  }

  /// clear before signOut
  void clear() {
    _sub?.cancel(); _sub = null;
    _goalSub?.cancel(); _goalSub = null;
    goal = null;
    _entries = const [];
    notifyListeners();
  }
}
