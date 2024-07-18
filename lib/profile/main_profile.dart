import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Daily Stats', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DailyStats(),
              SizedBox(height: 16),
              FavoriteSection(),
              SizedBox(height: 16),
              WeightStatistics(),
              SizedBox(height: 16),
              NutrientsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class DailyStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatItem(
                  label: 'Daily calories',
                  value: '2181',
                ),
                CircularProgressIndicator(
                  value: 0.75,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                StatItem(
                  label: 'Eaten',
                  value: '890',
                ),
              ],
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                '1645 Kcal available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String label;
  final String value;

  const StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class FavoriteSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FavoriteCard(
            title: 'Favourite Product',
            items: ['Avocado 6 times', 'Apple 6 times', 'Fish 5 times', 'Eggs 7 times'],
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: FavoriteCard(
            title: 'Favourite Brand',
            items: ['Danone SA', 'Mondelez', 'Unilever', 'Nestle'],
          ),
        ),
      ],
    );
  }
}

class FavoriteCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const FavoriteCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(item, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            )).toList(),
          ],
        ),
      ),
    );
  }
}

class WeightStatistics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Weight Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            SizedBox(height: 12),
            // Replace with your weight statistics graph
            Placeholder(fallbackHeight: 100),
          ],
        ),
      ),
    );
  }
}

class NutrientsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Protein, Fats, Carbohydrates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            SizedBox(height: 12),
            // Replace with your nutrients information
            Placeholder(fallbackHeight: 100),
            SizedBox(height: 16),
            Text(
              "You don't eat enough foods rich in vitamin E",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: VitaminEItem(name: 'Almond', percentage: '88% DV')),
                Expanded(child: VitaminEItem(name: 'Peanuts', percentage: '33% DV')),
                Expanded(child: VitaminEItem(name: 'Avocado', percentage: '14% DV')),
              ],
            ),
            SizedBox(height: 12),
            Center(child: ElevatedButton(onPressed: () {}, child: Text('See More'))),
          ],
        ),
      ),
    );
  }
}

class VitaminEItem extends StatelessWidget {
  final String name;
  final String percentage;

  const VitaminEItem({required this.name, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Replace with image of the food item
        Placeholder(fallbackHeight: 50, fallbackWidth: 50),
        SizedBox(height: 4),
        Text(name, style: TextStyle(fontSize: 14)),
        Text(
          percentage,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ProfilePage(),
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
  ));
}
