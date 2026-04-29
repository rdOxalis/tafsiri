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
}
