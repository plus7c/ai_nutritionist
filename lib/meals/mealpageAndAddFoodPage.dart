import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'LoggedMeal.dart';
import 'addfoodpage.dart';
import 'addmeallogpagewidget.dart';
import 'quickaddpage.dart';

class MealPage2 extends StatefulWidget {
  @override
  State<MealPage2> createState() => _MealPage2State();
}

class _MealPage2State extends State<MealPage2> {
  DateTime _selectedDate = DateTime.now();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      return LoggedMeal.fromMap(data);
    } else {
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calories Remaining'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on,  color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.check_circle_outline, color: Colors.white),
            onPressed: () {
              // Save logic will be implemented here
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildDateTimePicker(context),
            _buildCaloriesRemaining(),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Icon(Icons.add, color: Colors.blue),
                title: Text('LOG FOOD', style: TextStyle(color: Colors.blue)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddMealLogPage()),
                ),
              ),
            ),
            FutureBuilder<LoggedMeal?>(
              future: _fetchLoggedMeal(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasData) {
                  LoggedMeal loggedMeal = snapshot.data!;
                  return Column(
                    children: loggedMeal.mealTypes
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
            'No meals logged for this date.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: Icon(Icons.add, color: Colors.blue),
              title: Text('ADD FOOD', style: TextStyle(color: Colors.blue)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddMealLogPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _storeLoggedMeal(LoggedMeal loggedMeal) async {
    String userId = _auth.currentUser!.uid;
    DateTime logDate = DateTime(loggedMeal.timeOfLogging.year, loggedMeal.timeOfLogging.month, loggedMeal.timeOfLogging.day);

    CollectionReference loggedMealsRef = _firestore.collection('users').doc(userId).collection('loggedmeals');

    QuerySnapshot existingLogs = await loggedMealsRef
        .where('timeOfLogging', isEqualTo: Timestamp.fromDate(logDate))
        .get();

    if (existingLogs.docs.isNotEmpty) {
      String docId = existingLogs.docs.first.id;
      await loggedMealsRef.doc(docId).update(loggedMeal.toMap());
    } else {
      await loggedMealsRef.add(loggedMeal.toMap());
    }
  }

  Widget _buildDateTimePicker(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Center(
        child: InkWell(
          onTap: () => _selectDate(context),
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
                SizedBox(width: 5),
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
      ),
    );
  }

  Widget _buildCaloriesRemaining() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<LoggedMeal?>(
                future: _fetchLoggedMeal(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData) {
                    LoggedMeal loggedMeal = snapshot.data!;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            child: Text('Total Calories: ${loggedMeal.totalCaloriesLoggedMeal} kCal', style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),)
                        ),
                      ],
                    );
                  } else {
                    return Text('0');
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMealSection(BuildContext context, MealType mealType) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(Icons.restaurant, color: Colors.blue),
            title: Text(mealType.mealTypeName,
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text('${mealType.totalCalories} kCal',
                style: TextStyle(color: Colors.blue)),
          ),
          ...mealType.mealItems.map((food) => ListTile(
            title: Text(food.mealItemName),
            trailing: Text('${food.calories} Cal',
                style: TextStyle(color: Colors.grey)),
          )),
          // ListTile(
          //   leading: Icon(Icons.add, color: Colors.blue),
          //   title: Text('ADD FOOD', style: TextStyle(color: Colors.blue)),
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (context) => AddMealLogPage()),
          //   )
          //   //     Navigator.push(
          //   //   context,
          //   //   MaterialPageRoute(
          //   //       builder: (context) => AddFoodPage(mealType: mealType.mealTypeName)),
          //   // ),
          // ),
        ],
      ),
    );
  }
}
