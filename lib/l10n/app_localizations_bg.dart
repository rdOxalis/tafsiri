// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get appTitle => 'Tafsiri';

  @override
  String get translateButton => 'Преведи';

  @override
  String get inputHint => 'Въведете текст за превод…';

  @override
  String get outputHint => 'Преводът ще се появи тук';

  @override
  String get clearButton => 'Изчисти';

  @override
  String get pasteButton => 'Постави';

  @override
  String get copyButton => 'Копирай';

  @override
  String get microphoneButton => 'Гласов вход';

  @override
  String get imageButton => 'Изображение';

  @override
  String get navTranslator => 'Преводач';

  @override
  String get navHistory => 'История';

  @override
  String get navSettings => 'Настройки';

  @override
  String get historyTitle => 'История';

  @override
  String get historyEmpty => 'Все още няма преводи';

  @override
  String get historyReloadTitle => 'Зареждане на превод';

  @override
  String get historyReloadMessage =>
      'Да се зареди ли този текст обратно в преводача?';

  @override
  String get historyReloadConfirm => 'Зареди';

  @override
  String get cancel => 'Отказ';

  @override
  String get delete => 'Изтрий';

  @override
  String get undoDelete => 'Отмени';

  @override
  String get favouritesLabel => 'Любими';

  @override
  String get allLabel => 'Всички';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get apiKeyMistral => 'API ключ за Mistral';

  @override
  String get apiKeyClaude => 'API ключ за Claude';

  @override
  String get apiKeyOpenAI => 'API ключ за OpenAI';

  @override
  String get providerLabel => 'Доставчик на ИИ';

  @override
  String get providerSubtitle => 'използвайте свой API ключ';

  @override
  String get targetLanguageLabel => 'Основен език';

  @override
  String get altLanguageLabel => 'Втори език';

  @override
  String get targetLanguageInfo =>
      'Основен език — езикът, който искаш да научиш или който владееш по-слабо.';

  @override
  String get altLanguageInfo =>
      'Втори език — езикът, който владееш добре и на който се превежда текстът, когато въведеш нещо на основния език.';

  @override
  String get appLanguageLabel => 'Език на приложението';

  @override
  String get warningNoApiKey =>
      'Няма зададен API ключ за активния доставчик. Моля, въведете го по-долу.';

  @override
  String get donateButton => 'Почерпете ме с кафе';

  @override
  String get aboutSection => 'Относно';

  @override
  String get licensesButton => 'Лицензи с отворен код';

  @override
  String get sourceCodeButton => 'Изходен код в GitHub';

  @override
  String versionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String get errorNoApiKey =>
      'Няма зададен API ключ. Моля, въведете го в настройките.';

  @override
  String get errorApiError => 'Преводът не бе успешен. Опитайте отново.';

  @override
  String get errorNetwork => 'Няма връзка. Проверете интернет връзката си.';

  @override
  String get errorOcrFailed =>
      'Текстът не можа да бъде извлечен от изображението.';

  @override
  String get errorOcrEngineMissing =>
      'Разпознаването на текст не е инсталирано. Инсталирайте Tesseract, за да четете текст от изображения.';

  @override
  String errorOcrLanguageMissing(String package) {
    return 'Разпознаването на текст няма данни за този език. Инсталирайте: $package';
  }

  @override
  String get errorSttUnavailable =>
      'Гласовият вход не е достъпен на това устройство.';

  @override
  String get providerMistral => 'Mistral';

  @override
  String get providerClaude => 'Claude';

  @override
  String get providerOpenAI => 'ChatGPT';

  @override
  String get ocrSourceCamera => 'Камера';

  @override
  String get ocrSourceGallery => 'Галерия';

  @override
  String get sttLanguageLabel => 'Разпознаване на реч (микрофон)';

  @override
  String get sttLanguageAuto => 'Автоматично (от последния превод)';

  @override
  String get translationLanguagesSection => 'Езици за превод';

  @override
  String get translationInfoTitle => 'Как работи преводът';

  @override
  String get translationInfoPart1 => 'Въведеният текст се превежда на ';

  @override
  String get translationInfoPart2 => '. Ако текстът вече е на ';

  @override
  String get translationInfoPart3 => ', той се превежда на ';

  @override
  String get translationInfoPart4 => '.';

  @override
  String get getApiKeyButton => 'Вземи API ключ';

  @override
  String get mistralFreeHint =>
      'Mistral предлага безплатен план — без кредитна карта';

  @override
  String get correctionModeLabel => 'Режим на корекция';

  @override
  String get correctionButton => 'Подобри';

  @override
  String get correctionNotesTitle => 'Предложения';

  @override
  String get correctionOutputHint =>
      'Корекциите и предложенията ще се появят тук';

  @override
  String correctionModeInfo(String language) {
    return 'Текст на $language се коригира и подобрява, вместо да се превежда. Думи, написани на друг език, се заменят с правилната дума на $language.';
  }

  @override
  String get historyBadgeCorrection => 'Корекция';

  @override
  String get stateOn => 'вкл.';

  @override
  String get stateOff => 'изкл.';

  @override
  String get backupSection => 'Резервно копие';

  @override
  String get backupExportButton => 'Запази резервно копие';

  @override
  String get backupImportButton => 'Възстанови от копие';

  @override
  String get backupExplain =>
      'Записва настройките и историята на преводите във файл. Пазете го извън приложението — данните на приложението се изтриват при деинсталиране.';

  @override
  String get backupIncludeKeys => 'Включи API ключовете';

  @override
  String get backupIncludeKeysWarning =>
      'Ключовете се записват във файла нешифровани. Правете го само ако пазите файла на сигурно място.';

  @override
  String get backupImportConfirmTitle => 'Възстановяване от копие?';

  @override
  String get backupImportConfirmMessage =>
      'Текущите настройки ще бъдат заменени с тези от файла. Преводите от копието се добавят към историята; съществуващите записи се запазват.';

  @override
  String get backupImportConfirmButton => 'Възстанови';

  @override
  String get backupExported => 'Резервното копие е запазено';

  @override
  String get backupExportedWithKeys =>
      'Резервното копие е запазено — съдържа вашите API ключове';

  @override
  String backupImported(int added, int skipped) {
    return '$added превода са възстановени, $skipped вече съществуват';
  }

  @override
  String get backupImportedKeys => 'API ключовете също са възстановени';

  @override
  String get backupErrorNotBackup =>
      'Този файл не е резервно копие на Tafsiri.';

  @override
  String get backupErrorUnreadable => 'Файлът не можа да бъде прочетен.';

  @override
  String get backupErrorTooNew =>
      'Това копие е създадено с по-нова версия на Tafsiri.';

  @override
  String get backupErrorFailed => 'Резервното копие не бе успешно.';

  @override
  String get backupReplaceHistory => 'Замени историята';

  @override
  String get backupReplaceHistoryWarning =>
      'Текущата история на преводите се изтрива и се заменя с тази от файла, вместо двете да се обединят.';

  @override
  String get backupImportConfirmMessageReplace =>
      'Текущите настройки ще бъдат заменени с тези от файла, а цялата история на преводите ще бъде изтрита и заменена с тази от копието. Това не може да бъде отменено.';

  @override
  String backupImportedReplaced(int added) {
    return 'Историята е заменена — $added превода са възстановени';
  }

  @override
  String get outputStaleLabel => 'Вече не съответства на текста по-горе';

  @override
  String get outputStaleTooltip =>
      'Текстът по-горе е променен — резултатът по-долу е от предишната версия.';
}
