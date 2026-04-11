// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'Tafsiri';

  @override
  String get translateButton => 'Oversæt';

  @override
  String get inputHint => 'Indtast tekst til oversættelse…';

  @override
  String get outputHint => 'Oversættelsen vises her';

  @override
  String get clearButton => 'Ryd';

  @override
  String get pasteButton => 'Indsæt';

  @override
  String get copyButton => 'Kopiér';

  @override
  String get microphoneButton => 'Taleindtastning';

  @override
  String get imageButton => 'Billedindtastning';

  @override
  String get navTranslator => 'Oversætter';

  @override
  String get navHistory => 'Historik';

  @override
  String get navSettings => 'Indstillinger';

  @override
  String get historyTitle => 'Historik';

  @override
  String get historyEmpty => 'Ingen oversættelser endnu';

  @override
  String get historyReloadTitle => 'Indlæs oversættelse';

  @override
  String get historyReloadMessage => 'Indlæs denne tekst i oversætteren?';

  @override
  String get historyReloadConfirm => 'Indlæs';

  @override
  String get cancel => 'Annuller';

  @override
  String get delete => 'Slet';

  @override
  String get undoDelete => 'Fortryd';

  @override
  String get favouritesLabel => 'Favoritter';

  @override
  String get allLabel => 'Alle';

  @override
  String get settingsTitle => 'Indstillinger';

  @override
  String get apiKeyMistral => 'Mistral API-nøgle';

  @override
  String get apiKeyClaude => 'Claude API-nøgle';

  @override
  String get apiKeyOpenAI => 'OpenAI API-nøgle';

  @override
  String get providerLabel => 'AI-udbyder';

  @override
  String get targetLanguageLabel => 'Målsprog';

  @override
  String get altLanguageLabel => 'Alternativt sprog';

  @override
  String get appLanguageLabel => 'App-sprog';

  @override
  String get warningNoApiKey =>
      'Ingen API-nøgle angivet for den aktive udbyder. Tilføj venligst din nøgle nedenfor.';

  @override
  String get donateButton => 'Køb mig en kop kaffe';

  @override
  String get errorNoApiKey =>
      'Ingen API-nøgle angivet. Tilføj din nøgle i Indstillinger.';

  @override
  String get errorApiError => 'Oversættelse mislykkedes. Prøv igen.';

  @override
  String get errorNetwork =>
      'Ingen forbindelse. Kontrollér venligst din internetforbindelse.';

  @override
  String get errorOcrFailed => 'Kunne ikke udtrække tekst fra billedet.';

  @override
  String get errorSttUnavailable =>
      'Taleindtastning er ikke tilgængelig på denne enhed.';

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
  String get sttLanguageLabel => 'Taleinputsprog';

  @override
  String get sttLanguageAuto => 'Auto (fra seneste oversættelse)';
}
