/// Text recognition, abstracted over the engine (ADR-037).
///
/// Tesseract everywhere: compiled into the app on Android (ADR-075), run as an
/// installed program on the desktop. The interface exists so the controller
/// never learns which one it got — which is how ML Kit could be swapped out on
/// Android without touching anything above this line.
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

/// Nothing usable came back *and* the configured language had no trained data
/// installed — so the fix is a package away, not a better photo.
///
/// Only raised for that combination. A missing language pack that still yields
/// good text stays silent: for Latin scripts English trained data reads the
/// letters correctly and only drops diacritics, which the AI restores anyway.
/// It is the foreign scripts — Cyrillic, Arabic, Chinese — that produce noise
/// without their own data, and those are exactly the ones the confidence gate
/// catches (ADR-037).
class OcrLanguageMissingException implements Exception {
  const OcrLanguageMissingException(this.languageCodes);

  /// ISO 639-2 codes of the trained data that is not installed, e.g. `['bul']`.
  final List<String> languageCodes;

  @override
  String toString() =>
      'OcrLanguageMissingException: no trained data for '
      '${languageCodes.join(', ')}';
}

/// The trained data for a configured language could not be fetched (ADR-075).
///
/// Android only: there the data is downloaded on first use rather than
/// installed, so the remedy is a connection, not a package — and saying
/// "install Tesseract" to someone whose phone was merely offline would send
/// them looking for something that does not exist.
class OcrDataDownloadException implements Exception {
  const OcrDataDownloadException(this.languageCode);

  /// ISO 639-2 code whose data was not available, e.g. `swa`.
  final String languageCode;

  @override
  String toString() => 'OcrDataDownloadException: $languageCode';
}
