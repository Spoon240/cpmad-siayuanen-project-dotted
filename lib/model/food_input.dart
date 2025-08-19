class FoodInput {
  final String name;
  final num protein;
  final num carbs;
  final num fats;
  final num calories;
  final bool autoCalc;

  FoodInput({
    required this.name,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.calories,
    required this.autoCalc,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'calories': calories,
      'calc_source': autoCalc ? 'auto' : 'manual',
      'type': 'food',
    };
  }
}
