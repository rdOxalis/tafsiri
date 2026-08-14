import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mlkit_ocr_service.dart';
import 'ocr_service.dart';
import 'tesseract_ocr_service.dart';

/// ML Kit is Android/iOS only; desktop has no implementation and used to fail
/// on every image (ADR-031). Desktop therefore runs Tesseract instead (ADR-037).
bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// The text recognition engine for the current platform.
final ocrServiceProvider = Provider<OcrService>((ref) {
  return _isMobile ? const MlKitOcrService() : const TesseractOcrService();
});

/// True where picking an image can lead anywhere. Desktop image pickers offer
/// file selection only, so the camera entry in the source sheet would be a
/// guaranteed dead end.
bool get hasCamera => _isMobile;
