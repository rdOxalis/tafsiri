import 'dart:io';

import 'package:path/path.dart' as p;

import '../../diagnostics_log.dart';
import 'clipboard_image_service.dart';

/// Runs a process. Injectable so the tool selection and parsing can be tested
/// without a display server attached.
///
/// [binary] rather than an `Encoding?`: a nullable encoding parameter defaults
/// to null, which is exactly the value that means "raw bytes" — so forgetting
/// to pass it silently put the *type listing* into binary mode too, and every
/// clipboard looked empty. A bool has no such trap.
typedef ClipboardProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  bool binary,
});

/// The clipboard MIME types worth asking for, best first.
///
/// PNG is what screenshot tools put on the clipboard and what both OCR engines
/// read without conversion. The rest are there because a paste from an image
/// editor may offer nothing else.
const kClipboardImageTypes = <String>[
  'image/png',
  'image/jpeg',
  'image/bmp',
  'image/webp',
];

/// Clipboard images on Linux, through `wl-paste` or `xclip` (ADR-040).
///
/// A subprocess rather than a plugin, for the same reasons Tesseract is one
/// (ADR-037): no native build step, nothing to bundle, and the tools are
/// already on the kind of desktop that has a clipboard manager. Wayland is
/// tried first — on a Wayland session the X11 clipboard is a partial bridge
/// that frequently carries the text flavour of a copy but not the image, so
/// asking `xclip` first would report "no image" while the picture sits there.
class ProcessClipboardImageService implements ClipboardImageService {
  const ProcessClipboardImageService({ClipboardProcessRunner? runProcess})
      : _runProcess = runProcess;

  final ClipboardProcessRunner? _runProcess;

  ClipboardProcessRunner get _run => _runProcess ?? _defaultRunner;

  static Future<ProcessResult> _defaultRunner(
    String executable,
    List<String> arguments, {
    bool binary = false,
  }) =>
      Process.run(
        executable,
        arguments,
        stdoutEncoding: binary ? null : systemEncoding,
      );

  @override
  Future<File?> readImage() async {
    for (final tool in const [_WlPaste(), _XClip()]) {
      final type = await _offeredType(tool);
      if (type == null) continue;

      final bytes = await _bytes(tool, type);
      if (bytes == null || bytes.isEmpty) continue;

      diagLog('clipboard: ${tool.name} produced $type, ${bytes.length} B');
      return _writeTemporary(bytes, type);
    }
    return null;
  }

  /// The best image type [tool] says the clipboard offers, or `null` when it
  /// offers none — or when the tool is not installed, which reads the same.
  Future<String?> _offeredType(_ClipboardTool tool) async {
    final ProcessResult result;
    try {
      result = await _run(tool.executable, tool.listArguments);
    } on ProcessException {
      return null;
    }
    if (result.exitCode != 0) return null;

    final offered = '${result.stdout}'.split('\n').map((l) => l.trim()).toSet();
    for (final type in kClipboardImageTypes) {
      if (offered.contains(type)) return type;
    }
    return null;
  }

  Future<List<int>?> _bytes(_ClipboardTool tool, String type) async {
    final ProcessResult result;
    try {
      // Raw bytes: decoding the stream as text would corrupt every image.
      result = await _run(
        tool.executable,
        tool.readArguments(type),
        binary: true,
      );
    } on ProcessException {
      return null;
    }
    if (result.exitCode != 0) return null;

    final stdout = result.stdout;
    return stdout is List<int> ? stdout : null;
  }

  Future<File?> _writeTemporary(List<int> bytes, String type) async {
    try {
      final directory = await Directory.systemTemp.createTemp('tafsiri_clip');
      final file =
          File(p.join(directory.path, 'clipboard.${_extensionFor(type)}'));
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } on IOException catch (e) {
      diagLog('clipboard: could not write the image: $e');
      return null;
    }
  }

  String _extensionFor(String type) => switch (type) {
        'image/jpeg' => 'jpg',
        'image/bmp' => 'bmp',
        'image/webp' => 'webp',
        _ => 'png',
      };
}

/// One command-line clipboard tool, in the two ways it gets called.
abstract class _ClipboardTool {
  const _ClipboardTool();

  String get name;
  String get executable;
  List<String> get listArguments;
  List<String> readArguments(String type);
}

class _WlPaste extends _ClipboardTool {
  const _WlPaste();

  @override
  String get name => 'wl-paste';

  @override
  String get executable => 'wl-paste';

  @override
  List<String> get listArguments => const ['--list-types'];

  @override
  List<String> readArguments(String type) => ['--type', type];
}

class _XClip extends _ClipboardTool {
  const _XClip();

  @override
  String get name => 'xclip';

  @override
  String get executable => 'xclip';

  @override
  List<String> get listArguments =>
      const ['-selection', 'clipboard', '-t', 'TARGETS', '-o'];

  @override
  List<String> readArguments(String type) =>
      ['-selection', 'clipboard', '-t', type, '-o'];
}
