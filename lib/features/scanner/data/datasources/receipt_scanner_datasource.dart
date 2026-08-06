import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptScannerDataSource {
  final TextRecognizer _textRecognizer;

  ReceiptScannerDataSource()
    : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<RecognizedText> recognizeText(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file not found at $imagePath');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    return await _textRecognizer.processImage(inputImage);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
