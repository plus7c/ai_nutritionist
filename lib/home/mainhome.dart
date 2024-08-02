import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pizza_ordering_app/home/privacy.dart';
import 'package:pizza_ordering_app/home/profile.dart';

import '../auth/signup.dart';
import '../firebase_gemini_helper/firebase_gemini_helper.dart';

class MainHome extends StatefulWidget {
  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  HealthStatus? _healthStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHealthStatus();
  }

  Future<void> _fetchHealthStatus() async {
    try {
      final status = await GetOverallHealthStatus();
      setState(() {
        _healthStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching health status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Widget> _buildRecommendationList() {
    if (_healthStatus == null) {
      return [Text('Unable to fetch health status')];
    }

    List<String> recommendations = _healthStatus!.recommendation.split('. ');
    return recommendations.take(3).map((rec) => Text('• $rec')).toList();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      // Navigate to login page or initial page after sign out
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen())); // Replace with your login route
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Profile Options',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        leading: Icon(Icons.face_2_sharp),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hi there!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _signOut(context);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.green, backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Sign Out',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 10),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: Icon(Icons.edit, color: Colors.green),
                  title: Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  subtitle: Text('configure your height, weight, age, allergens, goals'),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.green),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomeProfile()),
                    );
                  },
                ),
              ), Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: Icon(Icons.edit, color: Colors.green),
                  title: Text('Privacy Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  subtitle: Text('You can delete your data or export it here'),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.green),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DeleteAccountPage()),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      title: Text('Overall Health Status',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      subtitle: _isLoading
                          ? CircularProgressIndicator()
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildRecommendationList(),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _isLoading ? '...' : '${_healthStatus?.score ?? 0}/100',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 15,)
                  ],
                )
              ),
              // Add more cards here for additional options
            ],
          ),
        ),
      ),
    );
  }
}