@TestOn('linux || mac-os || windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/services/ocr/ocr_service.dart';
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

  test('detects a script it was given no language for', () async {
    // The output format of `--psm 0` is what parseOsd depends on, and it is not
    // something to guess at. Asserting the *detection* rather than a successful
    // Cyrillic read keeps this stable whether or not the machine happens to
    // have script/Cyrillic trained data installed.
    const service = TesseractOcrService();

    expect(
      await service.detectScript('test/fixtures/ocr_sample_cyrillic.png'),
      'Cyrillic',
    );
  }, skip: tesseract);

  test('detects the script of a phrase too short for plain OSD', () async {
    // The regression (ADR-038). `tesseract --psm 0` answers this 21-character
    // line with "Too few characters. Skipping this page", which used to leave
    // detectScript with nothing and let a Latin misread through. The other
    // Cyrillic fixtures are 40 and 94 characters and clear OSD's floor on their
    // own, so only a short one can catch this.
    const service = TesseractOcrService();

    expect(
      await service.detectScript('test/fixtures/ocr_sample_bulgarian_short.png'),
      'Cyrillic',
    );
  }, skip: tesseract);

  test('never returns Latin nonsense for a short Cyrillic phrase', () async {
    // End to end on the image that actually failed in the app: Bulgarian
    // configured, no `bul` trained data, a phrase under OSD's character floor.
    // "Mona Te, nal Mu MacnoTo." at 70.6 confidence must never come back.
    const service = TesseractOcrService();

    try {
      final text = await service.recogniseText(
        'test/fixtures/ocr_sample_bulgarian_short.png',
        primaryLanguage: 'Bulgarian',
        altLanguage: 'English',
      );
      expect(text, matches(RegExp(r'[Ѐ-ӿ]')),
          reason: 'a Cyrillic image must not come back as Latin text');
    } on OcrLanguageMissingException catch (e) {
      expect(e.languageCodes, ['bul']);
    }
  }, skip: tesseract);

  test('never returns Latin nonsense for a Cyrillic image', () async {
    // Against the real engine, with Latin languages configured. Two outcomes
    // are correct depending on what this machine has installed: the read
    // succeeds in Cyrillic, or it reports the missing script package. What must
    // never happen is the third — plausible-looking Latin junk handed onwards,
    // which is what English trained data produces here at 60.5 confidence.
    const service = TesseractOcrService();

    try {
      final text = await service.recogniseText(
        'test/fixtures/ocr_sample_bulgarian.png',
        primaryLanguage: 'German',
        altLanguage: 'English',
      );
      expect(text, matches(RegExp(r'[Ѐ-ӿ]')),
          reason: 'a Cyrillic image must not come back as Latin text');
    } on OcrLanguageMissingException catch (e) {
      expect(e.languageCodes, ['script-cyrl']);
    }
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
