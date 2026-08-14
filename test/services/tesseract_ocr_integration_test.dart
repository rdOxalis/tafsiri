@TestOn('linux || mac-os || windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/services/ocr/tesseract_ocr_service.dart';

/// Drives the real `tesseract` binary end to end (ADR-037). Everything else is
/// covered by fakes; this is the one test that would notice if the command line
/// or the TSV format changed under us.
///
/// Skipped where Tesseract is not installed, which includes the Windows CI
/// runner — so it must never be the only guard on this code path.
void main() {
  final tesseract = _tesseractStatus();

  test('reads text from a real image', () async {
    const service = TesseractOcrService();

    final text = await service.recogniseText(
      'test/fixtures/ocr_sample.png',
      primaryLanguage: 'English',
      altLanguage: 'Swahili',
    );

    expect(text, 'Please give me butter');
  }, skip: tesseract);
}

/// `null` when Tesseract can run, otherwise the reason to skip.
String? _tesseractStatus() {
  try {
    final result = Process.runSync('tesseract', ['--version']);
    if (result.exitCode != 0) return 'tesseract exited with ${result.exitCode}';
    return null;
  } on ProcessException {
    return 'tesseract is not installed';
  }
}
