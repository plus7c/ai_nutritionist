import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../onboarding/userstatsonboarding.dart';

class DeleteAccountPage extends StatefulWidget {
  @override
  _DeleteAccountPageState createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _termsAccepted = false;

  Future<void> _deleteUserData() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please accept the terms before deleting your account.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Attempt to reauthenticate
        bool reauthenticated = await _reauthenticateUser();
        if (!reauthenticated) {
          throw Exception('Failed to reauthenticate. Please log in again.');
        }

        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete user authentication account
        await user.delete();

        // Sign out the user
        await _auth.signOut();
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserStatsOnboarding()),
        );// Redirect to login page
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Account'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete Account and Data',
              style: Theme.of(context).textTheme.headline5,
            ),
            SizedBox(height: 16),
            Text(
              'Warning: This action is irreversible. All your data will be permanently deleted.',
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 24),
            Text(
              'Terms and Conditions:',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8),
            Text(
              '1. By deleting your account, you acknowledge that all your personal data, including but not limited to profile information, meal logs, and progress data, will be permanently removed from our servers.\n\n'
                  '2. We may retain certain information as required by law or for legitimate business purposes.\n\n'
                  '3. You will lose access to all features and services associated with your account.\n\n'
                  '4. Any active subscriptions will be cancelled, and you may not be eligible for refunds on any paid services.\n\n'
                  '5. If you choose to use our services again in the future, you will need to create a new account.',
            ),
            SizedBox(height: 24),
            CheckboxListTile(
              title: Text('I have read and accept the terms and conditions'),
              value: _termsAccepted,
              onChanged: (bool? value) {
                setState(() {
                  _termsAccepted = value ?? false;
                });
              },
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (await _showDeleteConfirmationDialog()) {
                    await _deleteUserData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text('Delete My Account'),
              ),
            ),
          ],
        ),
      ),
    );

  }
  Future<bool> _reauthenticateUser() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in flow
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Reauthenticate
      await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print('Error during Google reauthentication: $e');
      return false;
    }
  }
  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Account Deletion'),
          content: Text('You will need to re-authenticate with Google to delete your account. Are you sure you want to proceed?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Yes, Delete My Account'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }
}


