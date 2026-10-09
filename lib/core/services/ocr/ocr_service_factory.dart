import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'android_tesseract_ocr_service.dart';
import 'ocr_service.dart';
import 'tesseract_ocr_service.dart';

/// The text recognition engine for the current platform.
///
/// Tesseract on both: compiled into the app on Android (ADR-075), run as an
/// installed program on the desktop (ADR-037). ML Kit used to serve Android
/// and iOS and is gone, because F-Droid cannot distribute it.
///
/// iOS is not a shipped platform, and nothing reads images there now; it gets
/// an engine that says so instead of one that fails obscurely.
final ocrServiceProvider = Provider<OcrService>((ref) {
  if (kIsWeb) return const UnavailableOcrService();
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => AndroidTesseractOcrService(),
    TargetPlatform.iOS => const UnavailableOcrService(),
    _ => const TesseractOcrService(),
  };
});

/// For platforms with no recognition engine at all.
class UnavailableOcrService implements OcrService {
  const UnavailableOcrService();

  @override
  Future<String> recogniseText(
    String imagePath, {
    required String primaryLanguage,
    required String altLanguage,
  }) async =>
      throw const OcrUnavailableException(
          'no text recognition on this platform');
}
