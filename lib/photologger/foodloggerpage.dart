import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'gemini_foodloggerpage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FoodLoggerPage extends StatefulWidget {
  const FoodLoggerPage({super.key});

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
          _result = AppLocalizations.of(context)!.noImageSelected;
        });
      }
    } catch (e) {
      setState(() {
        _result = AppLocalizations.of(context)!.failedToPickImage(e.toString());
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: MarkdownBody(
        data: recipeMarkdown,
        styleSheet: MarkdownStyleSheet(
          h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          p: const TextStyle(fontSize: 16),
          listBullet: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.foodLoggerPageTitle,
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        leading: const Icon(Icons.upload_file_sharp),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.foodLoggerPageDescription,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 16),
            _buildOptionButton(AppLocalizations.of(context)!.detectAllergensOption, 'allergen'),
            _buildOptionButton(AppLocalizations.of(context)!.nutrientInfoOption, 'nutrients'),
            _buildOptionButton(AppLocalizations.of(context)!.learnAboutFoodOption, 'learn'),
            _buildOptionButton(AppLocalizations.of(context)!.funFactsOption, 'fun_facts'),
            _buildOptionButton(AppLocalizations.of(context)!.generateDishOption, 'generate_dish'),
            const SizedBox(height: 16),
            if (_uploadedImage != null)
              Column(
                children: [
                  Image.memory(_uploadedImage!),
                  const SizedBox(height: 16),
                ],
              ),
            if (_result.isNotEmpty)
              _buildRecipeMarkdown(_result),
            if (_result.isNotEmpty || _uploadedImage != null)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  AppLocalizations.of(context)!.resultDisclaimer,
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
          _buildButton(title, type, ImageSource.camera, AppLocalizations.of(context)!.capturePhotoAction),
          _buildButton(title, type, ImageSource.gallery, AppLocalizations.of(context)!.uploadImageAction),
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
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
            padding: const EdgeInsets.all(10.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Slightly rounded corners
            ),
          ),
          child: Text(AppLocalizations.of(context)!.actionForOption(action, title)),
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
