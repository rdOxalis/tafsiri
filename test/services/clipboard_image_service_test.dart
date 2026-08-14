import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tafsiri/core/services/clipboard/clipboard_image_service.dart';
import 'package:tafsiri/core/services/clipboard/process_clipboard_image_service.dart';

/// Guards the clipboard image reader (ADR-040) without a display server: which
/// tool is asked, in which order, and that the bytes survive the trip.
void main() {
  /// PNG magic plus a byte that is not valid UTF-8, so a run that decoded the
  /// stream as text instead of leaving it raw would corrupt it visibly.
  final pngBytes = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0xFF];

  final calls = <String>[];

  setUp(calls.clear);

  /// A fake clipboard where [offers] is what each tool reports it has.
  ClipboardProcessRunner runnerWith({
    List<String>? wlPaste,
    List<String>? xclip,
    List<int>? bytes,
  }) {
    return (executable, arguments, {binary = false}) async {
      calls.add('$executable ${arguments.join(' ')}');

      final offers = executable == 'wl-paste' ? wlPaste : xclip;
      if (offers == null) {
        throw ProcessException(executable, arguments, 'No such file', 2);
      }

      final isListing =
          arguments.contains('--list-types') || arguments.contains('TARGETS');
      // Mirror `Process.run`: the shape of `stdout` follows the mode, never the
      // caller's intent. A fake that always handed back a String hid a real
      // bug — the listing ran in binary mode, so the parser saw the text of a
      // byte array and every clipboard looked empty (ADR-040).
      expect(binary, isListing ? isFalse : isTrue);
      if (isListing) {
        return ProcessResult(0, 0, offers.join('\n'), '');
      }
      return ProcessResult(0, 0, bytes ?? pngBytes, '');
    };
  }

  test('reads a PNG the Wayland clipboard offers', () async {
    final service = ProcessClipboardImageService(
      runProcess: runnerWith(wlPaste: ['text/plain', 'image/png']),
    );

    final file = await service.readImage();

    expect(file, isNotNull);
    expect(await file!.readAsBytes(), pngBytes);
    expect(file.path, endsWith('.png'));
    // xclip must not have been consulted at all.
    expect(calls.any((c) => c.startsWith('xclip')), isFalse);

    await file.parent.delete(recursive: true);
  });

  test('falls back to xclip when Wayland has no image', () async {
    // The real shape of an X11 session, and of a Wayland session where the
    // bridge carried only the text flavour.
    final service = ProcessClipboardImageService(
      runProcess: runnerWith(
        wlPaste: ['text/plain'],
        xclip: ['TARGETS', 'image/png'],
      ),
    );

    final file = await service.readImage();

    expect(file, isNotNull);
    expect(await file!.readAsBytes(), pngBytes);
    expect(calls.any((c) => c.startsWith('xclip')), isTrue);

    await file.parent.delete(recursive: true);
  });

  test('survives a tool that is not installed', () async {
    // wl-paste absent on an X11-only box: a ProcessException must read as "no
    // image here", not take the whole paste down.
    final service = ProcessClipboardImageService(
      runProcess: runnerWith(xclip: ['TARGETS', 'image/png']),
    );

    final file = await service.readImage();

    expect(file, isNotNull);
    await file!.parent.delete(recursive: true);
  });

  test('returns null when the clipboard holds only text', () async {
    // The case that must stay silent — the caller then pastes text.
    final service = ProcessClipboardImageService(
      runProcess: runnerWith(
        wlPaste: ['text/plain', 'text/html'],
        xclip: ['TARGETS', 'UTF8_STRING'],
      ),
    );

    expect(await service.readImage(), isNull);
  });

  test('prefers PNG over the other flavours on offer', () async {
    final service = ProcessClipboardImageService(
      runProcess: runnerWith(wlPaste: ['image/bmp', 'image/jpeg', 'image/png']),
    );

    final file = await service.readImage();

    expect(calls.last, 'wl-paste --type image/png');
    await file!.parent.delete(recursive: true);
  });

  test('names the file after the type it actually got', () async {
    final service = ProcessClipboardImageService(
      runProcess: runnerWith(wlPaste: ['image/jpeg']),
    );

    final file = await service.readImage();

    expect(file!.path, endsWith('.jpg'));
    await file.parent.delete(recursive: true);
  });

  test('treats an empty read as no image', () async {
    // A tool can advertise a type and then hand back nothing; writing a
    // zero-byte file and calling OCR on it would only produce a worse error.
    final service = ProcessClipboardImageService(
      runProcess: runnerWith(wlPaste: ['image/png'], bytes: const []),
    );

    expect(await service.readImage(), isNull);
  });

  test('lists types as text and reads pixels as bytes', () async {
    // Both halves of the same trap. Decoding the image as text turns 0xFF into
    // U+FFFD and corrupts every paste; reading the type list as bytes makes an
    // image-bearing clipboard look empty. The modes must not be confused.
    final modes = <String, bool>{};
    final service = ProcessClipboardImageService(
      runProcess: (executable, arguments, {binary = false}) async {
        final listing = arguments.contains('--list-types');
        modes[listing ? 'list' : 'read'] = binary;
        if (listing) return ProcessResult(0, 0, 'image/png', '');
        return ProcessResult(0, 0, pngBytes, '');
      },
    );

    final file = await service.readImage();

    expect(modes, {'list': false, 'read': true});
    expect(await file!.readAsBytes(), pngBytes);
    await file.parent.delete(recursive: true);
  });

  test('the unsupported platform reader simply has nothing', () async {
    expect(await const UnsupportedClipboardImageService().readImage(), isNull);
  });
}
