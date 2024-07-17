// LoggedMeal.dart
class MealItem {
  String mealItemName;
  int calories;
  double carbs;
  double fats;
  double protein;
  double servingSize;
  String servingUnit;

  MealItem({
    required this.mealItemName,
    required this.calories,
    required this.carbs,
    required this.fats,
    required this.protein,
    required this.servingSize,
    this.servingUnit = 'g',
  });

  Map<String, dynamic> toMap() {
    return {
      'mealItemName': mealItemName,
      'calories': calories,
      'carbs': carbs,
      'fats': fats,
      'protein': protein,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
    };
  }
}

class MealType {
  String mealTypeName; // could be breakfast, lunch, dinner, or snack
  List<MealItem> mealItems;
  int totalCalories;
  double totalCarbs;
  double totalProtein;
  double totalFats;

  MealType({
    required this.mealTypeName,
    required this.mealItems,
  })  : totalCalories = mealItems.fold(0, (sum, item) => sum + item.calories),
        totalCarbs = mealItems.fold(0, (sum, item) => sum + item.carbs),
        totalProtein = mealItems.fold(0, (sum, item) => sum + item.protein),
        totalFats = mealItems.fold(0, (sum, item) => sum + item.fats);

  Map<String, dynamic> toMap() {
    return {
      'mealTypeName': mealTypeName,
      'mealItems': mealItems.map((item) => item.toMap()).toList(),
      'totalCalories': totalCalories,
      'totalCarbs': totalCarbs,
      'totalProtein': totalProtein,
      'totalFats': totalFats,
    };
  }
}

class LoggedMeal {
  DateTime timeOfLogging;
  List<MealType> mealTypes;

  LoggedMeal({
    required this.timeOfLogging,
    required this.mealTypes,
  });

  Map<String, dynamic> toMap() {
    return {
      'timeOfLogging': timeOfLogging,
      'mealTypes': mealTypes.map((type) => type.toMap()).toList(),
    };
  }
}
