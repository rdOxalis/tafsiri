import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/licenses.dart';

/// Tesseract does real work for this app and appears in no licence list Flutter
/// builds by itself, because it is a program the app runs rather than a package
/// it links (ADR-049).
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

  test('adds nothing on mobile, where ML Kit does the reading', () async {
    // Listing Tesseract on Android would describe software the app never
    // touches there — the licence page has to be true, not merely generous.
    final names = await namesFor(TargetPlatform.android);

    expect(names, isEmpty);
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
