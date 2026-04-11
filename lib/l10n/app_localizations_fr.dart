// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Tafsiri';

  @override
  String get translateButton => 'Traduire';

  @override
  String get inputHint => 'Saisir le texte à traduire…';

  @override
  String get outputHint => 'La traduction apparaîtra ici';

  @override
  String get clearButton => 'Effacer';

  @override
  String get pasteButton => 'Coller';

  @override
  String get copyButton => 'Copier';

  @override
  String get microphoneButton => 'Saisie vocale';

  @override
  String get imageButton => 'Saisie par image';

  @override
  String get navTranslator => 'Traducteur';

  @override
  String get navHistory => 'Historique';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get historyTitle => 'Historique';

  @override
  String get historyEmpty => 'Aucune traduction pour l\'instant';

  @override
  String get historyReloadTitle => 'Charger la traduction';

  @override
  String get historyReloadMessage => 'Recharger ce texte dans le traducteur ?';

  @override
  String get historyReloadConfirm => 'Charger';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get undoDelete => 'Annuler';

  @override
  String get favouritesLabel => 'Favoris';

  @override
  String get allLabel => 'Tout';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get apiKeyMistral => 'Clé API Mistral';

  @override
  String get apiKeyClaude => 'Clé API Claude';

  @override
  String get apiKeyOpenAI => 'Clé API OpenAI';

  @override
  String get providerLabel => 'Fournisseur IA';

  @override
  String get targetLanguageLabel => 'Langue cible';

  @override
  String get altLanguageLabel => 'Langue alternative';

  @override
  String get appLanguageLabel => 'Langue de l\'application';

  @override
  String get warningNoApiKey =>
      'Aucune clé API définie pour le fournisseur actif. Veuillez l\'ajouter ci-dessous.';

  @override
  String get donateButton => 'Offrez-moi un café';

  @override
  String get errorNoApiKey =>
      'Aucune clé API définie. Veuillez l\'ajouter dans les Paramètres.';

  @override
  String get errorApiError => 'Échec de la traduction. Veuillez réessayer.';

  @override
  String get errorNetwork =>
      'Pas de connexion. Veuillez vérifier votre internet.';

  @override
  String get errorOcrFailed => 'Impossible d\'extraire le texte de l\'image.';

  @override
  String get errorSttUnavailable =>
      'La saisie vocale n\'est pas disponible sur cet appareil.';

  @override
  String get providerMistral => 'Mistral';

  @override
  String get providerClaude => 'Claude';

  @override
  String get providerOpenAI => 'ChatGPT';

  @override
  String get ocrSourceCamera => 'Appareil photo';

  @override
  String get ocrSourceGallery => 'Galerie';

  @override
  String get sttLanguageLabel => 'Langue de la saisie vocale';

  @override
  String get sttLanguageAuto => 'Auto (de la dernière traduction)';
}
