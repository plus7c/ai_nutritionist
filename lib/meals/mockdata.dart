// import 'LoggedMeal.dart';
//
// void mockdata() {
//   // Create some sample meal items
//   MealItem oatmeal = MealItem(
//     mealItemName: 'Oatmeal',
//     calories: 150,
//     carbs: 27.0,
//     fats: 3.0,
//     protein: 5.0,
//     servingSize: 40.0,
//   );
//
//   MealItem scrambledEggs = MealItem(
//     mealItemName: 'Scrambled Eggs',
//     calories: 200,
//     carbs: 2.0,
//     fats: 15.0,
//     protein: 14.0,
//     servingSize: 100.0,
//   );
//
//   MealItem chickenSalad = MealItem(
//     mealItemName: 'Chicken Salad',
//     calories: 350,
//     carbs: 15.0,
//     fats: 20.0,
//     protein: 30.0,
//     servingSize: 150.0,
//   );
//
//   MealItem apple = MealItem(
//     mealItemName: 'Apple',
//     calories: 95,
//     carbs: 25.0,
//     fats: 0.3,
//     protein: 0.5,
//     servingSize: 182.0,
//   );
//
//   // Create meal types
//   MealType breakfast = MealType(
//     mealTypeName: 'Breakfast',
//     mealItems: [oatmeal, scrambledEggs],
//   );
//
//   MealType lunch = MealType(
//     mealTypeName: 'Lunch',
//     mealItems: [chickenSalad],
//   );
//
//   MealType snack = MealType(
//     mealTypeName: 'Snack',
//     mealItems: [apple],
//   );
//
//   // Create a logged meal
//   LoggedMeal loggedMeal = LoggedMeal(
//     timeOfLogging: DateTime.now(),
//     mealTypes: [breakfast, lunch, snack],
//   );
//
//   // Print out the details of the logged meal
//   print('Logged Meal Details:');
//   print('Time of Logging: ${loggedMeal.timeOfLogging}');
//   for (var mealType in loggedMeal.mealTypes) {
//     print('\n${mealType.mealTypeName}:');
//     for (var item in mealType.mealItems) {
//       print('  - ${item.mealItemName}: ${item.calories} kcal, '
//           '${item.carbs}g carbs, ${item.fats}g fats, ${item.protein}g protein, '
//           '${item.servingSize}${item.servingUnit}');
//     }
//     print('  Total Calories: ${mealType.totalCalories}');
//     print('  Total Carbs: ${mealType.totalCarbs.toStringAsFixed(2)}g');
//     print('  Total Fats: ${mealType.totalFats.toStringAsFixed(2)}g');
//     print('  Total Protein: ${mealType.totalProtein.toStringAsFixed(2)}g');
//   }
// }
