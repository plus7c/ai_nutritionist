import 'package:flutter/material.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class FoodLogWidget extends StatefulWidget {
  final GenerativeModel model;

  const FoodLogWidget({super.key, required this.model});

  @override
  _FoodLogWidgetState createState() => _FoodLogWidgetState();
}

class _FoodLogWidgetState extends State<FoodLogWidget> {
  final ImagePicker _picker = ImagePicker();
  List<FoodLogEntry> entries = [];
  bool _isLoading = false;

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
          entries.add(FoodLogEntry(image: bytes, nutritionInfo: nutritionInfo));
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

      // Remove any markdown code block indicators
      jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '');

      // Trim any leading or trailing whitespace
      jsonString = jsonString.trim();

      // Parse the JSON response
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
        title: const Text('Click a Food Photo for Nutrition Info'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
          ? const Center(child: Text('No entries yet. Add a food photo to get started!'))
          : ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.memory(entry.image),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.nutritionInfo.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text('Calories: ${entry.nutritionInfo.calories}'),
                      Text('Protein: ${entry.nutritionInfo.protein}g'),
                      Text('Carbs: ${entry.nutritionInfo.carbs}g'),
                      Text('Fat: ${entry.nutritionInfo.fat}g'),
                      Text('Ingredients: ${entry.nutritionInfo.ingredients.join(", ")}'),
                      Text('Allergens: ${entry.nutritionInfo.allergens.join(", ")}'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.add_event,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.camera_alt),
            label: 'Camera',
            onTap: () => _getImage(ImageSource.camera),
          ),
          SpeedDialChild(
            child: const Icon(Icons.photo),
            label: 'Gallery',
            onTap: () => _getImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class FoodLogEntry {
  final Uint8List image;
  final NutritionInfo nutritionInfo;

  FoodLogEntry({required this.image, required this.nutritionInfo});
}

class NutritionInfo {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<String> ingredients;
  final List<String> allergens;

  NutritionInfo({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
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
      ingredients: [],
      allergens: [],
    );
  }
}
