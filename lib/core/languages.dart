import 'constants.dart';
import 'services/ocr/tesseract_ocr_service.dart' show kTesseractLanguageCodes;

/// ISO 639-1 code for each language Tesseract knows.
const _iso1ByTesseractCode = <String, String>{
  'swa': 'sw', 'eng': 'en', 'deu': 'de', 'fra': 'fr', 'nld': 'nl',
  'spa': 'es', 'dan': 'da', 'nor': 'nb', 'swe': 'sv', 'pol': 'pl',
  'ita': 'it', 'por': 'pt', 'tur': 'tr', 'bul': 'bg', 'rus': 'ru',
  'ell': 'el', 'ara': 'ar',
};

/// The ISO 639-1 code for a language name or code, or `null` when unknown.
///
/// The settings hold free-text names ("Swahili", "Deutsch"); the history's
/// `source_lang` holds the code the AI detected ("sw"). Both go through the
/// same table OCR already uses, so "German", "Deutsch" and "de" agree. Norwegian
/// is "nb", as the recognition locales have it.
String? isoCodeFor(String nameOrCode) {
  final key = nameOrCode.trim().toLowerCase();
  if (key.isEmpty) return null;
  if (key == 'no') return 'nb';
  return _iso1ByTesseractCode[kTesseractLanguageCodes[key]];
}

/// The native name of a language code, as the settings list shows it
/// ("Kiswahili", "Deutsch"); the code itself when unknown.
String languageDisplayName(String code) {
  for (final (c, name) in kSttLanguageOptions) {
    if (c == code) return name;
  }
  return code;
}

/// The language a translation came out in (ADR-083): the confident language
/// when the input was in the learning language, the learning language
/// otherwise — the rule the translation prompt states. A correction stays in
/// the input's language. `null` when the input's language is unknown.
String? resultLanguageFor({
  required String sourceLang,
  required String learningLanguage,
  required String confidentLanguage,
  required bool isCorrection,
}) {
  final source = isoCodeFor(sourceLang);
  if (source == null) return null;
  if (isCorrection) return source;
  final learning = isoCodeFor(learningLanguage);
  return source == learning
      ? isoCodeFor(confidentLanguage)
      : learning;
}
