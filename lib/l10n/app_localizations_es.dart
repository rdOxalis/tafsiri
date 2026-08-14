// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Tafsiri';

  @override
  String get translateButton => 'Traducir';

  @override
  String get inputHint => 'Introduce el texto a traducir…';

  @override
  String get outputHint => 'La traducción aparecerá aquí';

  @override
  String get clearButton => 'Borrar';

  @override
  String get pasteButton => 'Pegar';

  @override
  String get copyButton => 'Copiar';

  @override
  String get microphoneButton => 'Entrada de voz';

  @override
  String get imageButton => 'Entrada de imagen';

  @override
  String get navTranslator => 'Traductor';

  @override
  String get navHistory => 'Historial';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get historyTitle => 'Historial';

  @override
  String get historyEmpty => 'Aún no hay traducciones';

  @override
  String get historyReloadTitle => 'Cargar traducción';

  @override
  String get historyReloadMessage => '¿Cargar este texto en el traductor?';

  @override
  String get historyReloadConfirm => 'Cargar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get undoDelete => 'Deshacer';

  @override
  String get favouritesLabel => 'Favoritos';

  @override
  String get allLabel => 'Todos';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get apiKeyMistral => 'Clave API de Mistral';

  @override
  String get apiKeyClaude => 'Clave API de Claude';

  @override
  String get apiKeyOpenAI => 'Clave API de OpenAI';

  @override
  String get providerLabel => 'Proveedor de IA';

  @override
  String get providerSubtitle => 'trae tu propia clave API';

  @override
  String get targetLanguageLabel => 'Idioma principal';

  @override
  String get altLanguageLabel => 'Idioma secundario';

  @override
  String get appLanguageLabel => 'Idioma de la aplicación';

  @override
  String get warningNoApiKey =>
      'No hay clave API para el proveedor activo. Por favor, añádela a continuación.';

  @override
  String get donateButton => 'Invítame a un café';

  @override
  String get errorNoApiKey =>
      'No hay clave API. Por favor, añádela en Ajustes.';

  @override
  String get errorApiError =>
      'Error en la traducción. Por favor, inténtalo de nuevo.';

  @override
  String get errorNetwork => 'Sin conexión. Por favor, comprueba tu internet.';

  @override
  String get errorOcrFailed => 'No se pudo extraer el texto de la imagen.';

  @override
  String get errorOcrEngineMissing =>
      'El reconocimiento de texto no está instalado. Instala Tesseract para leer texto de las imágenes.';

  @override
  String get errorSttUnavailable =>
      'La entrada de voz no está disponible en este dispositivo.';

  @override
  String get providerMistral => 'Mistral';

  @override
  String get providerClaude => 'Claude';

  @override
  String get providerOpenAI => 'ChatGPT';

  @override
  String get ocrSourceCamera => 'Cámara';

  @override
  String get ocrSourceGallery => 'Galería';

  @override
  String get sttLanguageLabel => 'Reconocimiento de voz (Micrófono)';

  @override
  String get sttLanguageAuto => 'Auto (de la última traducción)';

  @override
  String get translationLanguagesSection => 'Idiomas de traducción';

  @override
  String get translationInfoTitle => 'Cómo funciona';

  @override
  String get translationInfoPart1 => 'El texto ingresado se traduce al ';

  @override
  String get translationInfoPart2 => '. Si el texto ya está en ';

  @override
  String get translationInfoPart3 => ', se traduce al ';

  @override
  String get translationInfoPart4 => '.';

  @override
  String get getApiKeyButton => 'Obtener clave API';

  @override
  String get mistralFreeHint =>
      'Mistral ofrece un nivel gratuito – sin tarjeta de crédito';

  @override
  String get correctionModeLabel => 'Modo corrección';

  @override
  String get correctionButton => 'Mejorar';

  @override
  String get correctionNotesTitle => 'Sugerencias';

  @override
  String get correctionOutputHint =>
      'Las correcciones y sugerencias aparecerán aquí';

  @override
  String correctionModeInfo(String language) {
    return 'El texto en $language se corrige y mejora en lugar de traducirse. Las palabras que escribiste en otro idioma se sustituyen por la palabra correcta en $language.';
  }

  @override
  String get historyBadgeCorrection => 'Corrección';

  @override
  String get stateOn => 'activado';

  @override
  String get stateOff => 'desactivado';

  @override
  String get backupSection => 'Copia de seguridad';

  @override
  String get backupExportButton => 'Guardar copia';

  @override
  String get backupImportButton => 'Restaurar copia';

  @override
  String get backupExplain =>
      'Escribe tus ajustes y el historial de traducciones en un archivo. Guárdalo fuera de la aplicación: los datos de la app se borran al desinstalarla.';

  @override
  String get backupIncludeKeys => 'Incluir claves de API';

  @override
  String get backupIncludeKeysWarning =>
      'Las claves se guardan sin cifrar en el archivo. Hazlo solo si lo guardas en un lugar seguro.';

  @override
  String get backupImportConfirmTitle => '¿Restaurar la copia?';

  @override
  String get backupImportConfirmMessage =>
      'Tus ajustes actuales se sustituirán por los del archivo. Las traducciones de la copia se añaden a tu historial; las existentes se conservan.';

  @override
  String get backupImportConfirmButton => 'Restaurar';

  @override
  String get backupExported => 'Copia guardada';

  @override
  String get backupExportedWithKeys =>
      'Copia guardada: contiene tus claves de API';

  @override
  String backupImported(int added, int skipped) {
    return '$added traducciones restauradas, $skipped ya presentes';
  }

  @override
  String get backupImportedKeys => 'Claves de API restauradas también';

  @override
  String get backupErrorNotBackup =>
      'Ese archivo no es una copia de seguridad de Tafsiri.';

  @override
  String get backupErrorUnreadable => 'No se pudo leer el archivo.';

  @override
  String get backupErrorTooNew =>
      'Esta copia se creó con una versión más reciente de Tafsiri.';

  @override
  String get backupErrorFailed => 'La copia de seguridad falló.';

  @override
  String get backupReplaceHistory => 'Reemplazar historial';

  @override
  String get backupReplaceHistoryWarning =>
      'Tu historial de traducciones actual se borra y se sustituye por el del archivo, en lugar de combinarlos.';

  @override
  String get backupImportConfirmMessageReplace =>
      'Tus ajustes actuales se sustituirán por los del archivo, y todo tu historial de traducciones se borrará y se sustituirá por el de la copia. Esto no se puede deshacer.';

  @override
  String backupImportedReplaced(int added) {
    return 'Historial reemplazado: $added traducciones restauradas';
  }
}
