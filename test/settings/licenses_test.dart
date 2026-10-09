import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/licenses.dart';

/// Native code and external programs appear in no licence list Flutter builds
/// by itself: Tesseract run on the desktop (ADR-049), and Tesseract compiled
/// into Android together with its libraries (ADR-075).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The package names [registerExtraLicenses] contributes on [platform].
  ///
  /// `LicenseRegistry` has no way to remove entries, so each case runs its own
  /// registration and reads only what that call added.
  Future<List<String>> namesFor(TargetPlatform platform) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      final names = <String>[];
      final before = await LicenseRegistry.licenses.length;
      registerExtraLicenses();
      var index = 0;
      await for (final entry in LicenseRegistry.licenses) {
        if (index++ >= before) names.addAll(entry.packages);
      }
      return names;
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  test('adds Tesseract on the desktop', () async {
    final names = await namesFor(TargetPlatform.linux);

    expect(names, contains('tesseract'));
  });

  test('lists everything Android compiles in (ADR-075)', () async {
    // Tesseract and the three libraries it is built on ship inside the APK
    // now. That is redistribution, so these are obligations, not courtesy.
    final names = await namesFor(TargetPlatform.android);

    expect(names, containsAll(
        ['tesseract', 'tesseract4android', 'leptonica', 'libjpeg', 'libpng']));
  });

  test('the desktop credits only the Tesseract the user installed', () async {
    // Leptonica and the image libraries belong to that installation there,
    // not to this app — claiming them would describe software we do not ship.
    final names = await namesFor(TargetPlatform.windows);

    expect(names, ['tesseract']);
  });

  test('iOS reads no text, and claims nothing', () async {
    expect(await namesFor(TargetPlatform.iOS), isEmpty);
  });

  test('every Android licence is the real text, not a placeholder', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final before = await LicenseRegistry.licenses.length;
    registerExtraLicenses();
    final texts = <String, String>{};
    var index = 0;
    await for (final entry in LicenseRegistry.licenses) {
      if (index++ >= before) {
        texts[entry.packages.single] =
            entry.paragraphs.map((p) => p.text).join(' ').toLowerCase();
      }
    }

    expect(texts['tesseract4android'], contains('apache license'));
    expect(texts['leptonica'], contains('redistribution and use'));
    // The IJG terms ask to be credited in exactly these words.
    expect(texts['libjpeg'], contains('independent jpeg group'));
    expect(texts['libpng'], contains('png reference library'));
  });

  test('the licence text is the real Apache 2.0', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final before = await LicenseRegistry.licenses.length;
    registerExtraLicenses();

    var index = 0;
    LicenseEntry? tesseract;
    await for (final entry in LicenseRegistry.licenses) {
      if (index++ >= before && entry.packages.contains('tesseract')) {
        tesseract = entry;
      }
    }

    final text =
        tesseract!.paragraphs.map((p) => p.text).join(' ').toLowerCase();
    expect(text, contains('apache license'));
    expect(text, contains('version 2.0'));
  });
}
