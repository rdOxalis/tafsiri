import 'dart:io';

import 'package:flutter/foundation.dart';

/// Appends OCR diagnostics to a file next to the system temp directory.
///
/// `debugPrint` alone is not enough on desktop. A Flutter **release** build on
/// Windows is a GUI application: Dart binds its standard output at startup,
/// when no console is attached, and attaching one afterwards does not reconnect
/// it — so running the installed app from a terminal prints nothing at all.
/// That left the one failing platform as the one platform that could not be
/// asked what it was doing, and cost four rounds of guessing (ADR-044).
///
/// Writes are best-effort: a diagnostic that can break recognition is worse
/// than no diagnostic.
void ocrLog(String message) {
  debugPrint('[OCR] $message');
  if (kIsWeb) return;

  try {
    final file = File('${Directory.systemTemp.path}${Platform.pathSeparator}'
        'tafsiri-ocr.log');

    // Keep it small enough to paste into a bug report, and never let a long
    // session bury the run someone is actually looking at.
    if (file.existsSync() && file.lengthSync() > 64 * 1024) {
      file.writeAsStringSync('');
    }
    file.writeAsStringSync(
      '${DateTime.now().toIso8601String()}  $message\n',
      mode: FileMode.append,
      flush: true,
    );
  } on Object {
    // Deliberately swallowed, including the argument errors a locked-down
    // temp directory can raise.
  }
}

/// Where [ocrLog] writes, for the message that tells a user where to look.
String get ocrLogPath => kIsWeb
    ? ''
    : '${Directory.systemTemp.path}${Platform.pathSeparator}tafsiri-ocr.log';
