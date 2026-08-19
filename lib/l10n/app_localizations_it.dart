// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Tafsiri';

  @override
  String get translateButton => 'Traduci';

  @override
  String get inputHint => 'Inserisci il testo da tradurre…';

  @override
  String get outputHint => 'La traduzione apparirà qui';

  @override
  String get clearButton => 'Cancella';

  @override
  String get pasteButton => 'Incolla';

  @override
  String get copyButton => 'Copia';

  @override
  String get microphoneButton => 'Input vocale';

  @override
  String get imageButton => 'Input immagine';

  @override
  String get navTranslator => 'Traduttore';

  @override
  String get navHistory => 'Cronologia';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get historyTitle => 'Cronologia';

  @override
  String get historyEmpty => 'Nessuna traduzione';

  @override
  String get historyReloadTitle => 'Carica traduzione';

  @override
  String get historyReloadMessage =>
      'Caricare di nuovo questo testo nel traduttore?';

  @override
  String get historyReloadConfirm => 'Carica';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get undoDelete => 'Annulla';

  @override
  String get favouritesLabel => 'Preferiti';

  @override
  String get allLabel => 'Tutte';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get apiKeyMistral => 'Chiave API Mistral';

  @override
  String get apiKeyClaude => 'Chiave API Claude';

  @override
  String get apiKeyOpenAI => 'Chiave API OpenAI';

  @override
  String get providerLabel => 'Provider IA';

  @override
  String get providerSubtitle => 'usa la tua chiave API';

  @override
  String get targetLanguageLabel => 'Lingua principale';

  @override
  String get altLanguageLabel => 'Lingua secondaria';

  @override
  String get targetLanguageInfo =>
      'Lingua principale — la lingua che vuoi imparare o che padroneggi meno.';

  @override
  String get altLanguageInfo =>
      'Lingua secondaria — la lingua che parli bene e verso cui viene tradotto il testo quando scrivi nella lingua principale.';

  @override
  String get appLanguageLabel => 'Lingua dell’app';

  @override
  String get warningNoApiKey =>
      'Nessuna chiave API impostata per il provider attivo. Inseriscila qui sotto.';

  @override
  String get donateButton => 'Offrimi un caffè';

  @override
  String get aboutSection => 'Informazioni';

  @override
  String get licensesButton => 'Licenze open source';

  @override
  String get sourceCodeButton => 'Codice sorgente su GitHub';

  @override
  String versionLabel(String version) {
    return 'Versione $version';
  }

  @override
  String get errorNoApiKey =>
      'Nessuna chiave API impostata. Inseriscila nelle impostazioni.';

  @override
  String get errorApiError => 'Traduzione non riuscita. Riprova.';

  @override
  String get errorNetwork => 'Nessuna connessione. Controlla la tua rete.';

  @override
  String get errorOcrFailed => 'Impossibile estrarre il testo dall’immagine.';

  @override
  String get errorOcrEngineMissing =>
      'Il riconoscimento del testo non è installato. Installa Tesseract per leggere il testo dalle immagini.';

  @override
  String errorOcrLanguageMissing(String package) {
    return 'Il riconoscimento del testo non ha i dati per questa lingua. Installa: $package';
  }

  @override
  String get errorSttUnavailable =>
      'L’input vocale non è disponibile su questo dispositivo.';

  @override
  String get providerMistral => 'Mistral';

  @override
  String get providerClaude => 'Claude';

  @override
  String get providerOpenAI => 'ChatGPT';

  @override
  String get ocrSourceCamera => 'Fotocamera';

  @override
  String get ocrSourceGallery => 'Galleria';

  @override
  String get sttLanguageLabel => 'Riconoscimento vocale (microfono)';

  @override
  String get sttLanguageAuto => 'Automatico (dall’ultima traduzione)';

  @override
  String get translationLanguagesSection => 'Lingue di traduzione';

  @override
  String get translationInfoTitle => 'Come funziona la traduzione';

  @override
  String get translationInfoPart1 => 'Il testo inserito viene tradotto in ';

  @override
  String get translationInfoPart2 => '. Se il testo è già in ';

  @override
  String get translationInfoPart3 => ', viene tradotto in ';

  @override
  String get translationInfoPart4 => '.';

  @override
  String get getApiKeyButton => 'Ottieni chiave API';

  @override
  String get mistralFreeHint =>
      'Mistral offre un piano gratuito — senza carta di credito';

  @override
  String get correctionModeLabel => 'Modalità correzione';

  @override
  String get correctionButton => 'Migliora';

  @override
  String get correctionNotesTitle => 'Suggerimenti';

  @override
  String get correctionOutputHint =>
      'Correzioni e suggerimenti appariranno qui';

  @override
  String correctionModeInfo(String language) {
    return 'Il testo in $language viene corretto e migliorato invece che tradotto. Le parole scritte in un’altra lingua vengono sostituite con la parola corretta in $language.';
  }

  @override
  String get historyBadgeCorrection => 'Correzione';

  @override
  String get stateOn => 'attiva';

  @override
  String get stateOff => 'disattiva';

  @override
  String get backupSection => 'Backup';

  @override
  String get backupExportButton => 'Salva backup';

  @override
  String get backupImportButton => 'Ripristina backup';

  @override
  String get backupExplain =>
      'Salva le impostazioni e la cronologia delle traduzioni in un file. Conservalo fuori dall’app — i dati dell’app vengono eliminati con la disinstallazione.';

  @override
  String get backupIncludeKeys => 'Includi le chiavi API';

  @override
  String get backupIncludeKeysWarning =>
      'Le chiavi vengono salvate nel file senza cifratura. Fallo solo se conservi il file in un luogo sicuro.';

  @override
  String get backupImportConfirmTitle => 'Ripristinare il backup?';

  @override
  String get backupImportConfirmMessage =>
      'Le impostazioni attuali verranno sostituite da quelle del file. Le traduzioni del backup vengono aggiunte alla cronologia; le voci esistenti restano.';

  @override
  String get backupImportConfirmButton => 'Ripristina';

  @override
  String get backupExported => 'Backup salvato';

  @override
  String get backupExportedWithKeys =>
      'Backup salvato — contiene le tue chiavi API';

  @override
  String backupImported(int added, int skipped) {
    return '$added traduzioni ripristinate, $skipped già presenti';
  }

  @override
  String get backupImportedKeys => 'Ripristinate anche le chiavi API';

  @override
  String get backupErrorNotBackup => 'Questo file non è un backup di Tafsiri.';

  @override
  String get backupErrorUnreadable => 'Impossibile leggere il file.';

  @override
  String get backupErrorTooNew =>
      'Questo backup è stato creato da una versione più recente di Tafsiri.';

  @override
  String get backupErrorFailed => 'Backup non riuscito.';

  @override
  String get backupReplaceHistory => 'Sostituisci la cronologia';

  @override
  String get backupReplaceHistoryWarning =>
      'La cronologia attuale viene eliminata e sostituita da quella del file, invece di unire le due.';

  @override
  String get backupImportConfirmMessageReplace =>
      'Le impostazioni attuali verranno sostituite da quelle del file e l’intera cronologia delle traduzioni verrà eliminata e sostituita da quella del backup. L’operazione non può essere annullata.';

  @override
  String backupImportedReplaced(int added) {
    return 'Cronologia sostituita — $added traduzioni ripristinate';
  }

  @override
  String get outputStaleLabel => 'Non corrisponde più al testo qui sopra';

  @override
  String get outputStaleTooltip =>
      'Il testo qui sopra è cambiato — il risultato qui sotto è della versione precedente.';
}
