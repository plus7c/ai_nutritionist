import 'package:flutter/material.dart';
import 'package:pizza_ordering_app/home/goalitem.dart';
import 'package:pizza_ordering_app/home/profilestat.dart';
import 'package:pizza_ordering_app/firestore_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fluttermoji/fluttermoji.dart';

class HomeProfile extends StatefulWidget {
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
        title: Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) :
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
              SizedBox(height: 16),
              Center(
                child: Text(
                  name.isNotEmpty ? name : 'Set your name',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),

              SizedBox(height: 24),
              _buildInfoTile('Weight', weight != null ? '${weight!.toStringAsFixed(1)} lbs' : 'Not set', Icons.fitness_center, () => _showUpdateDialog('Weight', 'weight')),
              _buildInfoTile('Height', _formatHeight(), Icons.height, () => _showUpdateDialog('Height', 'height')),
              _buildInfoTile('Gender', gender.isNotEmpty ? gender : 'Not set', Icons.person, _showGenderDialog),
              _buildInfoTile('Date of Birth', dateOfBirth != null ? DateFormat('MMM d, y').format(dateOfBirth!) : 'Not set', Icons.cake, _showDateOfBirthPicker),
              _buildInfoTile('Allergies', allergies.isNotEmpty ? allergies.join(', ') : 'None', Icons.warning, _showAllergiesDialog),
              SizedBox(height: 24),
              Text('Goals', style: Theme.of(context).textTheme.headline6),
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
      trailing: Icon(Icons.edit),
      onTap: onTap,
    );
  }

  List<Widget> _buildGoalItems() {
    return goals.map((goal) => CheckboxListTile(
      title: Text(goal),
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
                      labelText: 'Feet',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: inchesController,
                    decoration: InputDecoration(
                      labelText: 'Inches',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Please enter your height in feet and inches.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        )
            : TextField(
          decoration: InputDecoration(
            hintText: 'Enter new $title',
            border: OutlineInputBorder(),
          ),
          keyboardType: field == 'weight' ? TextInputType.number : TextInputType.text,
          onChanged: (val) => value = val,
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Update'),
            onPressed: () {
              Navigator.pop(context);
              if (field == 'height') {
                if (feetController.text.isNotEmpty && inchesController.text.isNotEmpty) {
                  int feet = int.parse(feetController.text);
                  int inches = int.parse(inchesController.text);
                  _updateField(field, {'feet': feet, 'inches': inches});
                }
              } else if (value.isNotEmpty) {
                if (field == 'weight') {
                  _updateField(field, double.parse(value));
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
        title: Text('Update Gender'),
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
        title: Text('Update Allergies'),
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
                  )).toList(),
                  TextField(
                    decoration: InputDecoration(
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
          TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: Text('Update'),
            onPressed: () {
              Navigator.pop(context);
              _updateField('allergies', updatedAllergies);
            },
          ),
        ],
      ),
    );
  }
}