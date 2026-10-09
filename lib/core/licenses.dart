import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the licences Flutter cannot find by itself (ADR-049, ADR-075).
///
/// `LicenseRegistry` is populated from the `LICENSE` file of every Dart package
/// in the build — Tafsiri's own MIT licence included, since the root package is
/// one of them. What it cannot know about is native code that is not a Dart
/// package, and a program the app merely runs.
///
/// **Android** compiles Tesseract into the app, with the three libraries it is
/// built on (ADR-075). That is redistribution, so their licences are an
/// obligation there, not a courtesy: Apache-2.0 for Tesseract and its Android
/// wrapper, BSD-2-Clause for Leptonica, the libpng licence, and the IJG terms,
/// which ask in so many words to be credited in the documentation.
///
/// **The desktop** runs a Tesseract the user installed (ADR-037). Nothing is
/// redistributed, so only Tesseract is credited, as attribution — its own
/// dependencies belong to that installation, not to this app.
///
/// **iOS** recognises no text at all since ML Kit left, and claims nothing.
void registerExtraLicenses() {
  if (kIsWeb) return;
  final entries = switch (defaultTargetPlatform) {
    TargetPlatform.android => const {
        'tesseract': 'Tesseract-Apache-2.0.txt',
        'tesseract4android': 'Tesseract4Android-Apache-2.0.txt',
        'leptonica': 'Leptonica-BSD-2-Clause.txt',
        'libjpeg': 'libjpeg-IJG.txt',
        'libpng': 'libpng-LICENSE.txt',
      },
    TargetPlatform.iOS => const <String, String>{},
    _ => const {'tesseract': 'Tesseract-Apache-2.0.txt'},
  };

  for (final MapEntry(key: package, value: file) in entries.entries) {
    LicenseRegistry.addLicense(() async* {
      final text = await rootBundle.loadString('assets/licenses/$file');
      yield LicenseEntryWithLineBreaks([package], text);
    });
  }
}
