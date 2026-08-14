// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tafsiri';

  @override
  String get translateButton => 'Translate';

  @override
  String get inputHint => 'Enter text to translate…';

  @override
  String get outputHint => 'Translation will appear here';

  @override
  String get clearButton => 'Clear';

  @override
  String get pasteButton => 'Paste';

  @override
  String get copyButton => 'Copy';

  @override
  String get microphoneButton => 'Voice input';

  @override
  String get imageButton => 'Image input';

  @override
  String get navTranslator => 'Translator';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No translations yet';

  @override
  String get historyReloadTitle => 'Load translation';

  @override
  String get historyReloadMessage => 'Load this text back into the translator?';

  @override
  String get historyReloadConfirm => 'Load';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get undoDelete => 'Undo';

  @override
  String get favouritesLabel => 'Favourites';

  @override
  String get allLabel => 'All';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get apiKeyMistral => 'Mistral API Key';

  @override
  String get apiKeyClaude => 'Claude API Key';

  @override
  String get apiKeyOpenAI => 'OpenAI API Key';

  @override
  String get providerLabel => 'AI Provider';

  @override
  String get providerSubtitle => 'bring your own API-Key';

  @override
  String get targetLanguageLabel => 'Primary Language';

  @override
  String get altLanguageLabel => 'Secondary Language';

  @override
  String get appLanguageLabel => 'App Language';

  @override
  String get warningNoApiKey =>
      'No API key set for the active provider. Please add your key below.';

  @override
  String get donateButton => 'Buy me a coffee';

  @override
  String get errorNoApiKey =>
      'No API key set. Please add your key in Settings.';

  @override
  String get errorApiError => 'Translation failed. Please try again.';

  @override
  String get errorNetwork => 'No connection. Please check your internet.';

  @override
  String get errorOcrFailed => 'Could not extract text from image.';

  @override
  String get errorOcrEngineMissing =>
      'Text recognition is not installed. Install Tesseract to read text from images.';

  @override
  String get errorSttUnavailable =>
      'Voice input is not available on this device.';

  @override
  String get providerMistral => 'Mistral';

  @override
  String get providerClaude => 'Claude';

  @override
  String get providerOpenAI => 'ChatGPT';

  @override
  String get ocrSourceCamera => 'Camera';

  @override
  String get ocrSourceGallery => 'Gallery';

  @override
  String get sttLanguageLabel => 'Speech Recognition (Microphone)';

  @override
  String get sttLanguageAuto => 'Auto (from last translation)';

  @override
  String get translationLanguagesSection => 'Translation Languages';

  @override
  String get translationInfoTitle => 'How translation works';

  @override
  String get translationInfoPart1 => 'Text you enter is translated to ';

  @override
  String get translationInfoPart2 => '. If the text is already ';

  @override
  String get translationInfoPart3 => ', it is translated to ';

  @override
  String get translationInfoPart4 => '.';

  @override
  String get getApiKeyButton => 'Get API key';

  @override
  String get mistralFreeHint =>
      'Mistral offers a free tier — no credit card required';

  @override
  String get correctionModeLabel => 'Correction mode';

  @override
  String get correctionButton => 'Improve';

  @override
  String get correctionNotesTitle => 'Suggestions';

  @override
  String get correctionOutputHint =>
      'Corrections and suggestions will appear here';

  @override
  String correctionModeInfo(String language) {
    return 'Text in $language is corrected and improved instead of translated. Words you wrote in another language are replaced with the correct $language word.';
  }

  @override
  String get historyBadgeCorrection => 'Correction';

  @override
  String get stateOn => 'on';

  @override
  String get stateOff => 'off';

  @override
  String get backupSection => 'Backup';

  @override
  String get backupExportButton => 'Save backup';

  @override
  String get backupImportButton => 'Restore backup';

  @override
  String get backupExplain =>
      'Writes your settings and translation history to a file. Keep it somewhere outside the app — app data is deleted when you uninstall.';

  @override
  String get backupIncludeKeys => 'Include API keys';

  @override
  String get backupIncludeKeysWarning =>
      'The keys are stored unencrypted in the file. Only do this if you keep the file somewhere safe.';

  @override
  String get backupImportConfirmTitle => 'Restore backup?';

  @override
  String get backupImportConfirmMessage =>
      'Your current settings will be replaced by the ones in the file. Translations from the backup are added to your history; existing entries are kept.';

  @override
  String get backupImportConfirmButton => 'Restore';

  @override
  String get backupExported => 'Backup saved';

  @override
  String get backupExportedWithKeys =>
      'Backup saved — it contains your API keys';

  @override
  String backupImported(int added, int skipped) {
    return '$added translations restored, $skipped already present';
  }

  @override
  String get backupImportedKeys => 'API keys restored as well';

  @override
  String get backupErrorNotBackup => 'That file is not a Tafsiri backup.';

  @override
  String get backupErrorUnreadable => 'The file could not be read.';

  @override
  String get backupErrorTooNew =>
      'This backup was written by a newer version of Tafsiri.';

  @override
  String get backupErrorFailed => 'Backup failed.';

  @override
  String get backupReplaceHistory => 'Replace history';

  @override
  String get backupReplaceHistoryWarning =>
      'Your current translation history is deleted and replaced by the one from the file, instead of the two being merged.';

  @override
  String get backupImportConfirmMessageReplace =>
      'Your current settings will be replaced by the ones in the file, and your entire translation history will be deleted and replaced by the backup’s. This cannot be undone.';

  @override
  String backupImportedReplaced(int added) {
    return 'History replaced — $added translations restored';
  }
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class AppLocalizationsEnGb extends AppLocalizationsEn {
  AppLocalizationsEnGb() : super('en_GB');

  @override
  String get appTitle => 'Tafsiri';

  @override
  String get translateButton => 'Translate';

  @override
  String get inputHint => 'Enter text to translate…';

  @override
  String get outputHint => 'Translation will appear here';

  @override
  String get clearButton => 'Clear';

  @override
  String get pasteButton => 'Paste';

  @override
  String get copyButton => 'Copy';

  @override
  String get microphoneButton => 'Voice input';

  @override
  String get imageButton => 'Image input';

  @override
  String get navTranslator => 'Translator';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No translations yet';

  @override
  String get historyReloadTitle => 'Load translation';

  @override
  String get historyReloadMessage => 'Load this text back into the translator?';

  @override
  String get historyReloadConfirm => 'Load';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get undoDelete => 'Undo';

  @override
  String get favouritesLabel => 'Favourites';

  @override
  String get allLabel => 'All';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get apiKeyMistral => 'Mistral API Key';

  @override
  String get apiKeyClaude => 'Claude API Key';

  @override
  String get apiKeyOpenAI => 'OpenAI API Key';

  @override
  String get providerLabel => 'AI Provider';

  @override
  String get providerSubtitle => 'bring your own API-Key';

  @override
  String get targetLanguageLabel => 'Primary Language';

  @override
  String get altLanguageLabel => 'Secondary Language';

  @override
  String get appLanguageLabel => 'App Language';

  @override
  String get warningNoApiKey =>
      'No API key set for the active provider. Please add your key below.';

  @override
  String get donateButton => 'Buy me a coffee';

  @override
  String get errorNoApiKey =>
      'No API key set. Please add your key in Settings.';

  @override
  String get errorApiError => 'Translation failed. Please try again.';

  @override
  String get errorNetwork => 'No connection. Please check your internet.';

  @override
  String get errorOcrFailed => 'Could not extract text from image.';

  @override
  String get errorOcrEngineMissing =>
      'Text recognition is not installed. Install Tesseract to read text from images.';

  @override
  String get errorSttUnavailable =>
      'Voice input is not available on this device.';

  @override
  String get providerMistral => 'Mistral';

  @override
  String get providerClaude => 'Claude';

  @override
  String get providerOpenAI => 'ChatGPT';

  @override
  String get ocrSourceCamera => 'Camera';

  @override
  String get ocrSourceGallery => 'Gallery';

  @override
  String get sttLanguageLabel => 'Speech Recognition (Microphone)';

  @override
  String get sttLanguageAuto => 'Auto (from last translation)';

  @override
  String get translationLanguagesSection => 'Translation Languages';

  @override
  String get translationInfoTitle => 'How translation works';

  @override
  String get translationInfoPart1 => 'Text you enter is translated to ';

  @override
  String get translationInfoPart2 => '. If the text is already ';

  @override
  String get translationInfoPart3 => ', it is translated to ';

  @override
  String get translationInfoPart4 => '.';

  @override
  String get getApiKeyButton => 'Get API key';

  @override
  String get mistralFreeHint =>
      'Mistral offers a free tier — no credit card required';

  @override
  String get correctionModeLabel => 'Correction mode';

  @override
  String get correctionButton => 'Improve';

  @override
  String get correctionNotesTitle => 'Suggestions';

  @override
  String get correctionOutputHint =>
      'Corrections and suggestions will appear here';

  @override
  String correctionModeInfo(String language) {
    return 'Text in $language is corrected and improved instead of translated. Words you wrote in another language are replaced with the correct $language word.';
  }

  @override
  String get historyBadgeCorrection => 'Correction';

  @override
  String get stateOn => 'on';

  @override
  String get stateOff => 'off';

  @override
  String get backupSection => 'Backup';

  @override
  String get backupExportButton => 'Save backup';

  @override
  String get backupImportButton => 'Restore backup';

  @override
  String get backupExplain =>
      'Writes your settings and translation history to a file. Keep it somewhere outside the app — app data is deleted when you uninstall.';

  @override
  String get backupIncludeKeys => 'Include API keys';

  @override
  String get backupIncludeKeysWarning =>
      'The keys are stored unencrypted in the file. Only do this if you keep the file somewhere safe.';

  @override
  String get backupImportConfirmTitle => 'Restore backup?';

  @override
  String get backupImportConfirmMessage =>
      'Your current settings will be replaced by the ones in the file. Translations from the backup are added to your history; existing entries are kept.';

  @override
  String get backupImportConfirmButton => 'Restore';

  @override
  String get backupExported => 'Backup saved';

  @override
  String get backupExportedWithKeys =>
      'Backup saved — it contains your API keys';

  @override
  String backupImported(int added, int skipped) {
    return '$added translations restored, $skipped already present';
  }

  @override
  String get backupImportedKeys => 'API keys restored as well';

  @override
  String get backupErrorNotBackup => 'That file is not a Tafsiri backup.';

  @override
  String get backupErrorUnreadable => 'The file could not be read.';

  @override
  String get backupErrorTooNew =>
      'This backup was written by a newer version of Tafsiri.';

  @override
  String get backupErrorFailed => 'Backup failed.';

  @override
  String get backupReplaceHistory => 'Replace history';

  @override
  String get backupReplaceHistoryWarning =>
      'Your current translation history is deleted and replaced by the one from the file, instead of the two being merged.';

  @override
  String get backupImportConfirmMessageReplace =>
      'Your current settings will be replaced by the ones in the file, and your entire translation history will be deleted and replaced by the backup’s. This cannot be undone.';

  @override
  String backupImportedReplaced(int added) {
    return 'History replaced — $added translations restored';
  }
}
