import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clipboard_image_service.dart';
import 'process_clipboard_image_service.dart';

/// The clipboard image reader for the current platform (ADR-040).
///
/// Linux only for now. Android and Windows both *can* carry an image on the
/// clipboard, but neither is reachable the way Linux is: Android needs a
/// platform channel into `ClipboardManager`, and Windows needs either a
/// PowerShell round-trip or a plugin — and Windows has no OCR engine bundled
/// yet anyway (ADR-037), so an image pasted there would have nothing to read
/// it. Everywhere else returns "no image", which sends the caller down the
/// text-paste path it would have taken before this existed.
final clipboardImageServiceProvider = Provider<ClipboardImageService>((ref) {
  if (!kIsWeb && Platform.isLinux) {
    return const ProcessClipboardImageService();
  }
  return const UnsupportedClipboardImageService();
});
