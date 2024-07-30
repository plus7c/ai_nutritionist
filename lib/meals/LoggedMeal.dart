// LoggedMeal.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class MealItem {
  final String id;
  final String mealItemName;
  final int calories;
  final double carbs;
  final double fats;
  final double protein;
  final double servingSize;
  final String servingUnit;

  MealItem({
    required this.id,
    required this.mealItemName,
    required this.calories,
    required this.carbs,
    required this.fats,
    required this.protein,
    required this.servingSize,
    this.servingUnit = 'g',
  });

  static MealItem fromMap(Map<String, dynamic> map) {
    return MealItem(
      id: map['id'] ?? Uuid().v4(), // Use the existing ID or generate a new one
      mealItemName: map['mealItemName'] ?? '',
      calories: map['calories'] ?? 0,
      carbs: map['carbs']?.toDouble() ?? 0.0,
      fats: map['fats']?.toDouble() ?? 0.0,
      protein: map['protein']?.toDouble() ?? 0.0,
      servingSize: map['servingSize']?.toDouble() ?? 0.0,
      servingUnit: map['servingUnit'] ?? 'g',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
  String mealTypeName;
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

  static MealType fromMap(Map<String, dynamic> map) {
    var items = map['mealItems'] as List;
    List<MealItem> mealItemsList = items.map((item) => MealItem.fromMap(item)).toList();

    return MealType(
      mealTypeName: map['mealTypeName'] ?? '',
      mealItems: mealItemsList,
    );
  }
}

class LoggedMeal {
  DateTime timeOfLogging;
  List<MealType> mealTypes;

  LoggedMeal({
    required this.timeOfLogging,
    required this.mealTypes,
  });

  int get totalCaloriesLoggedMeal {
    return mealTypes.fold(0, (sum, item) => sum + item.totalCalories);
  }

  Map<String, dynamic> toMap() {
    return {
      'timeOfLogging': timeOfLogging,
      'mealTypes': mealTypes.map((type) => type.toMap()).toList(),
    };
  }

  static LoggedMeal fromMap(Map<String, dynamic> map) {
    var types = map['mealTypes'] as List;
    List<MealType> mealTypesList = types.map((type) => MealType.fromMap(type)).toList();

    return LoggedMeal(
      timeOfLogging: (map['timeOfLogging'] as Timestamp).toDate(),
      mealTypes: mealTypesList,
    );
  }
}
