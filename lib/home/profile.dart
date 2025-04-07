import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../firebase_gemini_helper/firebase_gemini_helper.dart';
import '../firestore_helper.dart';

class HomeProfile extends StatefulWidget {
  const HomeProfile({super.key});

  @override
  _HomeProfileState createState() => _HomeProfileState();
}

class _HomeProfileState extends State<HomeProfile> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userId;

  List<String> selectedGoals = [];
  String name = '';
  String gender = '';
  DateTime? dateOfBirth;
  double? weight;
  Map<String, int>? height;
  List<String> allergies = [];

  List<String> genderOptions = ['Male', 'Female', 'Other'];
  List<String> commonAllergies = [
    'Milk', 'Eggs', 'Peanuts', 'Tree nuts', 'Fish', 'Shellfish', 'Soy', 'Wheat'
  ];
  List<String> goals = [
    'Weight loss',
    'Allergies and food sensitivities',
    'Meal planning',
    'Set personal nutrition goals',
    'Better eating habits',
    'Chronic diseases',
    'Digestive issues',
    'Other'
  ];

  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _getUserIdAndLoadData();
  }

  Future<void> _getUserIdAndLoadData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
      await _loadAllUserData();
      setState(() {
        isLoading = false;
      });
    } else {
      print('No user is currently signed in');
      setState(() {
        isLoading = false;
      });
      // Handle the case when no user is signed in, e.g., navigate to login page
    }
  }

  Future<void> _loadAllUserData() async {
    if (userId == null) return;
    var userData = await _firestoreService.getUserData(userId!);
    if (userData != null) {
      setState(() {
        name = userData['username'] ?? '';
        gender = userData['gender'] ?? '';
        dateOfBirth = userData['dateOfBirth']?.toDate();
        weight = userData['weight'];
        height = userData['height'] != null
            ? Map<String, int>.from(userData['height'])
            : null;
        allergies = List<String>.from(userData['allergies'] ?? []);
        selectedGoals = List<String>.from(userData['goals'] ?? []);
      });
    }
  }

  Future<void> _updateField(String field, dynamic value) async {
    if (userId == null) return;
    await _firestoreService.updateField(userId!, field, value);
    await _loadField(field);
  }

  Future<void> _loadField(String field) async {
    if (userId == null) return;
    var fieldData = await _firestoreService.getField(userId!, field);
    setState(() {
      switch (field) {
        case 'username':
          name = fieldData ?? '';
          break;
        case 'gender':
          gender = fieldData ?? '';
          break;
        case 'dateOfBirth':
          dateOfBirth = fieldData?.toDate();
          break;
        case 'weight':
          weight = fieldData;
          break;
        case 'height':
          height = fieldData != null ? Map<String, int>.from(fieldData) : null;
          break;
        case 'allergies':
          allergies = List<String>.from(fieldData ?? []);
          break;
        case 'goals':
          selectedGoals = List<String>.from(fieldData ?? []);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.userProfileTitle),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()):
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child:
                FluttermojiCircleAvatar(
                  backgroundColor: Colors.grey[200],
                  radius: 30,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  name.isNotEmpty ? name : AppLocalizations.of(context)!.nameLabel,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),

              const SizedBox(height: 24),
              _buildInfoTile(
                AppLocalizations.of(context)!.weightLabel, 
                weight != null ? '${weight!.toStringAsFixed(1)} kg' : AppLocalizations.of(context)!.selectDateText, 
                Icons.fitness_center, 
                () => _showUpdateDialog(AppLocalizations.of(context)!.weightLabel, 'weight')
              ),
              _buildInfoTile(
                AppLocalizations.of(context)!.heightLabel, 
                _formatHeight(), 
                Icons.height, 
                () => _showUpdateDialog(AppLocalizations.of(context)!.heightLabel, 'height')
              ),
              _buildInfoTile(
                AppLocalizations.of(context)!.genderLabel, 
                gender.isNotEmpty ? _getLocalizedGender(context, gender) : AppLocalizations.of(context)!.selectDateText, 
                Icons.person, 
                _showGenderDialog
              ),
              _buildInfoTile(
                AppLocalizations.of(context)!.dateOfBirthLabel, 
                dateOfBirth != null ? DateFormat('yyyy-MM-dd').format(dateOfBirth!) : AppLocalizations.of(context)!.selectDateText, 
                Icons.cake, 
                _showDateOfBirthPicker
              ),
              _buildInfoTile(
                AppLocalizations.of(context)!.allergiesLabel, 
                allergies.isNotEmpty ? allergies.join(', ') : AppLocalizations.of(context)!.selectDateText, 
                Icons.warning, 
                _showAllergiesDialog
              ),
              const SizedBox(height: 24),
              Text(AppLocalizations.of(context)!.goalsLabel, style: Theme.of(context).textTheme.titleLarge),
              ..._buildGoalItems(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit),
      onTap: onTap,
    );
  }

  List<Widget> _buildGoalItems() {
    return goals.map((goal) => CheckboxListTile(
      title: Text(_getLocalizedGoal(context, goal)),
      value: selectedGoals.contains(goal),
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            selectedGoals.add(goal);
          } else {
            selectedGoals.remove(goal);
          }
        });
        _updateField('goals', selectedGoals);
      },
    )).toList();
  }

  String _formatHeight() {
    if (height != null && height!['feet'] != null && height!['inches'] != null) {
      return "${height!['feet']}' ${height!['inches']}\"";
    }
    return 'Not set';
  }

  void _showUpdateDialog(String title, String field) {
    String value = '';
    TextEditingController feetController = TextEditingController();
    TextEditingController inchesController = TextEditingController();

    if (field == 'height' && height != null) {
      feetController.text = height!['feet'].toString();
      inchesController.text = height!['inches'].toString();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update $title'),
        content: field == 'height'
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: feetController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.ftText,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: inchesController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.inText,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.enterHeightText,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        )
            : TextField(
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterNewText + ' $title',
            border: const OutlineInputBorder(),
          ),
          keyboardType: field == 'weight' ? TextInputType.number : TextInputType.text,
          onChanged: (val) => value = val,
        ),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancelButtonText),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text(AppLocalizations.of(context)!.saveButtonText),
            onPressed: () {
              Navigator.pop(context);
              if (field == 'height') {
                if (feetController.text.isNotEmpty && inchesController.text.isNotEmpty) {
                  int feet = int.parse(feetController.text);
                  int inches = int.parse(inchesController.text);
                  _updateField(field, {'feet': feet, 'inches': inches});
                  //doing this to trigger an update on the recommendation for the BMI since its affected by height
                  getBMIRecommendation(triggeredFromProfilePage: true);

                }
              } else if (value.isNotEmpty) {
                if (field == 'weight') {
                  _updateField(field, double.parse(value));
                  //doing this to trigger an update on the recommendation for the BMI since its affected by weight
                  getBMIRecommendation(triggeredFromProfilePage: true);
                } else {
                  _updateField(field, value);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showGenderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Gender'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: genderOptions.map((option) => RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: gender,
            onChanged: (value) {
              Navigator.pop(context);
              if (value != null) _updateField('gender', value);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showDateOfBirthPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != dateOfBirth) {
      _updateField('dateOfBirth', picked);
    }
  }

  void _showAllergiesDialog() {
    List<String> updatedAllergies = List.from(allergies);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Allergies'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...commonAllergies.map((allergy) => CheckboxListTile(
                    title: Text(allergy),
                    value: updatedAllergies.contains(allergy),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          updatedAllergies.add(allergy);
                        } else {
                          updatedAllergies.remove(allergy);
                        }
                      });
                    },
                  )),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Other allergies (comma-separated)',
                    ),
                    onChanged: (value) {
                      updatedAllergies.addAll(value.split(',').map((e) => e.trim()));
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text('Update'),
            onPressed: () {
              Navigator.pop(context);
              _updateField('allergies', updatedAllergies);
            },
          ),
        ],
      ),
    );
  }

  String _getLocalizedGender(BuildContext context, String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return AppLocalizations.of(context)!.maleText;
      case 'female':
        return AppLocalizations.of(context)!.femaleText;
      case 'other':
        return AppLocalizations.of(context)!.otherText;
      default:
        return gender;
    }
  }

  String _getLocalizedGoal(BuildContext context, String goal) {
    switch (goal) {
      case 'Weight loss':
        return AppLocalizations.of(context)!.weightLossGoal;
      case 'Allergies and food sensitivities':
        return AppLocalizations.of(context)!.allergiesGoal;
      case 'Meal planning':
        return AppLocalizations.of(context)!.mealPlanningGoal;
      case 'Set personal nutrition goals':
        return AppLocalizations.of(context)!.nutritionGoalsGoal;
      case 'Better eating habits':
        return AppLocalizations.of(context)!.eatingHabitsGoal;
      case 'Chronic diseases':
        return AppLocalizations.of(context)!.chronicDiseasesGoal;
      case 'Digestive issues':
        return AppLocalizations.of(context)!.digestiveIssuesGoal;
      case 'Other':
        return AppLocalizations.of(context)!.otherGoal;
      default:
        return goal;
    }
  }
}