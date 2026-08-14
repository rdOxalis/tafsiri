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
  String get providerSubtitle => 'apportez votre propre clé API';

  @override
  String get targetLanguageLabel => 'Langue principale';

  @override
  String get altLanguageLabel => 'Langue secondaire';

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
  String get errorOcrEngineMissing =>
      'La reconnaissance de texte n\'est pas installée. Installez Tesseract pour lire le texte des images.';

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
  String get sttLanguageLabel => 'Reconnaissance vocale (Microphone)';

  @override
  String get sttLanguageAuto => 'Auto (de la dernière traduction)';

  @override
  String get translationLanguagesSection => 'Langues de traduction';

  @override
  String get translationInfoTitle => 'Comment ça marche';

  @override
  String get translationInfoPart1 => 'Le texte saisi est traduit en ';

  @override
  String get translationInfoPart2 => '. S\'il est déjà en ';

  @override
  String get translationInfoPart3 => ', il est traduit en ';

  @override
  String get translationInfoPart4 => '.';

  @override
  String get getApiKeyButton => 'Obtenir la clé API';

  @override
  String get mistralFreeHint =>
      'Mistral propose un forfait gratuit – aucune carte bancaire requise';

  @override
  String get correctionModeLabel => 'Mode correction';

  @override
  String get correctionButton => 'Améliorer';

  @override
  String get correctionNotesTitle => 'Suggestions';

  @override
  String get correctionOutputHint =>
      'Les corrections et suggestions apparaîtront ici';

  @override
  String correctionModeInfo(String language) {
    return 'Le texte en $language est corrigé et amélioré au lieu d’être traduit. Les mots écrits dans une autre langue sont remplacés par le mot juste en $language.';
  }

  @override
  String get historyBadgeCorrection => 'Correction';

  @override
  String get stateOn => 'activé';

  @override
  String get stateOff => 'désactivé';

  @override
  String get backupSection => 'Sauvegarde';

  @override
  String get backupExportButton => 'Enregistrer la sauvegarde';

  @override
  String get backupImportButton => 'Restaurer la sauvegarde';

  @override
  String get backupExplain =>
      'Écrit vos réglages et votre historique de traduction dans un fichier. Conservez-le hors de l’application — les données de l’application sont supprimées à la désinstallation.';

  @override
  String get backupIncludeKeys => 'Inclure les clés API';

  @override
  String get backupIncludeKeysWarning =>
      'Les clés sont enregistrées en clair dans le fichier. À ne faire que si vous le conservez en lieu sûr.';

  @override
  String get backupImportConfirmTitle => 'Restaurer la sauvegarde ?';

  @override
  String get backupImportConfirmMessage =>
      'Vos réglages actuels seront remplacés par ceux du fichier. Les traductions de la sauvegarde s’ajoutent à votre historique ; les entrées existantes sont conservées.';

  @override
  String get backupImportConfirmButton => 'Restaurer';

  @override
  String get backupExported => 'Sauvegarde enregistrée';

  @override
  String get backupExportedWithKeys =>
      'Sauvegarde enregistrée — elle contient vos clés API';

  @override
  String backupImported(int added, int skipped) {
    return '$added traductions restaurées, $skipped déjà présentes';
  }

  @override
  String get backupImportedKeys => 'Clés API également restaurées';

  @override
  String get backupErrorNotBackup =>
      'Ce fichier n’est pas une sauvegarde Tafsiri.';

  @override
  String get backupErrorUnreadable => 'Le fichier n’a pas pu être lu.';

  @override
  String get backupErrorTooNew =>
      'Cette sauvegarde provient d’une version plus récente de Tafsiri.';

  @override
  String get backupErrorFailed => 'Échec de la sauvegarde.';

  @override
  String get backupReplaceHistory => 'Remplacer l’historique';

  @override
  String get backupReplaceHistoryWarning =>
      'Votre historique de traduction actuel est supprimé et remplacé par celui du fichier, au lieu d’être fusionné.';

  @override
  String get backupImportConfirmMessageReplace =>
      'Vos réglages actuels seront remplacés par ceux du fichier, et tout votre historique de traduction sera supprimé et remplacé par celui de la sauvegarde. Cette action est irréversible.';

  @override
  String backupImportedReplaced(int added) {
    return 'Historique remplacé — $added traductions restaurées';
  }
}
