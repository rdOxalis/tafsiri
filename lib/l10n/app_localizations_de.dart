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
  String get errorOcrEngineMissing =>
      'Texterkennung ist nicht installiert. Installiere Tesseract, um Text aus Bildern zu lesen.';

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

  @override
  String get getApiKeyButton => 'API-Key holen';

  @override
  String get mistralFreeHint =>
      'Mistral bietet einen kostenlosen Tarif – keine Kreditkarte nötig';

  @override
  String get correctionModeLabel => 'Korrekturmodus';

  @override
  String get correctionButton => 'Verbessern';

  @override
  String get correctionNotesTitle => 'Vorschläge';

  @override
  String get correctionOutputHint =>
      'Korrekturen und Vorschläge erscheinen hier';

  @override
  String correctionModeInfo(String language) {
    return 'Text auf $language wird korrigiert und verbessert statt übersetzt. Wörter, die du in einer anderen Sprache geschrieben hast, werden durch das richtige Wort auf $language ersetzt.';
  }

  @override
  String get historyBadgeCorrection => 'Korrektur';

  @override
  String get stateOn => 'an';

  @override
  String get stateOff => 'aus';

  @override
  String get backupSection => 'Sicherung';

  @override
  String get backupExportButton => 'Sicherung speichern';

  @override
  String get backupImportButton => 'Sicherung einlesen';

  @override
  String get backupExplain =>
      'Schreibt Einstellungen und Übersetzungsverlauf in eine Datei. Bewahre sie außerhalb der App auf — App-Daten werden beim Deinstallieren gelöscht.';

  @override
  String get backupIncludeKeys => 'API-Schlüssel mitsichern';

  @override
  String get backupIncludeKeysWarning =>
      'Die Schlüssel stehen unverschlüsselt in der Datei. Nur machen, wenn du die Datei sicher aufbewahrst.';

  @override
  String get backupImportConfirmTitle => 'Sicherung einlesen?';

  @override
  String get backupImportConfirmMessage =>
      'Deine aktuellen Einstellungen werden durch die aus der Datei ersetzt. Übersetzungen aus der Sicherung kommen zum Verlauf hinzu, vorhandene bleiben erhalten.';

  @override
  String get backupImportConfirmButton => 'Einlesen';

  @override
  String get backupExported => 'Sicherung gespeichert';

  @override
  String get backupExportedWithKeys =>
      'Sicherung gespeichert — sie enthält deine API-Schlüssel';

  @override
  String backupImported(int added, int skipped) {
    return '$added Übersetzungen wiederhergestellt, $skipped bereits vorhanden';
  }

  @override
  String get backupImportedKeys => 'API-Schlüssel ebenfalls wiederhergestellt';

  @override
  String get backupErrorNotBackup => 'Diese Datei ist keine Tafsiri-Sicherung.';

  @override
  String get backupErrorUnreadable => 'Die Datei konnte nicht gelesen werden.';

  @override
  String get backupErrorTooNew =>
      'Diese Sicherung stammt aus einer neueren Tafsiri-Version.';

  @override
  String get backupErrorFailed => 'Sicherung fehlgeschlagen.';

  @override
  String get backupReplaceHistory => 'Historie ersetzen';

  @override
  String get backupReplaceHistoryWarning =>
      'Dein aktueller Übersetzungsverlauf wird gelöscht und durch den aus der Datei ersetzt, statt beide zusammenzuführen.';

  @override
  String get backupImportConfirmMessageReplace =>
      'Deine aktuellen Einstellungen werden durch die aus der Datei ersetzt, und dein gesamter Übersetzungsverlauf wird gelöscht und durch den der Sicherung ersetzt. Das lässt sich nicht rückgängig machen.';

  @override
  String backupImportedReplaced(int added) {
    return 'Verlauf ersetzt — $added Übersetzungen wiederhergestellt';
  }
}
