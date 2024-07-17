import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'LoggedMeal.dart';

class AddMealLogPage extends StatefulWidget {
  @override
  _AddMealLogPageState createState() => _AddMealLogPageState();
}

class _AddMealLogPageState extends State<AddMealLogPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _selectedDate = DateTime.now();
  String _mealTypeName = '';
  final List<MealItem> _mealItems = [];

  final TextEditingController _mealItemNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _servingSizeController = TextEditingController();

  void _addMealItem() {
    if (_mealItemNameController.text.isNotEmpty &&
        _caloriesController.text.isNotEmpty &&
        _carbsController.text.isNotEmpty &&
        _fatsController.text.isNotEmpty &&
        _proteinController.text.isNotEmpty &&
        _servingSizeController.text.isNotEmpty) {
      setState(() {
        _mealItems.add(MealItem(
          mealItemName: _mealItemNameController.text,
          calories: int.parse(_caloriesController.text),
          carbs: double.parse(_carbsController.text),
          fats: double.parse(_fatsController.text),
          protein: double.parse(_proteinController.text),
          servingSize: double.parse(_servingSizeController.text),
        ));
        _mealItemNameController.clear();
        _caloriesController.clear();
        _carbsController.clear();
        _fatsController.clear();
        _proteinController.clear();
        _servingSizeController.clear();
      });
    }
  }

  Future<void> _storeMealLog() async {
    if (_mealItems.isEmpty || _mealTypeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one meal item and specify a meal type.')),
      );
      return;
    }

    String userId = _auth.currentUser!.uid;
    MealType newMealType = MealType(mealTypeName: _mealTypeName, mealItems: _mealItems);

    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
    DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    CollectionReference loggedMealsRef = _firestore.collection('users').doc(userId).collection('loggedmeals');

    QuerySnapshot existingLogs = await loggedMealsRef
        .where('timeOfLogging', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timeOfLogging', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    if (existingLogs.docs.isNotEmpty) {
      String docId = existingLogs.docs.first.id;
      Map<String, dynamic> existingLogData = existingLogs.docs.first.data() as Map<String, dynamic>;
      LoggedMeal existingLoggedMeal = LoggedMeal.fromMap(existingLogData);

      // Check if meal type already exists and add new items to it
      int mealTypeIndex = existingLoggedMeal.mealTypes.indexWhere((mealType) => mealType.mealTypeName == newMealType.mealTypeName);
      if (mealTypeIndex != -1) {
        existingLoggedMeal.mealTypes[mealTypeIndex].mealItems.addAll(newMealType.mealItems);
      } else {
        existingLoggedMeal.mealTypes.add(newMealType);
      }

      await loggedMealsRef.doc(docId).update(existingLoggedMeal.toMap());
    } else {
      LoggedMeal newLoggedMeal = LoggedMeal(timeOfLogging: _selectedDate, mealTypes: [newMealType]);
      await loggedMealsRef.add(newLoggedMeal.toMap());
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Meal log added successfully!')),
    );

    setState(() {
      _mealTypeName = '';
      _mealItems.clear();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Meal Log'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                InkWell(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2010),
                      lastDate: DateTime(2050),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Log Date',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.calendar_today, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d, yyyy').format(_selectedDate),
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Meal Type (e.g., Breakfast, Lunch, Snack, Dinner)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _mealTypeName = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _mealItemNameController,
                  decoration: InputDecoration(
                    labelText: 'Meal Item Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _caloriesController,
                  decoration: InputDecoration(
                    labelText: 'Calories',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _carbsController,
                  decoration: InputDecoration(
                    labelText: 'Carbs (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _fatsController,
                  decoration: InputDecoration(
                    labelText: 'Fats (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _proteinController,
                  decoration: InputDecoration(
                    labelText: 'Protein (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _servingSizeController,
                  decoration: InputDecoration(
                    labelText: 'Serving Size (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addMealItem,
                  child: Text('Add Meal Item'),
                ),
                SizedBox(height: 16),
                if (_mealItems.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meal Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._mealItems.map((item) => ListTile(
                        title: Text(item.mealItemName),
                        subtitle: Text(
                            'Calories: ${item.calories}, Carbs: ${item.carbs}g, Fats: ${item.fats}g, Protein: ${item.protein}g, Serving Size: ${item.servingSize}g'),
                      )),
                    ],
                  ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _storeMealLog,
                  child: Text('Save Meal Log'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
