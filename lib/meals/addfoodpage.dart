import 'package:flutter/material.dart';
import 'quickaddpage.dart';

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

