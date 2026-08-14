import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform_capabilities.dart';
import 'mlkit_ocr_service.dart';
import 'ocr_service.dart';
import 'tesseract_ocr_service.dart';

/// The text recognition engine for the current platform.
///
/// ML Kit is Android/iOS only; desktop has no implementation and used to fail
/// on every image (ADR-031). Desktop therefore runs Tesseract instead (ADR-037).
final ocrServiceProvider = Provider<OcrService>((ref) {
  return isMobilePlatform
      ? const MlKitOcrService()
      : const TesseractOcrService();
});
