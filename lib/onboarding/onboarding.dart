import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/signinconfirmation.dart';
import '../auth/signup.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define green color scheme
    final primaryGreen = const Color(0xFF4CAF50);
    final darkGreen = const Color(0xFF388E3C);
    final lightGreen = const Color(0xFFA5D6A7);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: IntroductionScreen(
        pages: [
          PageViewModel(
            title: "Welcome to nutrai",
            body: "nutrai is a cutting-edge mobile app that leverages advanced AI technology to offer personalized nutrition recommendations, meal planning, and food analysis",
            image: Center(child: Image.asset("assets/images/12.jpeg", height: 175.0)),
            decoration: PageDecoration(
              titleTextStyle: TextStyle(color: darkGreen, fontSize: 24, fontWeight: FontWeight.bold),
              bodyTextStyle: const TextStyle(color: Colors.black87, fontSize: 16),
              imagePadding: const EdgeInsets.only(top: 40),
            ),
          ),
          PageViewModel(
            title: "Track Your Nutrition",
            body: "Log your food easily with photo recognition.",
            image: Center(child: Image.asset("assets/images/14.jpeg", height: 175.0)),
            decoration: PageDecoration(
              titleTextStyle: TextStyle(color: darkGreen, fontSize: 24, fontWeight: FontWeight.bold),
              bodyTextStyle: const TextStyle(color: Colors.black87, fontSize: 16),
              imagePadding: const EdgeInsets.only(top: 40),
            ),
          ),
          PageViewModel(
            title: "Get Expert Advice",
            body: "Ask questions and receive tips to improve your eating habits. The AI will understand you better since it will have access to your basic stats such as height, weight and age",
            image: Center(child: Image.asset("assets/images/13.jpeg", height: 175.0)),
            decoration: PageDecoration(
              titleTextStyle: TextStyle(color: darkGreen, fontSize: 24, fontWeight: FontWeight.bold),
              bodyTextStyle: const TextStyle(color: Colors.black87, fontSize: 16),
              imagePadding: const EdgeInsets.only(top: 40),
            ),
          ),
        ],
        onDone: () {
          User? user = FirebaseAuth.instance.currentUser;

          if (user != null) {
            print("User is signed in. User ID: ${user.uid}");
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => SignInConfirmationPage()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
            print("No user is currently signed in.");
          }
        },
        onSkip: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => SignInConfirmationPage()),
          );
        },
        showSkipButton: true,
        skip: Text("Skip", style: TextStyle(color: darkGreen)),
        next: Icon(Icons.arrow_forward, color: primaryGreen),
        done: Text("Done", style: TextStyle(fontWeight: FontWeight.w600, color: darkGreen)),
        dotsDecorator: DotsDecorator(
          size: const Size.square(10.0),
          activeSize: const Size(22.0, 10.0),
          activeColor: primaryGreen,
          color: lightGreen,
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        globalBackgroundColor: Colors.white,
        curve: Curves.fastLinearToSlowEaseIn,
        controlsMargin: const EdgeInsets.all(16),
        controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
        showNextButton: true,
        nextFlex: 0,
        dotsFlex: 2,
        // skip: 0,
        animationDuration: 1000,
        isProgressTap: true,
        isProgress: true,
        freeze: false,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Screen"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: const Center(
        child: Text("Welcome to the app!"),
      ),
    );
  }
}