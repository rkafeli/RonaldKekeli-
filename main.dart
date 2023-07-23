import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class PlantIdentification extends StatefulWidget {
  @override
  _PlantIdentificationState createState() => _PlantIdentificationState();
}

class _PlantIdentificationState extends State<PlantIdentification> {
  File? _image;
  String? _result;
  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      var appDir = await getApplicationDocumentsDirectory();
      var modelPath = join(appDir.path, 'model.tflite');
      _interpreter = await Interpreter.fromAsset(modelPath);
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _predictImage() async {
    if (_image == null || _interpreter == null) return;

    var imageBytes = await _image!.readAsBytes();
    var input = imageBytes.buffer.asUint8List();

    var output = List.filled(_interpreter!.getOutputTensor(0).shape.reduce((a, b) => a * b), 0).buffer.asUint8List();
    _interpreter!.run(input, output);

    var labels = await File('assets/labels.txt').readAsLines();
    var maxIndex = output.indexOf(output.reduce((curr, next) => curr > next ? curr : next));
    setState(() {
      _result = labels[maxIndex];
    });
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    var pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
        _result = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plant Identification'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? Text('Select an image')
                : Image.file(
                    _image!,
                    height: 200,
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getImage,
              child: Text('Select Image'),
            ),
            SizedBox(height: 20),
            _result == null
                ? Container()
                : Text(
                    'Prediction: $_result',
                    style: TextStyle(fontSize: 20),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _predictImage,
        child: Icon(Icons.check),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: PlantIdentification(),
  ));
}
