import 'package:NutrAI/auth/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


import '../apptemplate/apptemplate.dart';
import '../firestore_helper.dart';
import '../onboarding/userstatsonboarding.dart';

class SignInConfirmationPage extends StatelessWidget {
  SignInConfirmationPage({Key? key}) : super(key: key);
  final FirestoreService _firestoreService = FirestoreService();
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

  void checkIfUserStatsArePopulated(){

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Sign In Confirmation'),
        leading: Icon(Icons.login_sharp),
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data != null) {
            User user = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Name: ${user.displayName ?? 'N/A'}',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Email: ${user.email ?? 'N/A'}',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Do you want to continue with this account?',
                    style: Theme.of(context).textTheme.subtitle1,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          // Navigate to the main app or next page
                          var userData = await _firestoreService.getUserData(user.uid);
                          if (userData != null) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AppTemplate()));
                          } else {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UserStatsOnboarding()));
                          }
                        },
                        child: Text('Continue'),
                      ),
                      ElevatedButton(
                        onPressed: () => _signOut(context),
                        child: Text('Sign Out'),
                        // style: ElevatedButton.styleFrom(
                        //   backgroundColor: Colors.red,
                        // ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No user is currently signed in.', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to login page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text('Go to Login', style: TextStyle(fontSize: 20)),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.all(20.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Slightly rounded corners
                      ),
                    )
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}