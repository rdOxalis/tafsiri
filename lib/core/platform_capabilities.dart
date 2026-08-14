import 'package:flutter/foundation.dart';

/// What the current platform can actually do, in one place.
///
/// These gate *widgets*, not just their enabled state: a control the platform
/// cannot support is worse than absent, because a disabled button reads as
/// "not right now" and invites the user to look for the setting that turns it
/// on. There is none.

/// True on the platforms the app treats as a handheld.
bool get isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// True where picking an image can lead anywhere. Desktop image pickers offer
/// file selection only, so the camera entry in the source sheet would be a
/// guaranteed dead end (ADR-037).
bool get hasCamera => isMobilePlatform;

/// True where voice input has an engine behind it at all.
///
/// Not the same as "mobile": `speech_to_text` declares Android, iOS, web,
/// macOS and Windows (that last through `speech_to_text_windows`, in beta).
/// **Linux is the only target with no implementation**, which is why it is the
/// only one where the button is hidden rather than merely disabled — everywhere
/// else `initialize()` failing means a permission or a beta gap, and both are
/// states the user can act on (ADR-039).
///
/// Deliberately `defaultTargetPlatform` rather than `dart:io`, so this file
/// stays importable from anywhere.
bool get hasSpeechInput =>
    kIsWeb || defaultTargetPlatform != TargetPlatform.linux;
