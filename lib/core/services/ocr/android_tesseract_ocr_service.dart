import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ocr_service.dart';
import 'tessdata_store.dart';
import 'tesseract_ocr_service.dart' show kMinMeanConfidence, kTesseractLanguageCodes;

/// The two configured languages as Tesseract codes, in order, duplicates and
/// unknown names dropped (ADR-075).
///
/// Falls back to English when neither name is known: the settings field is
/// free text, and a name Tafsiri cannot map should still yield a reading of
/// Latin script rather than no reading at all.
List<String> tesseractCodesFor(List<String> languageNames) {
  final codes = <String>[];
  for (final name in languageNames) {
    final code = kTesseractLanguageCodes[name.trim().toLowerCase()];
    if (code != null && !codes.contains(code)) codes.add(code);
  }
  return codes.isEmpty ? const ['eng'] : codes;
}

/// Text recognition on Android through Tesseract built into the app
/// (ADR-075), replacing ML Kit, which F-Droid cannot distribute.
///
/// Two things ML Kit never offered come with it. **Any script Tesseract has
/// data for** — Bulgarian is a UI language, and ML Kit has no Cyrillic model,
/// so a photographed Bulgarian sign came back as confident Latin nonsense.
/// And **a confidence figure**, which lets the same gate as on the desktop turn
/// a bad read into an honest "could not read that" instead of fluent text that
/// was never on the image (ADR-037).
class AndroidTesseractOcrService implements OcrService {
  AndroidTesseractOcrService({TessdataStore? store, MethodChannel? channel})
      : _store = store ?? TessdataStore(),
        _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'tafsiri/tesseract';

  final TessdataStore _store;
  final MethodChannel _channel;

  @override
  Future<String> recogniseText(
    String imagePath, {
    required String primaryLanguage,
    required String altLanguage,
  }) async {
    final codes = tesseractCodesFor([primaryLanguage, altLanguage]);

    try {
      await _store.ensure(codes);
    } on TessdataDownloadException catch (e) {
      debugPrint('[OCR] trained data unavailable: $e');
      throw OcrDataDownloadException(e.code);
    }

    final Map<String, Object?>? result;
    try {
      result = await _channel.invokeMapMethod<String, Object?>('recognise', {
        'imagePath': imagePath,
        'dataPath': await _store.dataPath(),
        'languages': codes.join('+'),
      });
    } on PlatformException catch (e) {
      debugPrint('[OCR] ${e.code}: ${e.message}');
      if (e.code == 'init_failed') {
        // The files are there and Tesseract would not load them: corrupt or
        // truncated in a way the size check missed. Throw them away so the
        // next attempt fetches them fresh instead of failing the same way.
        await _store.discard(codes);
        throw OcrDataDownloadException(codes.first);
      }
      throw OcrFailedException(e.message ?? e.code);
    } on MissingPluginException {
      throw const OcrUnavailableException(
          'the Tesseract channel is not registered on this platform');
    }

    final text = (result?['text'] as String? ?? '').trim();
    final confidence = (result?['confidence'] as num? ?? 0).toDouble();
    debugPrint('[OCR] ${codes.join('+')}: ${text.length} chars, '
        'confidence ${confidence.toStringAsFixed(0)}');

    if (text.isEmpty) {
      throw const OcrFailedException('Tesseract found no text in the image.');
    }
    // The same gate as on the desktop (ADR-037). Below it the read is more
    // likely invented than seen, and the AI downstream would turn invented
    // characters into fluent, plausible text the user has no way to doubt.
    if (confidence < kMinMeanConfidence) {
      throw OcrFailedException(
          'confidence ${confidence.toStringAsFixed(0)} is below the gate');
    }
    return text;
  }
}
