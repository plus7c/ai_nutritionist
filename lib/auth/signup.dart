import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pizza_ordering_app/onboarding/userstatsonboarding.dart';



class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<User?> _signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child:
            ElevatedButton(
              onPressed: () async {
                User? user = await _signInWithGoogle();
                if (user != null) {
                  print(user);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => UserStatsOnboarding()),
                  );
                }
              },
              child: Text('Sign in with Google'),
            ),
            // TextField(
            //   decoration: InputDecoration(labelText: 'Email'),
            //   keyboardType: TextInputType.emailAddress,
            //   onChanged: (value) {
            //     // Save email input
            //   },
            // ),
            // TextField(
            //   decoration: InputDecoration(labelText: 'Password'),
            //   obscureText: true,
            //   onChanged: (value) {
            //     // Save password input
            //   },
            // ),
            // ElevatedButton(
            //   onPressed: () async {
            //     // Call _signInWithEmail with the saved email and password
            //
            //     User? user = await _signInWithEmail('email', 'password');
            //     if (user != null) {
            //       //check whether user is new or existing
            //       var storeduserId = _firestoreService.getUserData(user.uid);
            //       if (storeduserId == null)
            //       {
            //         Navigator.pushReplacement(
            //           context,
            //           MaterialPageRoute(builder: (context) => UserStatsOnboarding()),
            //         );
            //       }
            //       Navigator.pushReplacement(
            //         context,
            //         MaterialPageRoute(builder: (context) => ChatPage()),
            //       );
            //     }
            //   },
            //   child: Text('Sign in with Email'),
            // ),

        ),
      ),
    );
  }
}
