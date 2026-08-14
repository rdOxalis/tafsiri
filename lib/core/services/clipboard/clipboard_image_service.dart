import 'dart:io';

/// Reads an image out of the system clipboard, abstracted over the platform.
///
/// Flutter's own `Clipboard` is text-only, so an image on the clipboard is
/// invisible to the framework. Every implementation writes the bytes to a file
/// rather than returning them: the OCR engines take a path, and on desktop the
/// engine is a separate process that could not be handed a buffer anyway
/// (ADR-040).
abstract class ClipboardImageService {
  /// The clipboard image written to a temporary file, or `null` when the
  /// clipboard holds no image — including on platforms with no implementation,
  /// so callers can always fall back to pasting text.
  ///
  /// The caller owns the file and is responsible for deleting it.
  Future<File?> readImage();
}

/// Used where the platform has no way to read clipboard images.
///
/// Deliberately silent rather than throwing: "no image" and "cannot tell" lead
/// to exactly the same next step, which is to paste text instead.
class UnsupportedClipboardImageService implements ClipboardImageService {
  const UnsupportedClipboardImageService();

  @override
  Future<File?> readImage() async => null;
}
