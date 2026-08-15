import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'platform_capabilities.dart';

/// Adds the licences Flutter cannot find by itself (ADR-049).
///
/// `LicenseRegistry` is populated from the `LICENSE` file of every Dart package
/// in the build — Tafsiri's own MIT licence included, since the root package is
/// one of them. What it cannot know about is a program the app *runs*: text
/// recognition on the desktop shells out to Tesseract (ADR-037), which is
/// Apache-2.0 and appears nowhere in that list.
///
/// Tesseract is not bundled today — the user installs it — so this is
/// attribution rather than an obligation. It becomes an obligation the moment
/// the engine ships inside the app, which is open for both Windows and macOS,
/// and being correct in advance costs one asset.
void registerExtraLicenses() {
  // Only where it is actually used. Android and iOS recognise text with ML Kit,
  // which is a Dart package and already listed; claiming Tesseract there would
  // be a licence page describing software the app never touches.
  if (isMobilePlatform) return;

  LicenseRegistry.addLicense(() async* {
    final text =
        await rootBundle.loadString('assets/licenses/Tesseract-Apache-2.0.txt');
    yield LicenseEntryWithLineBreaks(const ['tesseract'], text);
  });
}
