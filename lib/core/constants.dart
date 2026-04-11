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

// Default setting values
const kDefaultTargetLanguage = 'Swahili';
const kDefaultAltLanguage = 'English';
const kDefaultProvider = kProviderMistral;

// External URLs
const kPayPalDonateUrl = 'https://paypal.me/CarlDarkman';

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
];

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
};
