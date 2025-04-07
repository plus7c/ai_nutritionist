import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../gemini_utils.dart';
import '../stats/dateselect.dart';
import 'LoggedMeal.dart';
import 'addmeallogpagewidget.dart';

class MealPage2 extends StatefulWidget {
  const MealPage2({super.key});

  @override
  State<MealPage2> createState() => _MealPage2State();
}

class _MealPage2State extends State<MealPage2> {
  DateTime _selectedDate = DateTime.now();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late LoggedMeal currentMeal;

  @override
  void initState() {
    super.initState();
    _updateCurrentMeal();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2050),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
    await _updateCurrentMeal();
  }

  Future<void> _updateCurrentMeal() async {
    final meal = await _fetchLoggedMeal();
    if (meal != null) {
      setState(() {
        currentMeal = meal;
      });
    }
  }

  Future<LoggedMeal?> _fetchLoggedMeal() async {
    String userId = _auth.currentUser!.uid;

    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
    DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('loggedmeals')
        .where('timeOfLogging', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timeOfLogging', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      Map<String, dynamic> data = querySnapshot.docs.first.data() as Map<String, dynamic>;
      LoggedMeal fetchedData = LoggedMeal.fromMap(data);
      return fetchedData;
    } else {
      return null;
    }
  }

  Future<bool> _deleteMealItem(MealType mealType, MealItem mealItem) async {
    String userId = _auth.currentUser!.uid;
    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loggedmeals')
          .where('timeOfLogging', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timeOfLogging', isLessThanOrEqualTo: Timestamp.fromDate(startOfDay.add(const Duration(days: 1))))
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentReference docRef = querySnapshot.docs.first.reference;

        // Update the meal type
        int mealTypeIndex = currentMeal.mealTypes.indexWhere((mt) => mt.mealTypeName == mealType.mealTypeName);
        if (mealTypeIndex != -1) {
          currentMeal.mealTypes[mealTypeIndex].mealItems.removeWhere((item) => item.id == mealItem.id);
          currentMeal.mealTypes[mealTypeIndex].totalCalories -= mealItem.calories;
        }

        // Update Firestore
        await docRef.update(currentMeal.toMap());

        // Update local state
        setState(() {
          // The currentMeal has already been updated above
        });

        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting meal item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToDeleteMealItem)),
      );
      return false;
    }
  }
  Future<bool> _showDeleteConfirmationDialog(MealType mealType, MealItem mealItem) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteMealItemTitle),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppLocalizations.of(context)!.deleteMealItemConfirmation),
                Text(mealItem.mealItemName, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancelButton),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.deleteButton),
              onPressed: () {
                Navigator.of(context).pop(true);
                _deleteMealItem(mealType, mealItem);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.caloriesRemainingPageTitle,
          style: const TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        leading: const Icon(Icons.heat_pump_sharp),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildDateTimePicker(context),
            _buildCaloriesRemaining(),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.add, color: Colors.green),
                title: Text(AppLocalizations.of(context)!.logFoodButton, style: const TextStyle(color: Colors.green)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMealLogPage(
                      model: getGeminiInstance(),
                      addMealToLog: addMealToLog,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_outlined, color: Colors.red), 
              title: Text(
                AppLocalizations.of(context)!.deleteEntrySwipeHint, 
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            FutureBuilder<LoggedMeal?>(
              future: _fetchLoggedMeal(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasData) {
                  LoggedMeal loggedMeal = snapshot.data!;
                  return Column(
                    children: currentMeal.mealTypes
                        .map((mealType) => _buildMealSection(context, mealType))
                        .toList(),
                  );
                } else {
                  return _buildNoMealsLogged(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMealsLogged(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.noMealsLoggedMessage,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void addMealToLog(LoggedMeal meal){
    setState(() {
      currentMeal = meal;
    });
  }

  Widget _buildDateTimePicker(BuildContext context) {
    return DateSelectButton(
      selectedDate: _selectedDate,
      onPressed: () => _selectDate(context),
    );
  }

  Widget _buildCaloriesRemaining() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<LoggedMeal?>(
                future: _fetchLoggedMeal(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasData) {
                    LoggedMeal loggedMeal = snapshot.data!;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            child: Text(
                              AppLocalizations.of(context)!.totalCaloriesText(loggedMeal.totalCaloriesLoggedMeal.toString()), 
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                            )
                        ),
                      ],
                    );
                  } else {
                    return Text(
                      AppLocalizations.of(context)!.totalCaloriesText("0"), 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMealSection(BuildContext context, MealType mealType) {
    if (mealType.mealItems.isEmpty) {
      return const SizedBox.shrink(); // Return an empty widget if there are no meal items
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.restaurant, color: Colors.blue),
            title: Text(mealType.mealTypeName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              AppLocalizations.of(context)!.caloriesUnitText(mealType.totalCalories),
              style: const TextStyle(color: Colors.blue)
            ),
          ),
          ...mealType.mealItems.map((food) => Dismissible(
            key: Key(food.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              bool shouldDelete = await _showDeleteConfirmationDialog(mealType, food);
              if (shouldDelete) {
                bool deleted = await _deleteMealItem(mealType, food);
                return deleted;
              }
              return false;
            },
            child: ListTile(
              title: Text(food.mealItemName),
              trailing: Text(
                AppLocalizations.of(context)!.caloriesUnitText(food.calories),
                style: const TextStyle(color: Colors.grey)
              ),
            ),
          )),
        ],
      ),
    );
  }
}