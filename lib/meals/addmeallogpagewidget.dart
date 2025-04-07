import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
// ignore: unused_import
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'LoggedMeal.dart';

class AddMealLogPage extends StatefulWidget {
  final GenerativeModel model;
  final Function addMealToLog;
  const AddMealLogPage({super.key, required this.model, required this.addMealToLog});

  @override
  _AddMealLogPageState createState() => _AddMealLogPageState();
}

class _AddMealLogPageState extends State<AddMealLogPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  DateTime _selectedDate = DateTime.now();
  String _mealTypeName = ''; 
  List<MealItem> _mealItems = [];
  bool _isLoading = false;

  final TextEditingController _mealItemNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _servingSizeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _mealTypeName = AppLocalizations.of(context)!.breakfastMealType;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = AppLocalizations.of(context);
    if (currentLocale != null) {
      final bool isBreakfast = _mealTypeName == AppLocalizations.of(context)!.breakfastMealType;
      final bool isLunch = _mealTypeName == AppLocalizations.of(context)!.lunchMealType;
      final bool isDinner = _mealTypeName == AppLocalizations.of(context)!.dinnerMealType;
      final bool isSnack = _mealTypeName == AppLocalizations.of(context)!.snackMealType;
      
      if (isBreakfast || _mealTypeName.isEmpty) {
        _mealTypeName = currentLocale.breakfastMealType;
      } else if (isLunch) {
        _mealTypeName = currentLocale.lunchMealType;
      } else if (isDinner) {
        _mealTypeName = currentLocale.dinnerMealType;
      } else if (isSnack) {
        _mealTypeName = currentLocale.snackMealType;
      }
    }
  }

  void _addMealItem() {
    if (_mealItemNameController.text.isNotEmpty && _caloriesController.text.isNotEmpty) {
      setState(() {
        _mealItems.add(MealItem(
          id: const Uuid().v4(), 
          mealItemName: _mealItemNameController.text,
          calories: int.parse(_caloriesController.text),
          carbs: _carbsController.text.isNotEmpty ? double.parse(_carbsController.text) : 0.0,
          fats: _fatsController.text.isNotEmpty ? double.parse(_fatsController.text) : 0.0,
          protein: _proteinController.text.isNotEmpty ? double.parse(_proteinController.text) : 0.0,
          servingSize: _servingSizeController.text.isNotEmpty ? double.parse(_servingSizeController.text) : 0.0,
        ));
        _mealItemNameController.clear();
        _caloriesController.clear();
        _carbsController.clear();
        _fatsController.clear();
        _proteinController.clear();
        _servingSizeController.clear();
      });
    }
  }

  Future<void> _storeMealLog() async {
    try {
      if (_mealItems.isEmpty || _mealTypeName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.addMealLogValidationError)),
        );
        return;
      }

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.loginRequiredError)),
        );
        return;
      }

      try {
        print('开始保存 meal log');
        print('用户ID: ${_auth.currentUser?.uid}');
        print('选择的日期: $_selectedDate');
        print('餐食类型: $_mealTypeName');
        print('餐食项目数量: ${_mealItems.length}');
        
        String? userId = _auth.currentUser?.uid;
        if (userId == null) {
          print('错误: 用户未登录');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.loginRequiredError)),
          );
          return;
        }
        
        MealType newMealType = MealType(mealTypeName: _mealTypeName, mealItems: _mealItems);
        print('新建 MealType: ${newMealType.mealTypeName}, 总卡路里: ${newMealType.totalCalories}');

        DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
        DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

        CollectionReference loggedMealsRef = _firestore.collection('users').doc(userId).collection('loggedmeals');
        print('Firestore 路径: users/$userId/loggedmeals');

        try {
          print('查询当天已有的 meal logs');
          QuerySnapshot existingLogs = await loggedMealsRef
              .where('timeOfLogging', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
              .where('timeOfLogging', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
              .get();
          
          print('查询结果: ${existingLogs.docs.length} 条记录');

          if (existingLogs.docs.isNotEmpty) {
            print('找到已有记录，更新现有记录');
            String docId = existingLogs.docs.first.id;
            print('文档ID: $docId');
            
            Map<String, dynamic> existingLogData = existingLogs.docs.first.data() as Map<String, dynamic>;
            print('现有数据: $existingLogData');
            
            LoggedMeal existingLoggedMeal = LoggedMeal.fromMap(existingLogData);
            print('转换为 LoggedMeal 对象成功');

            int mealTypeIndex = existingLoggedMeal.mealTypes.indexWhere((mealType) => mealType.mealTypeName == newMealType.mealTypeName);
            if (mealTypeIndex != -1) {
              print('更新现有餐食类型: ${newMealType.mealTypeName}');
              existingLoggedMeal.mealTypes[mealTypeIndex].mealItems.addAll(newMealType.mealItems);
            } else {
              print('添加新餐食类型: ${newMealType.mealTypeName}');
              existingLoggedMeal.mealTypes.add(newMealType);
            }

            widget.addMealToLog(existingLoggedMeal);
            
            Map<String, dynamic> updatedData = existingLoggedMeal.toMap();
            print('更新数据: $updatedData');
            
            await loggedMealsRef.doc(docId).update(updatedData);
            print('更新成功');
          } else {
            print('没有找到现有记录，创建新记录');
            LoggedMeal newLoggedMeal = LoggedMeal(timeOfLogging: _selectedDate, mealTypes: [newMealType]);
            
            Map<String, dynamic> newData = newLoggedMeal.toMap();
            print('新数据: $newData');
            
            DocumentReference docRef = await loggedMealsRef.add(newData);
            print('创建成功，新文档ID: ${docRef.id}');
            
            widget.addMealToLog(newLoggedMeal);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.mealLogAddedSuccess)),
          );

          setState(() {
            _mealTypeName = AppLocalizations.of(context)!.breakfastMealType;
            _mealItems.clear();
          });
        } catch (e) {
          print('Firestore 操作错误: $e');
          if (e is FirebaseException) {
            print('Firebase 错误代码: ${e.code}');
            print('Firebase 错误消息: ${e.message}');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.mealLogSaveError(e.toString()))),
          );
        }
      } catch (e) {
        print('一般错误: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.unexpectedError(e.toString()))),
        );
      }
    } catch (e) {
      print('一般错误: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.unexpectedError(e.toString()))),
      );
    }
  }

  Future<void> _getImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final nutritionInfo = await _generateNutritionInfo(bytes);
        setState(() {
          _mealItemNameController.text = nutritionInfo.name;
          _caloriesController.text = nutritionInfo.calories.toString();
          _carbsController.text = nutritionInfo.carbs.toString();
          _fatsController.text = nutritionInfo.fat.toString();
          _proteinController.text = nutritionInfo.protein.toString();
          _servingSizeController.text = nutritionInfo.servingSize.toString();
        });
      }
    } catch (e) {
      setState(() {
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<NutritionInfo> _generateNutritionInfo(Uint8List imageBytes) async {
    const prompt = '''
  Analyze this food image and provide the following information:
  1. Name of the dish
  2. Estimated calorie content
  3. Macronutrients (protein, carbs, fat) in grams
  4. List of main ingredients
  5. Any potential allergens

  Format the response as a JSON object with the following structure:
  {
    "name": "Dish name",
    "calories": 000,
    "protein": 00,
    "carbs": 00,
    "fat": 00,
    "ingredients": ["ingredient1", "ingredient2", ...],
    "allergens": ["allergen1", "allergen2", ...]
  }
  ''';

    try {
      final response = await widget.model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);

      String jsonString = response.text ?? '{}';

      jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '');

      jsonString = jsonString.trim();

      final jsonResponse = json.decode(jsonString);
      return NutritionInfo.fromJson(jsonResponse);
    } catch (e) {
      print('Error generating nutrition info: $e');
      return NutritionInfo.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context)!.addMealLogPageTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                InkWell(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2010),
                      lastDate: DateTime(2050),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.logDateLabel,
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _mealTypeName.isEmpty ? null : _mealTypeName,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.mealTypeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    AppLocalizations.of(context)!.breakfastMealType,
                    AppLocalizations.of(context)!.lunchMealType,
                    AppLocalizations.of(context)!.dinnerMealType,
                    AppLocalizations.of(context)!.snackMealType
                  ]
                      .map((label) => DropdownMenuItem(
                    value: label,
                    child: Text(label),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _mealTypeName = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.addMealItemValidationError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mealItemNameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.mealItemNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.addMealItemValidationError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _caloriesController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.caloriesLabel,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.addCaloriesValidationError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _carbsController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.carbsLabel,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fatsController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.fatsLabel,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _proteinController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.proteinLabel,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _servingSizeController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.servingSizeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _getImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: Text(AppLocalizations.of(context)!.takePhotoButton),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _addMealItem,
                            icon: const Icon(Icons.add),
                            label: Text(AppLocalizations.of(context)!.addMealItemButton),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_mealItems.isNotEmpty) ...[
                      Text(
                        AppLocalizations.of(context)!.mealItemsLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      ..._mealItems.map((item) => Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            item.mealItemName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(AppLocalizations.of(context)!.caloriesValueText(item.calories)),
                              Text(AppLocalizations.of(context)!.macroNutrientsText(
                                item.carbs.toDouble(), 
                                item.fats.toDouble(), 
                                item.protein.toDouble()
                              )),
                              Text(AppLocalizations.of(context)!.servingSizeValueText(item.servingSize.toDouble())),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _mealItems.remove(item);
                              });
                            },
                          ),
                        ),
                      )),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton.icon(
                      onPressed: () {
                          _storeMealLog();
                      },
                      icon: const Icon(Icons.save),
                      label: Text(AppLocalizations.of(context)!.saveMealLogButton),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NutritionInfo {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int servingSize;
  final List<String> ingredients;
  final List<String> allergens;

  NutritionInfo({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.ingredients,
    required this.allergens,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      name: json['name'] ?? 'Unknown',
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fat: json['fat'] ?? 0,
      servingSize: json['servingSize'] ?? 0,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      allergens: List<String>.from(json['allergens'] ?? []),
    );
  }

  factory NutritionInfo.empty() {
    return NutritionInfo(
      name: 'Unknown',
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      servingSize: 0,
      ingredients: [],
      allergens: [],
    );
  }
}
