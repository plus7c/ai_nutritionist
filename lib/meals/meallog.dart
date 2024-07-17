import 'package:flutter/material.dart';

class MealPage extends StatefulWidget {
  @override
  _MealPageState createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  int selectedIndex = 3; // Index of the selected date

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meals'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border),
            onPressed: () {
              // Handle favorite button press
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSelector(),
              SizedBox(height: 16),
              Text(
                'Suggested by AI',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildMealCard('Breakfast', 'Tomato & Cream Cheese Omelette, Honey Roasted P...'),
              _buildMealCard('Lunch', 'Grilled chicken or tofu salad with mixed greens, cherry...'),
              _buildMealCard('Snack', 'Cottage cheese with pineapple chunks'),
              _buildMealCard('Dinner', 'Baked salmon or roasted tempeh with a lemon-herb s...'),
              SizedBox(height: 24),
              Text(
                'Tracked meals',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // Add more tracked meal cards here
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    List<String> dates = ['14', '15', '16', '17', '18', '19', '20'];
    List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(dates.length, (index) {
        return _buildDateItem(dates[index], days[index], index);
      }),
    );
  }

  Widget _buildDateItem(String date, String day, int index) {
    bool isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Column(
        children: [
          Text(
            date,
            style: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green[100] : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              day,
              style: TextStyle(color: isSelected ? Colors.green[800] : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(String title, String description) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Handle meal card tap
        },
      ),
    );
  }
}
