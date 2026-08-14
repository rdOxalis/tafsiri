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
  String get providerSubtitle => 'bruk din egen API-nøkkel';

  @override
  String get targetLanguageLabel => 'Primærspråk';

  @override
  String get altLanguageLabel => 'Sekundærspråk';

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
  String get errorOcrEngineMissing =>
      'Tekstgjenkjenning er ikke installert. Installer Tesseract for å lese tekst fra bilder.';

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
  String get sttLanguageLabel => 'Talegjenkjenning (Mikrofon)';

  @override
  String get sttLanguageAuto => 'Auto (fra siste oversettelse)';

  @override
  String get translationLanguagesSection => 'Oversettingsspråk';

  @override
  String get translationInfoTitle => 'Slik fungerer det';

  @override
  String get translationInfoPart1 => 'Innskrevet tekst oversettes til ';

  @override
  String get translationInfoPart2 => '. Hvis teksten allerede er ';

  @override
  String get translationInfoPart3 => ', oversettes den til ';

  @override
  String get translationInfoPart4 => '.';

  @override
  String get getApiKeyButton => 'Hent API-nøkkel';

  @override
  String get mistralFreeHint =>
      'Mistral tilbyr et gratis nivå – intet kredittkort nødvendig';

  @override
  String get correctionModeLabel => 'Korrekturmodus';

  @override
  String get correctionButton => 'Forbedre';

  @override
  String get correctionNotesTitle => 'Forslag';

  @override
  String get correctionOutputHint => 'Rettelser og forslag vises her';

  @override
  String correctionModeInfo(String language) {
    return 'Tekst på $language blir rettet og forbedret i stedet for oversatt. Ord du har skrevet på et annet språk, erstattes med det riktige ordet på $language.';
  }

  @override
  String get historyBadgeCorrection => 'Retting';

  @override
  String get stateOn => 'på';

  @override
  String get stateOff => 'av';

  @override
  String get backupSection => 'Sikkerhetskopi';

  @override
  String get backupExportButton => 'Lagre sikkerhetskopi';

  @override
  String get backupImportButton => 'Gjenopprett sikkerhetskopi';

  @override
  String get backupExplain =>
      'Skriver innstillingene og oversettelsesloggen til en fil. Oppbevar den utenfor appen — appdata slettes når du avinstallerer.';

  @override
  String get backupIncludeKeys => 'Ta med API-nøkler';

  @override
  String get backupIncludeKeysWarning =>
      'Nøklene lagres ukryptert i filen. Gjør dette bare hvis du oppbevarer filen trygt.';

  @override
  String get backupImportConfirmTitle => 'Gjenopprette sikkerhetskopi?';

  @override
  String get backupImportConfirmMessage =>
      'Dine nåværende innstillinger erstattes av dem i filen. Oversettelser fra sikkerhetskopien legges til loggen; eksisterende beholdes.';

  @override
  String get backupImportConfirmButton => 'Gjenopprett';

  @override
  String get backupExported => 'Sikkerhetskopi lagret';

  @override
  String get backupExportedWithKeys =>
      'Sikkerhetskopi lagret — den inneholder API-nøklene dine';

  @override
  String backupImported(int added, int skipped) {
    return '$added oversettelser gjenopprettet, $skipped fantes allerede';
  }

  @override
  String get backupImportedKeys => 'API-nøkler ble også gjenopprettet';

  @override
  String get backupErrorNotBackup =>
      'Den filen er ikke en Tafsiri-sikkerhetskopi.';

  @override
  String get backupErrorUnreadable => 'Filen kunne ikke leses.';

  @override
  String get backupErrorTooNew =>
      'Denne sikkerhetskopien er skrevet av en nyere versjon av Tafsiri.';

  @override
  String get backupErrorFailed => 'Sikkerhetskopiering mislyktes.';

  @override
  String get backupReplaceHistory => 'Erstatt logg';

  @override
  String get backupReplaceHistoryWarning =>
      'Din nåværende oversettelseslogg slettes og erstattes av den fra filen, i stedet for å slås sammen.';

  @override
  String get backupImportConfirmMessageReplace =>
      'Dine nåværende innstillinger erstattes av dem i filen, og hele oversettelsesloggen slettes og erstattes av sikkerhetskopiens. Dette kan ikke angres.';

  @override
  String backupImportedReplaced(int added) {
    return 'Logg erstattet — $added oversettelser gjenopprettet';
  }
}
