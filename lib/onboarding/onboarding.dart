import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:pizza_ordering_app/auth/signinconfirmation.dart';
import 'package:pizza_ordering_app/auth/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: IntroductionScreen(
        pages: [
          PageViewModel(
            title: "Welcome to Your Personal AI Nutritionist",
            body: "Get personalized meal plans and recipes based on your dietary preferences.",
            image: Center(child: Image.asset("assets/images/12.jpeg", height: 175.0)),
          ),
          PageViewModel(
            title: "Track Your Nutrition",
            body: "Log your food easily with barcode scanning and photo recognition.",
            image: Center(child: Image.asset("assets/images/14.jpeg", height: 175.0)),
          ),
          PageViewModel(
            title: "Get Expert Advice",
            body: "Ask questions and receive tips to improve your eating habits.",
            image: Center(child: Image.asset("assets/images/13.jpeg", height: 175.0)),
          ),
        ],
        onDone: () {
          User? user = FirebaseAuth.instance.currentUser;

          if (user != null) {
            // User is signed in
            print("User is signed in. User ID: ${user.uid}");
            // When done button is press
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => SignInConfirmationPage()),
            );
          } else {
            // No user is signed in
            // When done button is press
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
            print("No user is currently signed in.");
          }

        },
        onSkip: () {
          // You can also override onSkip callback
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => LoginScreen()),
          );
        },
        showSkipButton: true,
        skip: const Text("Skip"),
        next: const Icon(Icons.arrow_forward),
        done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
        dotsDecorator: DotsDecorator(
          size: const Size.square(10.0),
          activeSize: const Size(22.0, 10.0),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Screen"),
      ),
      body: Center(
        child: Text("Welcome to the app!"),
      ),
    );
  }
}
