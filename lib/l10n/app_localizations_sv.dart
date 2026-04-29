// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Tafsiri';

  @override
  String get translateButton => 'Översätt';

  @override
  String get inputHint => 'Ange text att översätta…';

  @override
  String get outputHint => 'Översättningen visas här';

  @override
  String get clearButton => 'Rensa';

  @override
  String get pasteButton => 'Klistra in';

  @override
  String get copyButton => 'Kopiera';

  @override
  String get microphoneButton => 'Röstinmatning';

  @override
  String get imageButton => 'Bildinmatning';

  @override
  String get navTranslator => 'Översättare';

  @override
  String get navHistory => 'Historik';

  @override
  String get navSettings => 'Inställningar';

  @override
  String get historyTitle => 'Historik';

  @override
  String get historyEmpty => 'Inga översättningar ännu';

  @override
  String get historyReloadTitle => 'Läs in översättning';

  @override
  String get historyReloadMessage => 'Läsa in den här texten i översättaren?';

  @override
  String get historyReloadConfirm => 'Läs in';

  @override
  String get cancel => 'Avbryt';

  @override
  String get delete => 'Ta bort';

  @override
  String get undoDelete => 'Ångra';

  @override
  String get favouritesLabel => 'Favoriter';

  @override
  String get allLabel => 'Alla';

  @override
  String get settingsTitle => 'Inställningar';

  @override
  String get apiKeyMistral => 'Mistral API-nyckel';

  @override
  String get apiKeyClaude => 'Claude API-nyckel';

  @override
  String get apiKeyOpenAI => 'OpenAI API-nyckel';

  @override
  String get providerLabel => 'AI-leverantör';

  @override
  String get providerSubtitle => 'ta med din egen API-nyckel';

  @override
  String get targetLanguageLabel => 'Primärt språk';

  @override
  String get altLanguageLabel => 'Sekundärt språk';

  @override
  String get appLanguageLabel => 'Appspråk';

  @override
  String get warningNoApiKey =>
      'Ingen API-nyckel angiven för den aktiva leverantören. Lägg till din nyckel nedan.';

  @override
  String get donateButton => 'Bjud mig på ett kaffe';

  @override
  String get errorNoApiKey =>
      'Ingen API-nyckel angiven. Lägg till din nyckel i Inställningar.';

  @override
  String get errorApiError => 'Översättningen misslyckades. Försök igen.';

  @override
  String get errorNetwork =>
      'Ingen anslutning. Kontrollera din internetanslutning.';

  @override
  String get errorOcrFailed => 'Kunde inte extrahera text från bilden.';

  @override
  String get errorSttUnavailable =>
      'Röstinmatning är inte tillgänglig på den här enheten.';

  @override
  String get providerMistral => 'Mistral';

  @override
  String get providerClaude => 'Claude';

  @override
  String get providerOpenAI => 'ChatGPT';

  @override
  String get ocrSourceCamera => 'Kamera';

  @override
  String get ocrSourceGallery => 'Galleri';

  @override
  String get sttLanguageLabel => 'Taligenkänning (Mikrofon)';

  @override
  String get sttLanguageAuto => 'Auto (från senaste översättning)';

  @override
  String get translationLanguagesSection => 'Översättningsspråk';

  @override
  String get translationInfoTitle => 'Så här fungerar det';

  @override
  String get translationInfoPart1 => 'Inmatad text översätts till ';

  @override
  String get translationInfoPart2 => '. Om texten redan är ';

  @override
  String get translationInfoPart3 => ', översätts den till ';

  @override
  String get translationInfoPart4 => '.';
}
