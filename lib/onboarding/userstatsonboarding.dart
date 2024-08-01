import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pizza_ordering_app/apptemplate/apptemplate.dart';
import 'package:pizza_ordering_app/home/profile.dart';
import 'package:intl/intl.dart';

class UserStatsOnboarding extends StatefulWidget {
  const UserStatsOnboarding({Key? key}) : super(key: key);

  @override
  State<UserStatsOnboarding> createState() => _UserStatsOnboardingState();
}

class _UserStatsOnboardingState extends State<UserStatsOnboarding> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _username = '';
  String _gender = 'Male';
  DateTime? _dateOfBirth;
  double _weight = 0;
  int _heightFeet = 0;
  int _heightInches = 0;
  List<String> _selectedGoals = [];
  List<String> _selectedAllergies = [];
  String _customAllergy = '';

  List<String> genders = ['Male', 'Female', 'Other'];
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
  List<String> commonAllergies = [
    'Milk', 'Eggs', 'Peanuts', 'Tree nuts', 'Fish', 'Shellfish', 'Soy', 'Wheat'
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingUserStats();
  }

  Future<void> _checkExistingUserStats() async {
    setState(() {
      _isLoading = true;
    });
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AppTemplate()),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Error checking user stats: $e");
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      print('Form validation passed');
      _formKey.currentState!.save();
      print('Username: $_username');
      print('Weight: $_weight');
      print('Height: $_heightFeet feet $_heightInches inches');

      User? user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'username': _username,
            'gender': _gender,
            'dateOfBirth': _dateOfBirth,
            'weight': _weight,
            'height': {
              'feet': _heightFeet,
              'inches': _heightInches,
            },
            'goals': _selectedGoals,
            'allergies': _selectedAllergies,
          });
          print('User data saved successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User data saved successfully!')),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AppTemplate()));
        } catch (e) {
          print('Error saving user data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving user data. Please try again.')),
          );
        }
      }
    } else {
      print('Form validation failed');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  void _addCustomAllergy() {
    if (_customAllergy.isNotEmpty && !_selectedAllergies.contains(_customAllergy)) {
      setState(() {
        _selectedAllergies.add(_customAllergy);
        _customAllergy = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            Text(
              'Let\'s get to know you!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => value!.isEmpty ? 'Please enter a username' : null,
              onSaved: (value) => _username = value!,
              onChanged: (value) => _username = value,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              items: genders.map((String gender) {
                return DropdownMenuItem(value: gender, child: Text(gender));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _gender = newValue!;
                });
              },
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake),
                  ),
                  validator: (value) => _dateOfBirth == null ? 'Please select your date of birth' : null,
                  controller: TextEditingController(
                    text: _dateOfBirth == null ? '' : DateFormat('MMM d, y').format(_dateOfBirth!),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Weight (lbs)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your weight';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onSaved: (value) => _weight = double.parse(value!),
              onChanged: (value) => _weight = double.tryParse(value) ?? 0,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Height (feet)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter feet';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                    onSaved: (value) => _heightFeet = int.parse(value!),
                    onChanged: (value) => _heightFeet = int.tryParse(value) ?? 0,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Height (inches)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter inches';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter a valid number';
                      }
                      int inches = int.parse(value);
                      if (inches < 0 || inches >= 12) {
                        return 'Enter a value between 0 and 11';
                      }
                      return null;
                    },
                    onSaved: (value) => _heightInches = int.parse(value!),
                    onChanged: (value) => _heightInches = int.tryParse(value) ?? 0,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Select your goals:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...goals.map((goal) => CheckboxListTile(
              title: Text(goal),
              value: _selectedGoals.contains(goal),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedGoals.add(goal);
                  } else {
                    _selectedGoals.remove(goal);
                  }
                });
              },
            )).toList(),
            SizedBox(height: 16),
            Text(
              'Select your allergies:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...commonAllergies.map((allergy) => CheckboxListTile(
              title: Text(allergy),
              value: _selectedAllergies.contains(allergy),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedAllergies.add(allergy);
                  } else {
                    _selectedAllergies.remove(allergy);
                  }
                });
              },
            )).toList(),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Add custom allergy',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _customAllergy = value,
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addCustomAllergy,
                  child: Text('Add'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Selected Allergies:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: _selectedAllergies.map((allergy) => Chip(
                label: Text(allergy),
                onDeleted: () {
                  setState(() {
                    _selectedAllergies.remove(allergy);
                  });
                },
              )).toList(),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveUserData,
              child: Text('Save Profile'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}