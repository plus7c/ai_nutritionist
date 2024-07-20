import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'gemini_foodloggerpage.dart';

class FoodLoggerPage extends StatefulWidget {
  @override
  _FoodLoggerPageState createState() => _FoodLoggerPageState();
}

class _FoodLoggerPageState extends State<FoodLoggerPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _result = '';
  Uint8List? _uploadedImage;

  Future<void> _captureAndProcessImage(String type, ImageSource source) async {
    setState(() {
      _isLoading = true;
      _result = '';
      _uploadedImage = null;
    });

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final response = await GeminiFoodLogger.callGemini(type, bytes);
        setState(() {
          _uploadedImage = bytes;
          _result = response;
        });
      } else {
        setState(() {
          _result = 'No image selected. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Failed to pick image: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRecipeMarkdown(String recipeMarkdown) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: MarkdownBody(
        data: recipeMarkdown,
        styleSheet: MarkdownStyleSheet(
          h1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          p: TextStyle(fontSize: 16),
          listBullet: TextStyle(fontSize: 16),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Logger'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select an option:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            SizedBox(height: 16),
            _buildOptionButton('Detect Allergens 🥜', 'allergen'),
            _buildOptionButton('Detailed Nutrient Info 🥦', 'nutrients'),
            _buildOptionButton('Learn About Food 🍎', 'learn'),
            _buildOptionButton('Fun Facts About Food 🌮', 'fun_facts'),
            _buildOptionButton('Generate Dish 🍳', 'generate_dish'),
            SizedBox(height: 16),
            if (_uploadedImage != null)
              Column(
                children: [
                  Image.memory(_uploadedImage!),
                  SizedBox(height: 16),
                ],
              ),
            if (_result.isNotEmpty)
              _buildRecipeMarkdown(_result),
            if (_result.isNotEmpty || _uploadedImage != null)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Note: Results could be inaccurate. Always verify with a professional.',
                  style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String title, String type) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildButton(title, type, ImageSource.camera, 'Capture Photo'),
          _buildButton(title, type, ImageSource.gallery, 'Upload Image'),
        ],
      ),
    );
  }

  Widget _buildButton(String title, String type, ImageSource source, String action) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => _captureAndProcessImage(type, source),
          child: Text("$action for $title"),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            padding: EdgeInsets.all(10.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Slightly rounded corners
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: FoodLoggerPage(),
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
  ));
}
