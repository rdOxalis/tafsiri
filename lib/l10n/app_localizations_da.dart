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
  String get providerSubtitle => 'brug din egen API-nøgle';

  @override
  String get targetLanguageLabel => 'Primært sprog';

  @override
  String get altLanguageLabel => 'Sekundært sprog';

  @override
  String get targetLanguageInfo =>
      'Primært sprog — det sprog, du vil lære, eller som du er mindst god til.';

  @override
  String get altLanguageInfo =>
      'Sekundært sprog — det sprog, du taler godt, og som din tekst oversættes til, når du skriver på det primære sprog.';

  @override
  String get appLanguageLabel => 'App-sprog';

  @override
  String get warningNoApiKey =>
      'Ingen API-nøgle angivet for den aktive udbyder. Tilføj venligst din nøgle nedenfor.';

  @override
  String get donateButton => 'Køb mig en kop kaffe';

  @override
  String get aboutSection => 'Om';

  @override
  String get licensesButton => 'Open source-licenser';

  @override
  String get sourceCodeButton => 'Kildekode på GitHub';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

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
  String get errorOcrEngineMissing =>
      'Tekstgenkendelse er ikke installeret. Installer Tesseract for at læse tekst fra billeder.';

  @override
  String errorOcrLanguageMissing(String package) {
    return 'Tekstgenkendelsen mangler data for dette sprog. Installer: $package';
  }

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
  String get sttLanguageLabel => 'Talegenkendelse (Mikrofon)';

  @override
  String get sttLanguageAuto => 'Auto (fra seneste oversættelse)';

  @override
  String get translationLanguagesSection => 'Oversættelsessprog';

  @override
  String get translationInfoTitle => 'Sådan fungerer det';

  @override
  String get translationInfoPart1 => 'Indtastet tekst oversættes til ';

  @override
  String get translationInfoPart2 => '. Hvis teksten allerede er ';

  @override
  String get translationInfoPart3 => ', oversættes den til ';

  @override
  String get translationInfoPart4 => '.';

  @override
  String get getApiKeyButton => 'Hent API-nøgle';

  @override
  String get mistralFreeHint =>
      'Mistral tilbyder et gratis niveau – intet kreditkort kræves';

  @override
  String get correctionModeLabel => 'Rettelsestilstand';

  @override
  String get correctionButton => 'Forbedr';

  @override
  String get correctionNotesTitle => 'Forslag';

  @override
  String get correctionOutputHint => 'Rettelser og forslag vises her';

  @override
  String correctionModeInfo(String language) {
    return 'Tekst på $language bliver rettet og forbedret i stedet for oversat. Ord, du har skrevet på et andet sprog, erstattes med det rigtige ord på $language.';
  }

  @override
  String get historyBadgeCorrection => 'Rettelse';

  @override
  String get stateOn => 'til';

  @override
  String get stateOff => 'fra';

  @override
  String get backupSection => 'Sikkerhedskopi';

  @override
  String get backupExportButton => 'Gem sikkerhedskopi';

  @override
  String get backupImportButton => 'Gendan sikkerhedskopi';

  @override
  String get backupExplain =>
      'Skriver dine indstillinger og din oversættelseshistorik til en fil. Gem den uden for appen — appdata slettes, når du afinstallerer.';

  @override
  String get backupIncludeKeys => 'Tag API-nøgler med';

  @override
  String get backupIncludeKeysWarning =>
      'Nøglerne gemmes ukrypteret i filen. Gør det kun, hvis du opbevarer filen sikkert.';

  @override
  String get backupImportConfirmTitle => 'Gendan sikkerhedskopi?';

  @override
  String get backupImportConfirmMessage =>
      'Dine nuværende indstillinger erstattes af dem i filen. Oversættelser fra sikkerhedskopien føjes til din historik; eksisterende bevares.';

  @override
  String get backupImportConfirmButton => 'Gendan';

  @override
  String get backupExported => 'Sikkerhedskopi gemt';

  @override
  String get backupExportedWithKeys =>
      'Sikkerhedskopi gemt — den indeholder dine API-nøgler';

  @override
  String backupImported(int added, int skipped) {
    return '$added oversættelser gendannet, $skipped fandtes allerede';
  }

  @override
  String get backupImportedKeys => 'API-nøgler blev også gendannet';

  @override
  String get backupErrorNotBackup =>
      'Den fil er ikke en Tafsiri-sikkerhedskopi.';

  @override
  String get backupErrorUnreadable => 'Filen kunne ikke læses.';

  @override
  String get backupErrorTooNew =>
      'Denne sikkerhedskopi er skrevet af en nyere version af Tafsiri.';

  @override
  String get backupErrorFailed => 'Sikkerhedskopiering mislykkedes.';

  @override
  String get backupReplaceHistory => 'Erstat historik';

  @override
  String get backupReplaceHistoryWarning =>
      'Din nuværende oversættelseshistorik slettes og erstattes af den fra filen i stedet for at blive slået sammen.';

  @override
  String get backupImportConfirmMessageReplace =>
      'Dine nuværende indstillinger erstattes af dem i filen, og hele din oversættelseshistorik slettes og erstattes af sikkerhedskopiens. Det kan ikke fortrydes.';

  @override
  String backupImportedReplaced(int added) {
    return 'Historik erstattet — $added oversættelser gendannet';
  }

  @override
  String get outputStaleLabel => 'Passer ikke længere til teksten ovenfor';

  @override
  String get outputStaleTooltip =>
      'Teksten ovenfor er ændret — resultatet nedenfor stammer fra den forrige version.';
}
