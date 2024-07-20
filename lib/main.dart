
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pizza_ordering_app/auth/signup.dart';
import 'package:pizza_ordering_app/chatpage/chatpage.dart';
import 'package:pizza_ordering_app/home/profile.dart';
import 'package:pizza_ordering_app/onboarding/onboarding.dart';
import 'package:pizza_ordering_app/photologger/foodloggerpage.dart';
import 'package:pizza_ordering_app/photologger/photologger.dart';
import 'package:pizza_ordering_app/stats/stats_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'gemini_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  initializeDateFormatting().then((_) => runApp(const MainPage()));
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: OnboardingScreen(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  // ignore: unused_field
  static const TextStyle optionStyle =
  TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static List<Widget> _widgetOptions = <Widget>[
    HomeProfile(),
    FoodLoggerPage(),
    ChatPage(),
    StatsPage(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('BottomNavigationBar Sample'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Photo AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Emma AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Directionality(
      textDirection: TextDirection.ltr,
      child: FoodLoggerPage()
    ),
    routes: {
      '/login': (context) => LoginScreen(), // Define a route to login
    },
  );
}
