// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Tafsiri';

  @override
  String get translateButton => 'Vertalen';

  @override
  String get inputHint => 'Voer te vertalen tekst in…';

  @override
  String get outputHint => 'Vertaling verschijnt hier';

  @override
  String get clearButton => 'Wissen';

  @override
  String get pasteButton => 'Plakken';

  @override
  String get copyButton => 'Kopiëren';

  @override
  String get microphoneButton => 'Spraakinvoer';

  @override
  String get imageButton => 'Afbeeldingsinvoer';

  @override
  String get navTranslator => 'Vertaler';

  @override
  String get navHistory => 'Geschiedenis';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get historyTitle => 'Geschiedenis';

  @override
  String get historyEmpty => 'Nog geen vertalingen';

  @override
  String get historyReloadTitle => 'Vertaling laden';

  @override
  String get historyReloadMessage => 'Deze tekst terugzetten in de vertaler?';

  @override
  String get historyReloadConfirm => 'Laden';

  @override
  String get cancel => 'Annuleren';

  @override
  String get delete => 'Verwijderen';

  @override
  String get undoDelete => 'Ongedaan maken';

  @override
  String get favouritesLabel => 'Favorieten';

  @override
  String get allLabel => 'Alles';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get apiKeyMistral => 'Mistral API-sleutel';

  @override
  String get apiKeyClaude => 'Claude API-sleutel';

  @override
  String get apiKeyOpenAI => 'OpenAI API-sleutel';

  @override
  String get providerLabel => 'AI-aanbieder';

  @override
  String get targetLanguageLabel => 'Doeltaal';

  @override
  String get altLanguageLabel => 'Alternatieve taal';

  @override
  String get appLanguageLabel => 'App-taal';

  @override
  String get warningNoApiKey =>
      'Geen API-sleutel ingesteld voor de actieve aanbieder. Voeg hieronder uw sleutel toe.';

  @override
  String get donateButton => 'Trakteer me op een koffie';

  @override
  String get errorNoApiKey =>
      'Geen API-sleutel ingesteld. Voeg uw sleutel toe in Instellingen.';

  @override
  String get errorApiError => 'Vertaling mislukt. Probeer het opnieuw.';

  @override
  String get errorNetwork => 'Geen verbinding. Controleer uw internet.';

  @override
  String get errorOcrFailed => 'Kon geen tekst uit de afbeelding halen.';

  @override
  String get errorSttUnavailable =>
      'Spraakinvoer is niet beschikbaar op dit apparaat.';

  @override
  String get providerMistral => 'Mistral';

  @override
  String get providerClaude => 'Claude';

  @override
  String get providerOpenAI => 'ChatGPT';

  @override
  String get ocrSourceCamera => 'Camera';

  @override
  String get ocrSourceGallery => 'Galerij';

  @override
  String get sttLanguageLabel => 'Taal voor spraakinvoer';

  @override
  String get sttLanguageAuto => 'Automatisch (van laatste vertaling)';
}
