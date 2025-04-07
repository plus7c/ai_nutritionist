import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../auth/signup.dart';
import '../firebase_gemini_helper/firebase_gemini_helper.dart';
import 'privacy.dart';
import 'profile.dart';
import 'language_settings.dart';

class MainHome extends StatefulWidget {
  const MainHome({super.key});

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
      final status = await getOverallHealthStatus();
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
      return [const Text('Unable to fetch health status')];
    }

    List<String> recommendations = _healthStatus!.recommendation.split('. ');
    return recommendations.take(3).map((rec) => Text('• $rec')).toList();
  }

  Future<void> _showSignOutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmSignOutTitle),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppLocalizations.of(context)!.signOutConfirmationText),
                Text(AppLocalizations.of(context)!.signOutConfirmationSubtext),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.cancelButtonText,
                style: const TextStyle(color: Colors.grey)
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.signOutButtonText,
                style: const TextStyle(color: Colors.green)
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                _signOut(context); // Call the sign out function
              },
            ),
          ],
        );
      },
    );
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
        const SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.profileOptionsTitle,
          style: const TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        leading: const Icon(Icons.face_2_sharp),
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
                    AppLocalizations.of(context)!.greetingText,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _showSignOutConfirmationDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.green,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.signOutButtonText,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: const Icon(Icons.edit, color: Colors.green),
                  title: Text(
                    AppLocalizations.of(context)!.editProfileTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.editProfileSubtitle
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.green),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomeProfile()),
                    );
                  },
                ),
              ),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: const Icon(Icons.edit, color: Colors.green),
                  title: Text(
                    AppLocalizations.of(context)!.privacyPolicyTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.privacyPolicySubtitle
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.green),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DeleteAccountPage()),
                    );
                  },
                ),
              ),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: const Icon(Icons.language, color: Colors.green),
                  title: Text(
                    AppLocalizations.of(context)!.languageOptionText,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.selectLanguageText
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.green),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LanguageSettingsPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        title: const Text('Overall Health Status',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                        subtitle: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Colors.green,))
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildRecommendationList(),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _isLoading ? '...' : '${_healthStatus?.score ?? 0}/100',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15,)
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