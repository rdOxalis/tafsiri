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
  String get targetLanguageLabel => 'Język docelowy';

  @override
  String get altLanguageLabel => 'Język alternatywny';

  @override
  String get appLanguageLabel => 'Język aplikacji';

  @override
  String get warningNoApiKey =>
      'Brak klucza API dla aktywnego dostawcy. Dodaj swój klucz poniżej.';

  @override
  String get donateButton => 'Postaw mi kawę';

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
}
