// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Tafsiri';

  @override
  String get translateButton => 'Übersetzen';

  @override
  String get inputHint => 'Text zum Übersetzen eingeben…';

  @override
  String get outputHint => 'Übersetzung erscheint hier';

  @override
  String get clearButton => 'Löschen';

  @override
  String get pasteButton => 'Einfügen';

  @override
  String get copyButton => 'Kopieren';

  @override
  String get microphoneButton => 'Spracheingabe';

  @override
  String get imageButton => 'Bildeingabe';

  @override
  String get navTranslator => 'Übersetzer';

  @override
  String get navHistory => 'Verlauf';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get historyTitle => 'Verlauf';

  @override
  String get historyEmpty => 'Noch keine Übersetzungen';

  @override
  String get historyReloadTitle => 'Übersetzung laden';

  @override
  String get historyReloadMessage => 'Diesen Text in den Übersetzer laden?';

  @override
  String get historyReloadConfirm => 'Laden';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get undoDelete => 'Rückgängig';

  @override
  String get favouritesLabel => 'Favoriten';

  @override
  String get allLabel => 'Alle';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get apiKeyMistral => 'Mistral API-Schlüssel';

  @override
  String get apiKeyClaude => 'Claude API-Schlüssel';

  @override
  String get apiKeyOpenAI => 'OpenAI API-Schlüssel';

  @override
  String get providerLabel => 'KI-Anbieter';

  @override
  String get providerSubtitle => 'bring your own API-Key';

  @override
  String get targetLanguageLabel => 'Primärsprache';

  @override
  String get altLanguageLabel => 'Sekundärsprache';

  @override
  String get appLanguageLabel => 'App-Sprache';

  @override
  String get warningNoApiKey =>
      'Kein API-Schlüssel für den aktiven Anbieter hinterlegt. Bitte unten eintragen.';

  @override
  String get donateButton => 'Kauf mir einen Kaffee';

  @override
  String get errorNoApiKey =>
      'Kein API-Schlüssel hinterlegt. Bitte in den Einstellungen eintragen.';

  @override
  String get errorApiError =>
      'Übersetzung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get errorNetwork =>
      'Keine Verbindung. Bitte Internetverbindung prüfen.';

  @override
  String get errorOcrFailed =>
      'Text konnte nicht aus dem Bild extrahiert werden.';

  @override
  String get errorSttUnavailable =>
      'Spracheingabe ist auf diesem Gerät nicht verfügbar.';

  @override
  String get providerMistral => 'Mistral';

  @override
  String get providerClaude => 'Claude';

  @override
  String get providerOpenAI => 'ChatGPT';

  @override
  String get ocrSourceCamera => 'Kamera';

  @override
  String get ocrSourceGallery => 'Galerie';

  @override
  String get sttLanguageLabel => 'Spracherkennung (Mikrofon)';

  @override
  String get sttLanguageAuto => 'Automatisch (aus letzter Übersetzung)';

  @override
  String get translationLanguagesSection => 'Übersetzungssprachen';

  @override
  String get translationInfoTitle => 'Wie die Übersetzung funktioniert';

  @override
  String get translationInfoPart1 => 'Eingegebener Text wird nach ';

  @override
  String get translationInfoPart2 => ' übersetzt. Wenn der Text bereits ';

  @override
  String get translationInfoPart3 => ' ist, wird er nach ';

  @override
  String get translationInfoPart4 => ' übersetzt.';
}
