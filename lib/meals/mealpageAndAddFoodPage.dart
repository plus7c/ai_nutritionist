import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'LoggedMeal.dart';

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

  @override
  Widget build(BuildContext context) {
    // Mock data for demonstration
    List<MealType> mealTypes = [
      MealType(
        mealTypeName: 'Breakfast',
        mealItems: [
          MealItem(
            mealItemName: 'Oatmeal',
            calories: 150,
            carbs: 27.0,
            fats: 3.0,
            protein: 5.0,
            servingSize: 40.0,
          ),
          MealItem(
            mealItemName: 'Scrambled Eggs',
            calories: 200,
            carbs: 2.0,
            fats: 15.0,
            protein: 14.0,
            servingSize: 100.0,
          ),
        ],
      ),
      MealType(
        mealTypeName: 'Lunch',
        mealItems: [
          MealItem(
            mealItemName: 'Chicken Salad',
            calories: 350,
            carbs: 15.0,
            fats: 20.0,
            protein: 30.0,
            servingSize: 150.0,
          ),
        ],
      ),
      MealType(
        mealTypeName: 'Snack',
        mealItems: [
          MealItem(
            mealItemName: 'Applez',
            calories: 95,
            carbs: 25.0,
            fats: 0.3,
            protein: 0.5,
            servingSize: 182.0,
          ),
        ],
      ),
    ];

    LoggedMeal loggedMeal = LoggedMeal(
      timeOfLogging: _selectedDate,
      mealTypes: mealTypes,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Calories Remaining'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.check_circle_outline, color: Colors.white),
            onPressed: () {
              _storeLoggedMeal(loggedMeal);
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
            ...mealTypes.map((mealType) => _buildMealSection(context, mealType)),
          ],
        ),
      ),
    );
  }

  Future<void> _storeLoggedMeal(LoggedMeal loggedMeal) async {
    String userId = _auth.currentUser!.uid;
    DateTime logDate = DateTime(loggedMeal.timeOfLogging.year, loggedMeal.timeOfLogging.month, loggedMeal.timeOfLogging.day);

    // Reference to the user's logged meals collection
    CollectionReference loggedMealsRef = _firestore.collection('users').doc(userId).collection('loggedmeals');

    // Query for an existing log entry for the specific date
    QuerySnapshot existingLogs = await loggedMealsRef
        .where('timeOfLogging', isEqualTo: Timestamp.fromDate(logDate))
        .get();

    if (existingLogs.docs.isNotEmpty) {
      // If an entry for the same date exists, update it
      String docId = existingLogs.docs.first.id;
      await loggedMealsRef.doc(docId).update(loggedMeal.toMap());
    } else {
      // If no entry exists for the same date, create a new one
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
          Text(
            '2,640 - 621 + 0 = 2,019',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text('Goal     Food   Exercise     Remaining',
              style: TextStyle(color: Colors.white)),
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
            trailing: Text('${mealType.totalCalories} Cal',
                style: TextStyle(color: Colors.blue)),
          ),
          ...mealType.mealItems.map((food) => ListTile(
            title: Text(food.mealItemName),
            trailing: Text('${food.calories} Cal',
                style: TextStyle(color: Colors.grey)),
          )),
          ListTile(
            leading: Icon(Icons.add, color: Colors.blue),
            title: Text('ADD FOOD', style: TextStyle(color: Colors.blue)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddFoodPage(mealType: mealType.mealTypeName)),
            ),
          ),
        ],
      ),
    );
  }
}

class AddFoodPage extends StatelessWidget {
  final String mealType;

  AddFoodPage({required this.mealType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mealType, style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.white),
            onPressed: () {},
          ),
        ],
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Search for a food',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionButton(
                    context, Icons.qr_code_scanner, 'Scan a Barcode'),
                _buildQuickActionButton(
                    context, Icons.add_circle_outline, 'Quick Add'),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildFoodItem('Chicken Breast', '165 Cal, 100g, Cooked'),
                  _buildFoodItem('Test', '196 Cal, 1 serving'),
                  _buildFoodItem('Butter, salted', '32 Cal, 1 tsp'),
                  _buildFoodItem('Apple, slice', '15 Cal, 1 slice'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: 32, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => QuickAddPage(mealType: mealType)),
              );
            },
          ),
        ),
        SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildFoodItem(String food, String details) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(food, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(details, style: TextStyle(color: Colors.grey)),
        trailing: Icon(Icons.add, color: Colors.blue),
        onTap: () {
          // Handle food item selection
        },
      ),
    );
  }
}

class QuickAddPage extends StatefulWidget {
  final String mealType;

  QuickAddPage({required this.mealType});

  @override
  _QuickAddPageState createState() => _QuickAddPageState();
}

class _QuickAddPageState extends State<QuickAddPage> {
  final TextEditingController _caloriesController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quick Add', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.white),
            onPressed: _addFood,
          ),
        ],
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.restaurant, color: Colors.blue),
              title: Text('Meal', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(widget.mealType),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _caloriesController,
              decoration: InputDecoration(
                labelText: 'Calories',
                hintText: 'Enter calorie amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Divider(),
            _buildPremiumFeature('Total Fat (g)'),
            _buildPremiumFeature('Total Carbohydrates (g)'),
            _buildPremiumFeature('Protein (g)'),
            _buildPremiumFeature('Time'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Handle Go Premium
              },
              child: Text('Go Premium'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(String label) {
    return ListTile(
      title: Text(label),
      trailing: Icon(Icons.lock, color: Colors.yellow),
    );
  }

  Future<void> _addFood() async {
    String userId = _auth.currentUser!.uid;
    String calories = _caloriesController.text;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('loggedmeals')
        .add({
      'mealType': widget.mealType,
      'calories': int.parse(calories),
      'timestamp': Timestamp.now(),
    });

    Navigator.pop(context);
  }
}
