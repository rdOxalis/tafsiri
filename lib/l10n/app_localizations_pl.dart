// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Tafsiri';

  @override
  String get translateButton => 'Przetłumacz';

  @override
  String get inputHint => 'Wprowadź tekst do tłumaczenia…';

  @override
  String get outputHint => 'Tłumaczenie pojawi się tutaj';

  @override
  String get clearButton => 'Wyczyść';

  @override
  String get pasteButton => 'Wklej';

  @override
  String get copyButton => 'Kopiuj';

  @override
  String get microphoneButton => 'Wprowadzanie głosowe';

  @override
  String get imageButton => 'Wprowadzanie obrazu';

  @override
  String get navTranslator => 'Tłumacz';

  @override
  String get navHistory => 'Historia';

  @override
  String get navSettings => 'Ustawienia';

  @override
  String get historyTitle => 'Historia';

  @override
  String get historyEmpty => 'Brak tłumaczeń';

  @override
  String get historyReloadTitle => 'Wczytaj tłumaczenie';

  @override
  String get historyReloadMessage => 'Wczytać ten tekst do tłumacza?';

  @override
  String get historyReloadConfirm => 'Wczytaj';

  @override
  String get cancel => 'Anuluj';

  @override
  String get delete => 'Usuń';

  @override
  String get undoDelete => 'Cofnij';

  @override
  String get favouritesLabel => 'Ulubione';

  @override
  String get allLabel => 'Wszystkie';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get apiKeyMistral => 'Klucz API Mistral';

  @override
  String get apiKeyClaude => 'Klucz API Claude';

  @override
  String get apiKeyOpenAI => 'Klucz API OpenAI';

  @override
  String get providerLabel => 'Dostawca AI';

  @override
  String get providerSubtitle => 'użyj własnego klucza API';

  @override
  String get targetLanguageLabel => 'Język podstawowy';

  @override
  String get altLanguageLabel => 'Język dodatkowy';

  @override
  String get targetLanguageInfo =>
      'Język główny — język, którego chcesz się uczyć lub który znasz słabiej.';

  @override
  String get altLanguageInfo =>
      'Język pomocniczy — język, który znasz dobrze i na który tłumaczony jest tekst, gdy wpiszesz coś w języku głównym.';

  @override
  String get appLanguageLabel => 'Język aplikacji';

  @override
  String get warningNoApiKey =>
      'Brak klucza API dla aktywnego dostawcy. Dodaj swój klucz poniżej.';

  @override
  String get donateButton => 'Postaw mi kawę';

  @override
  String get aboutSection => 'Informacje';

  @override
  String get licensesButton => 'Licencje open source';

  @override
  String get sourceCodeButton => 'Kod źródłowy na GitHubie';

  @override
  String versionLabel(String version) {
    return 'Wersja $version';
  }

  @override
  String get errorNoApiKey =>
      'Brak klucza API. Dodaj swój klucz w Ustawieniach.';

  @override
  String get errorApiError => 'Tłumaczenie nie powiodło się. Spróbuj ponownie.';

  @override
  String get errorNetwork =>
      'Brak połączenia. Sprawdź swoje połączenie z internetem.';

  @override
  String get errorOcrFailed => 'Nie udało się wyodrębnić tekstu z obrazu.';

  @override
  String get errorOcrEngineMissing =>
      'Rozpoznawanie tekstu nie jest zainstalowane. Zainstaluj Tesseract, aby odczytywać tekst z obrazów.';

  @override
  String errorOcrLanguageMissing(String package) {
    return 'Rozpoznawanie tekstu nie ma danych dla tego języka. Zainstaluj: $package';
  }

  @override
  String get errorSttUnavailable =>
      'Wprowadzanie głosowe nie jest dostępne na tym urządzeniu.';

  @override
  String get providerMistral => 'Mistral';

  @override
  String get providerClaude => 'Claude';

  @override
  String get providerOpenAI => 'ChatGPT';

  @override
  String get ocrSourceCamera => 'Aparat';

  @override
  String get ocrSourceGallery => 'Galeria';

  @override
  String get sttLanguageLabel => 'Rozpoznawanie mowy (Mikrofon)';

  @override
  String get sttLanguageAuto => 'Auto (z ostatniego tłumaczenia)';

  @override
  String get translationLanguagesSection => 'Języki tłumaczenia';

  @override
  String get translationInfoTitle => 'Jak to działa';

  @override
  String get translationInfoPart1 => 'Wprowadzony tekst jest tłumaczony na ';

  @override
  String get translationInfoPart2 => '. Jeśli tekst jest już w języku ';

  @override
  String get translationInfoPart3 => ', zostanie przetłumaczony na ';

  @override
  String get translationInfoPart4 => '.';

  @override
  String get getApiKeyButton => 'Pobierz klucz API';

  @override
  String get mistralFreeHint =>
      'Mistral oferuje bezpłatny poziom – karta kredytowa nie jest wymagana';

  @override
  String get correctionModeLabel => 'Tryb korekty';

  @override
  String get correctionButton => 'Popraw';

  @override
  String get correctionNotesTitle => 'Sugestie';

  @override
  String get correctionOutputHint => 'Poprawki i sugestie pojawią się tutaj';

  @override
  String correctionModeInfo(String language) {
    return 'Tekst w języku $language jest poprawiany i ulepszany zamiast tłumaczony. Słowa napisane w innym języku są zastępowane właściwym słowem w języku $language.';
  }

  @override
  String get historyBadgeCorrection => 'Korekta';

  @override
  String get stateOn => 'wł.';

  @override
  String get stateOff => 'wył.';

  @override
  String get backupSection => 'Kopia zapasowa';

  @override
  String get backupExportButton => 'Zapisz kopię';

  @override
  String get backupImportButton => 'Przywróć kopię';

  @override
  String get backupExplain =>
      'Zapisuje ustawienia i historię tłumaczeń do pliku. Trzymaj go poza aplikacją — dane aplikacji znikają przy odinstalowaniu.';

  @override
  String get backupIncludeKeys => 'Dołącz klucze API';

  @override
  String get backupIncludeKeysWarning =>
      'Klucze są zapisywane w pliku bez szyfrowania. Rób to tylko, jeśli przechowujesz plik bezpiecznie.';

  @override
  String get backupImportConfirmTitle => 'Przywrócić kopię?';

  @override
  String get backupImportConfirmMessage =>
      'Bieżące ustawienia zostaną zastąpione tymi z pliku. Tłumaczenia z kopii zostaną dodane do historii; istniejące pozostaną.';

  @override
  String get backupImportConfirmButton => 'Przywróć';

  @override
  String get backupExported => 'Kopia zapisana';

  @override
  String get backupExportedWithKeys =>
      'Kopia zapisana — zawiera Twoje klucze API';

  @override
  String backupImported(int added, int skipped) {
    return 'Przywrócono $added tłumaczeń, $skipped już istniało';
  }

  @override
  String get backupImportedKeys => 'Klucze API również przywrócone';

  @override
  String get backupErrorNotBackup =>
      'Ten plik nie jest kopią zapasową Tafsiri.';

  @override
  String get backupErrorUnreadable => 'Nie udało się odczytać pliku.';

  @override
  String get backupErrorTooNew => 'Ta kopia pochodzi z nowszej wersji Tafsiri.';

  @override
  String get backupErrorFailed => 'Tworzenie kopii nie powiodło się.';

  @override
  String get backupReplaceHistory => 'Zastąp historię';

  @override
  String get backupReplaceHistoryWarning =>
      'Bieżąca historia tłumaczeń zostanie usunięta i zastąpiona tą z pliku, zamiast połączenia obu.';

  @override
  String get backupImportConfirmMessageReplace =>
      'Bieżące ustawienia zostaną zastąpione tymi z pliku, a cała historia tłumaczeń zostanie usunięta i zastąpiona tą z kopii. Tej operacji nie można cofnąć.';

  @override
  String backupImportedReplaced(int added) {
    return 'Historia zastąpiona — przywrócono $added tłumaczeń';
  }

  @override
  String get outputStaleLabel => 'Nie pasuje już do tekstu powyżej';

  @override
  String get outputStaleTooltip =>
      'Tekst powyżej został zmieniony — wynik poniżej pochodzi z poprzedniej wersji.';
}
