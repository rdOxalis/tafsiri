/// Text recognition, abstracted over the engine (ADR-037).
///
/// Mobile uses ML Kit, desktop shells out to Tesseract. The interface exists so
/// the controller never learns which one it got, and so Android can later swap
/// engines without touching anything above this line.
abstract class OcrService {
  /// Extracts text from the image at [imagePath].
  ///
  /// [primaryLanguage] and [altLanguage] are the human-readable names from
  /// Settings ("Swahili", "English"). Engines that pick the script themselves
  /// ignore them; Tesseract needs them to load the right trained data.
  ///
  /// Throws [OcrUnavailableException] when the engine cannot run at all, and
  /// [OcrFailedException] when it ran but produced nothing usable.
  Future<String> recogniseText(
    String imagePath, {
    required String primaryLanguage,
    required String altLanguage,
  });
}

/// The engine is missing or unusable — retrying the same image will not help,
/// the user has to install something.
class OcrUnavailableException implements Exception {
  const OcrUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'OcrUnavailableException: $message';
}

/// The engine ran, but this image yielded nothing worth using.
class OcrFailedException implements Exception {
  const OcrFailedException(this.message);

  final String message;

  @override
  String toString() => 'OcrFailedException: $message';
}
