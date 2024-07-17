import 'package:flutter/material.dart';
import 'package:pizza_ordering_app/gemini_utils.dart';
import 'package:pizza_ordering_app/meals/meallog.dart';
import 'package:pizza_ordering_app/meals/mealpageAndAddFoodPage.dart';

import '../chatpage/chatpage.dart';
import '../home/profile.dart';
import '../photologger/photologger.dart';
import '../profile/main_profile.dart';

class AppTemplate extends StatefulWidget {
  @override
  _AppTemplateState createState() => _AppTemplateState();
}

class _AppTemplateState extends State<AppTemplate> {
  int _selectedIndex = 0;
  static List<Widget> _widgetOptions = <Widget>[
    HomeProfile(),
    ChatPage(),
    FoodLogWidget(model: getGeminiInstance()),
    ProfilePage(),
    MealPage2(), // Placeholder for the new profile page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _selectedIndex = 2; // Index of Photo AI
          });
        },
        child: Icon(Icons.camera_alt, color: Colors.white),
        backgroundColor: Colors.amber[800],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
        child: Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home,
                          color: _selectedIndex == 0 ? Colors.amber[800] : Colors.grey,
                        ),
                        Text('Home', style: TextStyle(color: _selectedIndex == 0 ? Colors.amber[800] : Colors.grey))
                      ],
                    ),
                  ),
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat,
                          color: _selectedIndex == 1 ? Colors.amber[800] : Colors.grey,
                        ),
                        Text('Emma AI', style: TextStyle(color: _selectedIndex == 1 ? Colors.amber[800] : Colors.grey))
                      ],
                    ),
                  )
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          color: _selectedIndex == 3 ? Colors.amber[800] : Colors.grey,
                        ),
                        Text('Stats', style: TextStyle(color: _selectedIndex == 3 ? Colors.amber[800] : Colors.grey))
                      ],
                    ),
                  ),
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 4;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.set_meal,
                          color: _selectedIndex == 4 ? Colors.amber[800] : Colors.grey,
                        ),
                        Text('Meals', style: TextStyle(color: _selectedIndex == 4 ? Colors.amber[800] : Colors.grey))
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}