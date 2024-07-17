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
}

class LoggedMeal {
  DateTime timeOfLogging;
  List<MealType> mealTypes;

  LoggedMeal({
    required this.timeOfLogging,
    required this.mealTypes,
  });
}
