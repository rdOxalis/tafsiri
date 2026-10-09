import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tafsiri/core/services/clipboard/clipboard_image_service.dart';
import 'package:tafsiri/core/services/clipboard/clipboard_image_service_factory.dart';
import 'package:tafsiri/core/services/ocr/ocr_service.dart';
import 'package:tafsiri/core/services/ocr/ocr_service_factory.dart';
import 'package:tafsiri/features/translator/translator_controller.dart';

class _OneImage implements ClipboardImageService {
  _OneImage(this.file);
  final File file;
  @override
  Future<File?> readImage() async => file;
}

class _Throwing implements OcrService {
  _Throwing(this.error);
  final Object error;
  @override
  Future<String> recogniseText(String imagePath,
          {required String primaryLanguage, required String altLanguage}) async =>
      throw error;
}

/// ADR-075 — on Android trained data is fetched, not installed, so a failed
/// fetch must not be reported as "install Tesseract".
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<OcrFailure?> failureFor(Object error) async {
    final dir = await Directory.systemTemp.createTemp('clip');
    final image = File('${dir.path}/shot.png')..writeAsBytesSync([0]);
    final container = ProviderContainer(overrides: [
      clipboardImageServiceProvider.overrideWithValue(_OneImage(image)),
      ocrServiceProvider.overrideWithValue(_Throwing(error)),
    ]);
    addTearDown(container.dispose);
    await container.read(translatorProvider.notifier).pasteImageFromClipboard();
    return container.read(translatorProvider).ocrError;
  }

  test('a failed download gets its own message', () async {
    expect(await failureFor(const OcrDataDownloadException('swa')),
        OcrFailure.downloadFailed);
  });

  test('a missing engine is still reported as one', () async {
    expect(await failureFor(const OcrUnavailableException('none')),
        OcrFailure.engineMissing);
  });

  test('an unreadable image is still an ordinary failure', () async {
    expect(await failureFor(const OcrFailedException('blurry')),
        OcrFailure.failed);
  });
}
