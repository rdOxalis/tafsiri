// AI provider identifiers
const kProviderMistral = 'mistral';
const kProviderClaude = 'claude';
const kProviderOpenAI = 'openai';

// SharedPreferences keys
const kPrefApiKeyMistral = 'api_key_mistral';
const kPrefApiKeyClaude = 'api_key_claude';
const kPrefApiKeyOpenAI = 'api_key_openai';
const kPrefActiveProvider = 'active_provider';
const kPrefTargetLanguage = 'target_language';
const kPrefAltLanguage = 'alt_language';
const kPrefAppLocale = 'app_locale';
const kPrefCorrectionMode = 'correction_mode';

// Default setting values
const kDefaultTargetLanguage = 'Swahili';
const kDefaultAltLanguage = 'English';
const kDefaultProvider = kProviderMistral;

// Result modes (ADR-033) — how the AI handled the input.
const kModeTranslate = 'translate';
const kModeCorrect = 'correct';

// External URLs
const kPayPalDonateUrl = 'https://paypal.me/CarlDarkman';
const kMistralApiKeyUrl = 'https://console.mistral.ai/api-keys';
const kClaudeApiKeyUrl = 'https://console.anthropic.com/settings/keys';
const kOpenAiApiKeyUrl = 'https://platform.openai.com/api-keys';

// API key log masking
String maskApiKey(String key) {
  if (key.length <= 4) return '****';
  return '${key.substring(0, 4)}****';
}

// SharedPreferences key for STT input language
const kPrefSttLanguage = 'stt_language';

// STT language options: (ISO-639-1 code, display name). Empty code = auto.
const List<(String, String)> kSttLanguageOptions = [
  ('', 'Auto'),
  ('de', 'Deutsch'),
  ('en', 'English'),
  ('fr', 'Français'),
  ('nl', 'Nederlands'),
  ('es', 'Español'),
  ('da', 'Dansk'),
  ('nb', 'Norsk'),
  ('sv', 'Svenska'),
  ('pl', 'Polski'),
  ('sw', 'Kiswahili'),
  ('it', 'Italiano'),
  ('bg', 'Български'),
];

/// [kSttLanguageOptions] in display order.
///
/// The empty code is the "Auto" mode rather than a language, and its label is
/// localised — so it is pinned to the top instead of sorting under whatever
/// letter the current UI language happens to give it.
List<(String, String)> get sortedSttLanguageOptions {
  final languages = kSttLanguageOptions.where((e) => e.$1.isNotEmpty).toList()
    ..sort((a, b) => compareLanguageLabels(a.$2, b.$2));
  return [
    ...kSttLanguageOptions.where((e) => e.$1.isEmpty),
    ...languages,
  ];
}

/// Orders language names the way someone scanning a list expects to find them.
///
/// `String.compareTo` sorts by code unit, which files `Español` after `Svenska`
/// and drops every Cyrillic name at the end by accident rather than by
/// intention. This folds case and diacritics, so `Español` sits under E and
/// `Français` under F, and ranks scripts explicitly, so a name in another
/// alphabet groups at the end because that is where it is useful — not because
/// of where its code points happen to fall. The names themselves stay endonyms:
/// you recognise your own language faster than its translation (ADR-039).
int compareLanguageLabels(String a, String b) {
  final byScript = _scriptRank(a).compareTo(_scriptRank(b));
  if (byScript != 0) return byScript;
  return _sortKey(a).compareTo(_sortKey(b));
}

/// 0 for a name written in the Latin alphabet, 1 for anything else.
int _scriptRank(String label) =>
    label.isNotEmpty && label.codeUnitAt(0) <= 0x024F ? 0 : 1;

/// Lower case, with Latin diacritics folded onto their base letter.
String _sortKey(String label) {
  final buffer = StringBuffer();
  for (final rune in label.toLowerCase().runes) {
    final character = String.fromCharCode(rune);
    buffer.write(_foldedDiacritics[character] ?? character);
  }
  return buffer.toString();
}

/// Covers the diacritics of the app's languages, not all of Unicode — anything
/// unlisted falls through unchanged and still sorts sensibly among its peers.
const _foldedDiacritics = <String, String>{
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ā': 'a',
  'æ': 'ae',
  'ç': 'c', 'ć': 'c', 'č': 'c',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ę': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i',
  'ł': 'l',
  'ñ': 'n', 'ń': 'n',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ø': 'o', 'ō': 'o',
  'ś': 's', 'š': 's', 'ß': 'ss',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ź': 'z', 'ż': 'z', 'ž': 'z',
};

// STT locale map: ISO-639-1 → BCP-47
const Map<String, String> kSttLocaleMap = {
  'sw': 'sw-TZ',
  'de': 'de-DE',
  'en': 'en-GB',
  'fr': 'fr-FR',
  'nl': 'nl-NL',
  'es': 'es-ES',
  'da': 'da-DK',
  'no': 'nb-NO',
  'nb': 'nb-NO',
  'sv': 'sv-SE',
  'pl': 'pl-PL',
  'it': 'it-IT',
  'bg': 'bg-BG',
};
