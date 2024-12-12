import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({Key? key}) : super(key: key);

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  File? _file;
  List<dynamic>? _recognitions;
  String _label = "";
  String _confidence = "";

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt",
      );
      debugPrint("Model loaded successfully.");
    } catch (e) {
      debugPrint("Error loading model: $e");
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _image = image;
          _file = File(image.path);
        });
        await _detectImage(_file!);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _detectImage(File image) async {
    try {
      final recognitions = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 6,
        threshold: 0.05,
        imageMean: 127.5,
        imageStd: 127.5,
      );

      setState(() {
        _recognitions = recognitions;
        if (_recognitions != null && _recognitions!.isNotEmpty) {
          _label = "Animal: ${_recognitions![0]["label"]}";
          _confidence =
              "Confidence: ${(double.parse(_recognitions![0]["confidence"].toString()) * 100).toStringAsFixed(2)}%";
        } else {
          _label = "No recognizable object detected.";
          _confidence = "";
        }
      });
    } catch (e) {
      debugPrint('Error detecting image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Text(
          'Object Detection via TFLite',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_image != null)
                Image.file(
                  File(_image!.path),
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Pick an image to identify',
                      style: TextStyle(fontSize: 18)),
                ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pick Image from Gallery'),
              ),
              const SizedBox(height: 22),
              Column(
                children: [
                  Text(
                    _label,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_confidence.isNotEmpty)
                    Text(
                      _confidence,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (_recognitions != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Full Recognitions: ${_recognitions.toString()}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}
