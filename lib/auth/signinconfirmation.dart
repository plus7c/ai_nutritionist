import 'package:nutrai/auth/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../apptemplate/apptemplate.dart';
import '../firestore_helper.dart';
import '../onboarding/userstatsonboarding.dart';

class SignInConfirmationPage extends StatelessWidget {
  SignInConfirmationPage({super.key});
  final FirestoreService _firestoreService = FirestoreService();

  // Define green color scheme
  final Color primaryGreen = const Color(0xFF4CAF50);
  final Color darkGreen = const Color(0xFF388E3C);
  final Color lightGreen = const Color(0xFFA5D6A7);

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      // Navigate to login page or initial page after sign out
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen())); // Replace with your login route
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Sign In Confirmation', style: TextStyle(color: Colors.white)),
        leading: const Icon(Icons.login_sharp, color: Colors.white),
        backgroundColor: darkGreen,
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryGreen)));
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: darkGreen),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Name: ${user.displayName ?? 'N/A'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Email: ${user.email ?? 'N/A'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black87),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Do you want to continue with this account?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          var userData = await _firestoreService.getUserData(user.uid);
                          if (userData != null) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AppTemplate()));
                          } else {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserStatsOnboarding()));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Continue', style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: () => _signOut(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Sign Out', style: TextStyle(color: Colors.white)),
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
                  const Text('No user is currently signed in.',
                      style: TextStyle(fontSize: 20, color: Colors.black87)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.all(20.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Go to Login', style: TextStyle(fontSize: 20, color: Colors.white))
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