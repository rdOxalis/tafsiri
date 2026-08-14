import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/services/clipboard/powershell_clipboard_image_service.dart';

/// Guards the Windows clipboard reader (ADR-047) from Linux: the script that is
/// generated, the encoding it travels in, and what a missing image looks like.
void main() {
  final pngBytes = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0xFF];

  /// Decodes what `-EncodedCommand` carried, the way PowerShell would.
  String decodeCommand(List<String> arguments) {
    final encoded = arguments[arguments.indexOf('-EncodedCommand') + 1];
    final bytes = base64.decode(encoded);
    final units = <int>[
      for (var i = 0; i < bytes.length; i += 2) bytes[i] | (bytes[i + 1] << 8),
    ];
    return String.fromCharCodes(units);
  }

  /// The path the script was told to save to.
  String targetOf(String script) =>
      RegExp(r"\.Save\('(.+)',").firstMatch(script)!.group(1)!;

  test('writes the clipboard image to the path it generated', () async {
    // Stands in for PowerShell: decode the command, do what it says.
    late String script;
    final service = PowerShellClipboardImageService(
      runProcess: (executable, arguments, {binary = false}) async {
        expect(executable, 'powershell');
        script = decodeCommand(arguments);
        await File(targetOf(script)).writeAsBytes(pngBytes);
        return ProcessResult(0, 0, '', '');
      },
    );

    final file = await service.readImage();

    expect(file, isNotNull);
    expect(await file!.readAsBytes(), pngBytes);
    expect(file.path, endsWith('clipboard.png'));

    await file.parent.delete(recursive: true);
  });

  test('runs in a single-threaded apartment and skips the profile', () async {
    // Clipboard access is only allowed from an STA thread; -NoProfile keeps a
    // user's PowerShell profile from changing what the script sees.
    late List<String> seen;
    final service = PowerShellClipboardImageService(
      runProcess: (executable, arguments, {binary = false}) async {
        seen = arguments;
        return ProcessResult(0, 0, '', '');
      },
    );

    await service.readImage();

    expect(seen, containsAll(['-STA', '-NoProfile', '-NonInteractive']));
  });

  test('reports no image when the script wrote nothing', () async {
    // `Clipboard.GetImage()` returns null for a clipboard holding text, the
    // guard skips the save, and no file appears. That has to read as "no
    // image" so the caller falls back to pasting text.
    final service = PowerShellClipboardImageService(
      runProcess: (executable, arguments, {binary = false}) async =>
          ProcessResult(0, 0, '', ''),
    );

    expect(await service.readImage(), isNull);
  });

  test('reports no image when PowerShell is not there at all', () async {
    final service = PowerShellClipboardImageService(
      runProcess: (executable, arguments, {binary = false}) async =>
          throw ProcessException(executable, arguments, 'not found', 2),
    );

    expect(await service.readImage(), isNull);
  });

  test('an empty file is not an image', () async {
    // A save that failed halfway leaves a zero-byte file behind; handing that
    // to OCR would only produce a worse error.
    final service = PowerShellClipboardImageService(
      runProcess: (executable, arguments, {binary = false}) async {
        await File(targetOf(decodeCommand(arguments))).writeAsBytes(const []);
        return ProcessResult(0, 0, '', '');
      },
    );

    expect(await service.readImage(), isNull);
  });

  group('clipboardToPngScript', () {
    test('embeds the path literally, backslashes and all', () {
      // The real case: a Windows temp path under a profile with an umlaut in
      // it. Single quotes take everything literally, so nothing here needs
      // escaping — which is precisely why they are used.
      const path = r'C:\Users\RalfDünkelmann\AppData\Local\Temp\x\clipboard.png';

      final script = clipboardToPngScript(path);

      expect(script, contains("'$path'"));
      expect(script, contains('System.Windows.Forms.Clipboard'));
      expect(script, contains(r'if ($image)'),
          reason: 'a clipboard without an image must write no file');
    });

    test('doubles a quote in the path rather than ending the string', () {
      final script = clipboardToPngScript(r"C:\it's\clipboard.png");

      expect(script, contains(r"'C:\it''s\clipboard.png'"));
    });
  });

  test('encodes as base64 of UTF-16LE', () {
    // What -EncodedCommand expects. Byte order is written out by hand, so this
    // does not depend on the machine the test runs on.
    expect(encodePowerShellCommand('Hi'), base64.encode([0x48, 0, 0x69, 0]));
  });
}
