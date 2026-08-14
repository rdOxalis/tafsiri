import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clipboard_image_service.dart';
import 'powershell_clipboard_image_service.dart';
import 'process_clipboard_image_service.dart';

/// The clipboard image reader for the current platform (ADR-040, ADR-047).
///
/// Linux goes through `wl-paste`/`xclip`, Windows through the PowerShell it
/// ships with. Android is the one left: its clipboard carries images as
/// `content://` URIs, which needs a platform channel into `ClipboardManager`
/// rather than a subprocess. Everywhere else returns "no image", which sends
/// the caller down the text-paste path it would have taken before this existed.
final clipboardImageServiceProvider = Provider<ClipboardImageService>((ref) {
  if (kIsWeb) return const UnsupportedClipboardImageService();
  if (Platform.isLinux) return const ProcessClipboardImageService();
  if (Platform.isWindows) return const PowerShellClipboardImageService();
  return const UnsupportedClipboardImageService();
});
