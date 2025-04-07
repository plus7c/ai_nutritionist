import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

import '../apptemplate/apptemplate.dart';

class UserStatsOnboarding extends StatefulWidget {
  const UserStatsOnboarding({super.key});

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
  final List<String> _selectedGoals = [];
  final List<String> _selectedAllergies = [];
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

      // 检查网络连接
      try {
        User? user = _auth.currentUser;
        if (user != null) {
          try {
            print('尝试保存用户数据到 Firestore，用户ID: ${user.uid}');
            
            // 准备数据，确保格式正确
            Map<String, dynamic> userData = {
              'username': _username,
              'gender': _gender,
              'dateOfBirth': _dateOfBirth != null ? Timestamp.fromDate(_dateOfBirth!) : null,
              'weight': _weight,
              'height': {
                'feet': _heightFeet,
                'inches': _heightInches,
              },
              'goals': _selectedGoals,
              'allergies': _selectedAllergies,
              'createdAt': FieldValue.serverTimestamp(), // 添加创建时间戳
            };
            
            print('保存的数据: $userData');
            
            // 确保 Firebase 已初始化
            if (!Firebase.apps.isNotEmpty) {
              await Firebase.initializeApp(
                options: DefaultFirebaseOptions.currentPlatform,
              );
            }
            
            // 使用事务确保写入成功
            await FirebaseFirestore.instance.runTransaction((transaction) async {
              transaction.set(
                FirebaseFirestore.instance.collection('users').doc(user.uid),
                userData
              );
            });
            
            print('用户数据保存成功');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User data saved successfully!')),
            );
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AppTemplate()));
          } catch (e) {
            print('Error saving user data: $e');
            // 添加更详细的错误日志
            if (e is FirebaseException) {
              print('Firebase Error Code: ${e.code}');
              print('Firebase Error Message: ${e.message}');
              print('Firebase Error Stack: ${e.stackTrace}');
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving user data: ${e.toString()}')),
            );
          }
        } else {
          print('No user is signed in');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user is signed in. Please sign in first.')),
          );
        }
      } catch (e) {
        print('General error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
        );
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Let\'s get to know you!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => value!.isEmpty ? 'Please enter a username' : null,
              onSaved: (value) => _username = value!,
              onChanged: (value) => _username = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
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
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
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
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
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
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
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
            const SizedBox(height: 16),
            const Text(
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
            )),
            const SizedBox(height: 16),
            const Text(
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
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Add custom allergy',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _customAllergy = value,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addCustomAllergy,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveUserData,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Slightly rounded corners
                ),
              ),
              child: Text('Save Profile')
            ),
          ],
        ),
      ),
    );
  }
}