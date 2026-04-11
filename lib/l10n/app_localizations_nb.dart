// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get appTitle => 'Tafsiri';

  @override
  String get translateButton => 'Oversett';

  @override
  String get inputHint => 'Skriv inn tekst som skal oversettes…';

  @override
  String get outputHint => 'Oversettelsen vises her';

  @override
  String get clearButton => 'Tøm';

  @override
  String get pasteButton => 'Lim inn';

  @override
  String get copyButton => 'Kopier';

  @override
  String get microphoneButton => 'Taleinntasting';

  @override
  String get imageButton => 'Bildeinntasting';

  @override
  String get navTranslator => 'Oversetter';

  @override
  String get navHistory => 'Historikk';

  @override
  String get navSettings => 'Innstillinger';

  @override
  String get historyTitle => 'Historikk';

  @override
  String get historyEmpty => 'Ingen oversettelser ennå';

  @override
  String get historyReloadTitle => 'Last inn oversettelse';

  @override
  String get historyReloadMessage => 'Laste inn denne teksten i oversetteren?';

  @override
  String get historyReloadConfirm => 'Last inn';

  @override
  String get cancel => 'Avbryt';

  @override
  String get delete => 'Slett';

  @override
  String get undoDelete => 'Angre';

  @override
  String get favouritesLabel => 'Favoritter';

  @override
  String get allLabel => 'Alle';

  @override
  String get settingsTitle => 'Innstillinger';

  @override
  String get apiKeyMistral => 'Mistral API-nøkkel';

  @override
  String get apiKeyClaude => 'Claude API-nøkkel';

  @override
  String get apiKeyOpenAI => 'OpenAI API-nøkkel';

  @override
  String get providerLabel => 'AI-leverandør';

  @override
  String get targetLanguageLabel => 'Målspråk';

  @override
  String get altLanguageLabel => 'Alternativt språk';

  @override
  String get appLanguageLabel => 'Appspråk';

  @override
  String get warningNoApiKey =>
      'Ingen API-nøkkel angitt for den aktive leverandøren. Legg til nøkkelen din nedenfor.';

  @override
  String get donateButton => 'Kjøp meg en kaffe';

  @override
  String get errorNoApiKey =>
      'Ingen API-nøkkel angitt. Legg til nøkkelen din i Innstillinger.';

  @override
  String get errorApiError => 'Oversettelse mislyktes. Prøv igjen.';

  @override
  String get errorNetwork =>
      'Ingen tilkobling. Kontroller internettilkoblingen din.';

  @override
  String get errorOcrFailed => 'Kunne ikke hente ut tekst fra bildet.';

  @override
  String get errorSttUnavailable =>
      'Taleinntasting er ikke tilgjengelig på denne enheten.';

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
  String get sttLanguageLabel => 'Taleinputspråk';

  @override
  String get sttLanguageAuto => 'Auto (fra siste oversettelse)';
}
