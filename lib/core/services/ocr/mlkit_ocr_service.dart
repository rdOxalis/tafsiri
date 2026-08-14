import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_service.dart';

/// On-device recognition via ML Kit — Android and iOS only (ADR-005).
///
/// ML Kit detects the script itself, so the language hints are ignored here.
class MlKitOcrService implements OcrService {
  const MlKitOcrService();

  @override
  Future<String> recogniseText(
    String imagePath, {
    required String primaryLanguage,
    required String altLanguage,
  }) async {
    final recognizer = TextRecognizer();
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(imagePath));
      final text = result.text.trim();
      if (text.isEmpty) {
        throw const OcrFailedException('ML Kit found no text in the image.');
      }
      return text;
    } finally {
      await recognizer.close();
    }
  }
}
