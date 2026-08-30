import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

/// The UI locale for a language named in Settings, or `null` for one Tafsiri
/// has no translation of (ADR-065).
///
/// Keyed the way the free-text field may spell it — English name, native name
/// and the two-letter code the AI returns — the same three spellings
/// `kTesseractLanguageCodes` accepts, and for the same reason: the setting
/// takes whatever the user types.
const kUiLocaleForLanguage = <String, Locale>{
  'swahili': Locale('sw'), 'kiswahili': Locale('sw'), 'sw': Locale('sw'),
  'english': Locale('en'), 'en': Locale('en'),
  'german': Locale('de'), 'deutsch': Locale('de'), 'de': Locale('de'),
  'french': Locale('fr'), 'français': Locale('fr'), 'francais': Locale('fr'),
  'fr': Locale('fr'),
  'dutch': Locale('nl'), 'nederlands': Locale('nl'), 'nl': Locale('nl'),
  'spanish': Locale('es'), 'español': Locale('es'), 'espanol': Locale('es'),
  'es': Locale('es'),
  'danish': Locale('da'), 'dansk': Locale('da'), 'da': Locale('da'),
  'norwegian': Locale('nb'), 'norsk': Locale('nb'), 'bokmål': Locale('nb'),
  'no': Locale('nb'), 'nb': Locale('nb'),
  'swedish': Locale('sv'), 'svenska': Locale('sv'), 'sv': Locale('sv'),
  'polish': Locale('pl'), 'polski': Locale('pl'), 'pl': Locale('pl'),
  'italian': Locale('it'), 'italiano': Locale('it'), 'it': Locale('it'),
  'bulgarian': Locale('bg'), 'български': Locale('bg'), 'bg': Locale('bg'),
};

/// A section heading in the two languages the user configured (ADR-065).
///
/// [term] picks the string; it is read from Tafsiri's own translation of that
/// language, so this can only ever produce wording a translator wrote — never
/// a machine translation of the interface.
///
/// The learning language comes first, because that is the word the learner is
/// here to pick up. A language Tafsiri is not translated into contributes
/// nothing rather than falling back to English, and identical terms collapse
/// to one — with Danish and Norwegian configured, "Forslag · Forslag" would be
/// noise. When neither side yields anything the app's own interface language
/// is used, which is what was shown before this existed.
String bilingualTerm({
  required String learningLanguage,
  required String confidentLanguage,
  required String Function(AppLocalizations) term,
  required AppLocalizations fallback,
}) {
  final terms = <String>[];
  for (final name in [learningLanguage, confidentLanguage]) {
    final locale = kUiLocaleForLanguage[name.trim().toLowerCase()];
    if (locale == null) continue;
    final value = term(lookupAppLocalizations(locale));
    if (!terms.contains(value)) terms.add(value);
  }
  if (terms.isEmpty) return term(fallback);
  return terms.join(' · ');
}
