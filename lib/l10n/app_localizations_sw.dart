// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appTitle => 'Tafsiri';

  @override
  String get translateButton => 'Tafsiri';

  @override
  String get inputHint => 'Ingiza maandishi ya kutafsiri…';

  @override
  String get outputHint => 'Tafsiri itaonekana hapa';

  @override
  String get clearButton => 'Futa';

  @override
  String get pasteButton => 'Bandika';

  @override
  String get copyButton => 'Nakili';

  @override
  String get microphoneButton => 'Ingizo la sauti';

  @override
  String get imageButton => 'Ingizo la picha';

  @override
  String get navTranslator => 'Kutafsiri';

  @override
  String get navHistory => 'Historia';

  @override
  String get navSettings => 'Mipangilio';

  @override
  String get historyTitle => 'Historia';

  @override
  String get historyEmpty => 'Hakuna tafsiri bado';

  @override
  String get historyReloadTitle => 'Pakia tafsiri';

  @override
  String get historyReloadMessage => 'Pakia maandishi haya kwenye kitafsiri?';

  @override
  String get historyReloadConfirm => 'Pakia';

  @override
  String get cancel => 'Ghairi';

  @override
  String get delete => 'Futa';

  @override
  String get undoDelete => 'Tendua';

  @override
  String get favouritesLabel => 'Vipendwa';

  @override
  String get allLabel => 'Zote';

  @override
  String get settingsTitle => 'Mipangilio';

  @override
  String get apiKeyMistral => 'Ufunguo wa Mistral API';

  @override
  String get apiKeyClaude => 'Ufunguo wa Claude API';

  @override
  String get apiKeyOpenAI => 'Ufunguo wa OpenAI API';

  @override
  String get providerLabel => 'Mtoa huduma wa AI';

  @override
  String get targetLanguageLabel => 'Lugha Lengwa';

  @override
  String get altLanguageLabel => 'Lugha Mbadala';

  @override
  String get appLanguageLabel => 'Lugha ya Programu';

  @override
  String get warningNoApiKey =>
      'Hakuna ufunguo wa API kwa mtoa huduma aliyechaguliwa. Tafadhali ongeza ufunguo wako hapa chini.';

  @override
  String get donateButton => 'Nununulie kahawa';

  @override
  String get errorNoApiKey =>
      'Hakuna ufunguo wa API. Tafadhali ongeza ufunguo wako katika Mipangilio.';

  @override
  String get errorApiError => 'Tafsiri imeshindwa. Tafadhali jaribu tena.';

  @override
  String get errorNetwork =>
      'Hakuna muunganisho. Tafadhali angalia intaneti yako.';

  @override
  String get errorOcrFailed => 'Haikuweza kutoa maandishi kutoka kwa picha.';

  @override
  String get errorSttUnavailable =>
      'Ingizo la sauti halipatikani kwenye kifaa hiki.';

  @override
  String get providerMistral => 'Mistral';

  @override
  String get providerClaude => 'Claude';

  @override
  String get providerOpenAI => 'ChatGPT';
}
