import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../diagnostics_log.dart';
import 'clipboard_image_service.dart';
import 'process_clipboard_image_service.dart' show ClipboardProcessRunner;

/// Clipboard images on Windows, through the PowerShell that ships with it
/// (ADR-047).
///
/// There is no `wl-paste` here, but there is no need for a plugin either:
/// `System.Windows.Forms.Clipboard` can hand the image straight to a file, and
/// Windows PowerShell 5.1 is present on every supported version. Same reasoning
/// as Tesseract (ADR-037) and the Linux reader — a subprocess costs no native
/// build step and nothing to bundle.
///
/// The script writes the file itself rather than piping bytes back, which side-
/// steps the encoding trap that made Cyrillic arrive as mojibake (ADR-046):
/// binary through a text-decoding pipe is exactly the mistake to avoid twice.
class PowerShellClipboardImageService implements ClipboardImageService {
  const PowerShellClipboardImageService({ClipboardProcessRunner? runProcess})
      : _runProcess = runProcess;

  final ClipboardProcessRunner? _runProcess;

  ClipboardProcessRunner get _run => _runProcess ?? _defaultRunner;

  static Future<ProcessResult> _defaultRunner(
    String executable,
    List<String> arguments, {
    bool binary = false,
  }) =>
      Process.run(executable, arguments);

  @override
  Future<File?> readImage() async {
    final Directory directory;
    try {
      directory = await Directory.systemTemp.createTemp('tafsiri_clip');
    } on IOException catch (e) {
      diagLog('clipboard: could not create a temporary directory: $e');
      return null;
    }

    final file = File(p.join(directory.path, 'clipboard.png'));
    try {
      final result = await _run(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          // Clipboard access is only allowed from a single-threaded apartment.
          // 5.1 already defaults to it; saying so keeps this true if the
          // executable ever resolves to PowerShell 7, which defaults to MTA.
          '-STA',
          // Base64 UTF-16LE, so neither quoting nor a path with an umlaut in it
          // has to survive a round trip through the command line.
          '-EncodedCommand',
          encodePowerShellCommand(clipboardToPngScript(file.path)),
        ],
      );
      if (result.exitCode != 0) {
        diagLog('clipboard: powershell exited ${result.exitCode}: '
            '${result.stderr}');
      }
    } on ProcessException catch (e) {
      // No PowerShell on PATH. Reads as "no image", like every other platform
      // that cannot answer, so the caller falls back to pasting text.
      diagLog('clipboard: could not run powershell: ${e.message}');
      await _discard(directory);
      return null;
    }

    // The script writes nothing at all when the clipboard holds no image, so
    // the file's existence *is* the answer.
    if (!file.existsSync() || file.lengthSync() == 0) {
      await _discard(directory);
      return null;
    }
    diagLog('clipboard: powershell produced ${file.lengthSync()} B');
    return file;
  }

  Future<void> _discard(Directory directory) async {
    try {
      await directory.delete(recursive: true);
    } on IOException {
      // A leftover empty directory in temp is not worth reporting.
    }
  }
}

/// The script that saves a clipboard image to [path], or does nothing.
///
/// `GetImage` returns null for a clipboard holding anything else, and the guard
/// means "no image" and "no file" are the same outcome — nothing to distinguish
/// and nothing to parse out of stdout.
@visibleForTesting
String clipboardToPngScript(String path) {
  // PowerShell single-quoted strings escape a quote by doubling it, and take
  // everything else literally — including backslashes, which a double-quoted
  // string would treat as nothing special but which are worth not thinking
  // about at all here.
  final quoted = path.replaceAll("'", "''");
  return '''
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
\$image = [System.Windows.Forms.Clipboard]::GetImage()
if (\$image) {
  \$image.Save('$quoted', [System.Drawing.Imaging.ImageFormat]::Png)
  \$image.Dispose()
}
''';
}

/// [script] in the form `-EncodedCommand` expects: base64 of UTF-16LE.
///
/// Little-endian is written out by hand rather than taken from the host's
/// byte order, because the encoding PowerShell wants does not depend on the
/// machine Dart happens to be running on.
@visibleForTesting
String encodePowerShellCommand(String script) {
  final units = script.codeUnits;
  final bytes = Uint8List(units.length * 2);
  for (var i = 0; i < units.length; i++) {
    bytes[i * 2] = units[i] & 0xFF;
    bytes[i * 2 + 1] = (units[i] >> 8) & 0xFF;
  }
  return base64.encode(bytes);
}
