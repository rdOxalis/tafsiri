import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('da'),
    Locale('de'),
    Locale('en'),
    Locale('en', 'GB'),
    Locale('es'),
    Locale('fr'),
    Locale('nb'),
    Locale('nl'),
    Locale('pl'),
    Locale('sv'),
    Locale('sw'),
  ];

  /// The name of the app
  ///
  /// In en_GB, this message translates to:
  /// **'Tafsiri'**
  String get appTitle;

  /// Label for the translate button
  ///
  /// In en_GB, this message translates to:
  /// **'Translate'**
  String get translateButton;

  /// Hint text in the input field
  ///
  /// In en_GB, this message translates to:
  /// **'Enter text to translate…'**
  String get inputHint;

  /// Placeholder text in the output area
  ///
  /// In en_GB, this message translates to:
  /// **'Translation will appear here'**
  String get outputHint;

  /// Tooltip/label for the clear input button
  ///
  /// In en_GB, this message translates to:
  /// **'Clear'**
  String get clearButton;

  /// Tooltip/label for the paste from clipboard button
  ///
  /// In en_GB, this message translates to:
  /// **'Paste'**
  String get pasteButton;

  /// Tooltip/label for the copy translation button
  ///
  /// In en_GB, this message translates to:
  /// **'Copy'**
  String get copyButton;

  /// Tooltip for the microphone/STT button
  ///
  /// In en_GB, this message translates to:
  /// **'Voice input'**
  String get microphoneButton;

  /// Tooltip for the image/OCR button
  ///
  /// In en_GB, this message translates to:
  /// **'Image input'**
  String get imageButton;

  /// Bottom nav label for the translator screen
  ///
  /// In en_GB, this message translates to:
  /// **'Translator'**
  String get navTranslator;

  /// Bottom nav label for the history screen
  ///
  /// In en_GB, this message translates to:
  /// **'History'**
  String get navHistory;

  /// Bottom nav label for the settings screen
  ///
  /// In en_GB, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Title of the history screen
  ///
  /// In en_GB, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// Empty state message on the history screen
  ///
  /// In en_GB, this message translates to:
  /// **'No translations yet'**
  String get historyEmpty;

  /// Title of the reload-to-input confirmation dialog
  ///
  /// In en_GB, this message translates to:
  /// **'Load translation'**
  String get historyReloadTitle;

  /// Body of the reload-to-input confirmation dialog
  ///
  /// In en_GB, this message translates to:
  /// **'Load this text back into the translator?'**
  String get historyReloadMessage;

  /// Confirm button label in the reload dialog
  ///
  /// In en_GB, this message translates to:
  /// **'Load'**
  String get historyReloadConfirm;

  /// Generic cancel button label
  ///
  /// In en_GB, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic delete action label
  ///
  /// In en_GB, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Undo label in the delete snackbar
  ///
  /// In en_GB, this message translates to:
  /// **'Undo'**
  String get undoDelete;

  /// Label for the favourites filter
  ///
  /// In en_GB, this message translates to:
  /// **'Favourites'**
  String get favouritesLabel;

  /// Label for the 'all entries' filter
  ///
  /// In en_GB, this message translates to:
  /// **'All'**
  String get allLabel;

  /// Title of the settings screen
  ///
  /// In en_GB, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Label for the Mistral API key input field
  ///
  /// In en_GB, this message translates to:
  /// **'Mistral API Key'**
  String get apiKeyMistral;

  /// Label for the Claude API key input field
  ///
  /// In en_GB, this message translates to:
  /// **'Claude API Key'**
  String get apiKeyClaude;

  /// Label for the OpenAI API key input field
  ///
  /// In en_GB, this message translates to:
  /// **'OpenAI API Key'**
  String get apiKeyOpenAI;

  /// Label for the AI provider selector
  ///
  /// In en_GB, this message translates to:
  /// **'AI Provider'**
  String get providerLabel;

  /// Subtitle under the AI Provider section — intentionally not translated
  ///
  /// In en_GB, this message translates to:
  /// **'bring your own API-Key'**
  String get providerSubtitle;

  /// Label for the target language input field
  ///
  /// In en_GB, this message translates to:
  /// **'Primary Language'**
  String get targetLanguageLabel;

  /// Label for the alternative language input field
  ///
  /// In en_GB, this message translates to:
  /// **'Secondary Language'**
  String get altLanguageLabel;

  /// Label for the app UI language selector
  ///
  /// In en_GB, this message translates to:
  /// **'App Language'**
  String get appLanguageLabel;

  /// Warning banner shown when the active provider has no API key
  ///
  /// In en_GB, this message translates to:
  /// **'No API key set for the active provider. Please add your key below.'**
  String get warningNoApiKey;

  /// Label for the PayPal donate button in settings
  ///
  /// In en_GB, this message translates to:
  /// **'Buy me a coffee'**
  String get donateButton;

  /// Snackbar error when no API key is configured
  ///
  /// In en_GB, this message translates to:
  /// **'No API key set. Please add your key in Settings.'**
  String get errorNoApiKey;

  /// Error message shown when the API returns an error
  ///
  /// In en_GB, this message translates to:
  /// **'Translation failed. Please try again.'**
  String get errorApiError;

  /// Error message shown on network failure
  ///
  /// In en_GB, this message translates to:
  /// **'No connection. Please check your internet.'**
  String get errorNetwork;

  /// Error message shown when OCR fails
  ///
  /// In en_GB, this message translates to:
  /// **'Could not extract text from image.'**
  String get errorOcrFailed;

  /// Message shown when STT is not available
  ///
  /// In en_GB, this message translates to:
  /// **'Voice input is not available on this device.'**
  String get errorSttUnavailable;

  /// Display name for the Mistral provider
  ///
  /// In en_GB, this message translates to:
  /// **'Mistral'**
  String get providerMistral;

  /// Display name for the Claude provider
  ///
  /// In en_GB, this message translates to:
  /// **'Claude'**
  String get providerClaude;

  /// Display name for the OpenAI provider
  ///
  /// In en_GB, this message translates to:
  /// **'ChatGPT'**
  String get providerOpenAI;

  /// Bottom sheet option to pick image from camera
  ///
  /// In en_GB, this message translates to:
  /// **'Camera'**
  String get ocrSourceCamera;

  /// Bottom sheet option to pick image from gallery
  ///
  /// In en_GB, this message translates to:
  /// **'Gallery'**
  String get ocrSourceGallery;

  /// Label for the STT language selector in settings
  ///
  /// In en_GB, this message translates to:
  /// **'Speech Recognition (Microphone)'**
  String get sttLanguageLabel;

  /// Option in STT language selector meaning auto-detect
  ///
  /// In en_GB, this message translates to:
  /// **'Auto (from last translation)'**
  String get sttLanguageAuto;

  /// Section header for the translation languages group in settings
  ///
  /// In en_GB, this message translates to:
  /// **'Translation Languages'**
  String get translationLanguagesSection;

  /// Title of the translation logic info dialog
  ///
  /// In en_GB, this message translates to:
  /// **'How translation works'**
  String get translationInfoTitle;

  /// First text segment before the primary language name in the info dialog
  ///
  /// In en_GB, this message translates to:
  /// **'Text you enter is translated to '**
  String get translationInfoPart1;

  /// Second text segment between the two primary language occurrences
  ///
  /// In en_GB, this message translates to:
  /// **'. If the text is already '**
  String get translationInfoPart2;

  /// Third text segment before the secondary language name
  ///
  /// In en_GB, this message translates to:
  /// **', it is translated to '**
  String get translationInfoPart3;

  /// Final punctuation segment of the info dialog text
  ///
  /// In en_GB, this message translates to:
  /// **'.'**
  String get translationInfoPart4;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'da',
    'de',
    'en',
    'es',
    'fr',
    'nb',
    'nl',
    'pl',
    'sv',
    'sw',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'nb':
      return AppLocalizationsNb();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'sv':
      return AppLocalizationsSv();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
