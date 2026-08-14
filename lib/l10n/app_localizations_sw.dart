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
  String get providerSubtitle => 'tumia ufunguo wako wa API';

  @override
  String get targetLanguageLabel => 'Lugha ya Msingi';

  @override
  String get altLanguageLabel => 'Lugha ya Pili';

  @override
  String get targetLanguageInfo =>
      'Lugha ya msingi — lugha unayotaka kujifunza, au ambayo huimudu vizuri.';

  @override
  String get altLanguageInfo =>
      'Lugha ya pili — lugha unayoimudu vizuri, na ambayo maandishi yako hutafsiriwa kwake unapoandika kwa lugha ya msingi.';

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
  String get errorOcrEngineMissing =>
      'Utambuzi wa maandishi haujasakinishwa. Sakinisha Tesseract ili kusoma maandishi kwenye picha.';

  @override
  String errorOcrLanguageMissing(String package) {
    return 'Utambuzi wa maandishi hauna data ya lugha hii. Sakinisha: $package';
  }

  @override
  String get errorSttUnavailable =>
      'Ingizo la sauti halipatikani kwenye kifaa hiki.';

  @override
  String get providerMistral => 'Mistral';

  @override
  String get providerClaude => 'Claude';

  @override
  String get providerOpenAI => 'ChatGPT';

  @override
  String get ocrSourceCamera => 'Kamera';

  @override
  String get ocrSourceGallery => 'Picha';

  @override
  String get sttLanguageLabel => 'Utambuzi wa Sauti (Maikrofoni)';

  @override
  String get sttLanguageAuto => 'Kiotomatiki (kutoka tafsiri ya mwisho)';

  @override
  String get translationLanguagesSection => 'Lugha za Tafsiri';

  @override
  String get translationInfoTitle => 'Jinsi inavyofanya kazi';

  @override
  String get translationInfoPart1 =>
      'Maandishi yaliyoingizwa yatatafsirishwa kwa ';

  @override
  String get translationInfoPart2 => '. Ikiwa maandishi tayari ni ';

  @override
  String get translationInfoPart3 => ', yatatafsirishwa kwa ';

  @override
  String get translationInfoPart4 => '.';

  @override
  String get getApiKeyButton => 'Pata ufunguo wa API';

  @override
  String get mistralFreeHint =>
      'Mistral inatoa kiwango cha bure – hakuna kadi ya mkopo inayohitajika';

  @override
  String get correctionModeLabel => 'Hali ya kusahihisha';

  @override
  String get correctionButton => 'Sahihisha';

  @override
  String get correctionNotesTitle => 'Mapendekezo';

  @override
  String get correctionOutputHint =>
      'Masahihisho na mapendekezo yataonekana hapa';

  @override
  String correctionModeInfo(String language) {
    return 'Maandishi ya $language husahihishwa na kuboreshwa badala ya kutafsiriwa. Maneno uliyoandika kwa lugha nyingine hubadilishwa na neno sahihi la $language.';
  }

  @override
  String get historyBadgeCorrection => 'Sahihisho';

  @override
  String get stateOn => 'imewashwa';

  @override
  String get stateOff => 'imezimwa';

  @override
  String get backupSection => 'Nakala rudufu';

  @override
  String get backupExportButton => 'Hifadhi nakala';

  @override
  String get backupImportButton => 'Rejesha nakala';

  @override
  String get backupExplain =>
      'Huandika mipangilio na historia ya tafsiri kwenye faili. Iweke nje ya programu — data ya programu hufutwa unapoiondoa.';

  @override
  String get backupIncludeKeys => 'Jumuisha funguo za API';

  @override
  String get backupIncludeKeysWarning =>
      'Funguo huhifadhiwa bila usimbaji kwenye faili. Fanya hivi tu ikiwa utaiweka faili mahali salama.';

  @override
  String get backupImportConfirmTitle => 'Rejesha nakala?';

  @override
  String get backupImportConfirmMessage =>
      'Mipangilio yako ya sasa itabadilishwa na ile ya faili. Tafsiri kutoka kwenye nakala zitaongezwa kwenye historia; zilizopo zitabaki.';

  @override
  String get backupImportConfirmButton => 'Rejesha';

  @override
  String get backupExported => 'Nakala imehifadhiwa';

  @override
  String get backupExportedWithKeys =>
      'Nakala imehifadhiwa — ina funguo zako za API';

  @override
  String backupImported(int added, int skipped) {
    return 'Tafsiri $added zimerejeshwa, $skipped zilikuwepo tayari';
  }

  @override
  String get backupImportedKeys => 'Funguo za API pia zimerejeshwa';

  @override
  String get backupErrorNotBackup => 'Faili hiyo si nakala rudufu ya Tafsiri.';

  @override
  String get backupErrorUnreadable => 'Faili haikuweza kusomwa.';

  @override
  String get backupErrorTooNew =>
      'Nakala hii iliandikwa na toleo jipya zaidi la Tafsiri.';

  @override
  String get backupErrorFailed => 'Kuhifadhi nakala kumeshindikana.';

  @override
  String get backupReplaceHistory => 'Badilisha historia';

  @override
  String get backupReplaceHistoryWarning =>
      'Historia yako ya sasa ya tafsiri itafutwa na kubadilishwa na ile ya faili, badala ya kuunganishwa.';

  @override
  String get backupImportConfirmMessageReplace =>
      'Mipangilio yako ya sasa itabadilishwa na ile ya faili, na historia yako yote ya tafsiri itafutwa na kubadilishwa na ile ya nakala. Hatua hii haiwezi kutenduliwa.';

  @override
  String backupImportedReplaced(int added) {
    return 'Historia imebadilishwa — tafsiri $added zimerejeshwa';
  }
}
