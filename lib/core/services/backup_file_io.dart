import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/foundation.dart';

/// Opens the platform's file dialogs for backup export/import (ADR-034).
///
/// The two plugins split by platform on purpose:
/// * `file_selector` cannot offer a save dialog on Android at all.
/// * `file_picker` shells out to `zenity`/`qarma` on Linux, which is not
///   installed by default (KDE ships `kdialog` instead), so its Linux path
///   fails on perfectly ordinary desktops.
///
/// So Linux gets `file_selector` (native GTK, no external binary) and Android
/// gets `file_picker` (Storage Access Framework). Both write outside the app
/// sandbox, which is the entire point — sandbox data dies with an uninstall.
class BackupFileIo {
  const BackupFileIo();

  static const _typeGroup = fs.XTypeGroup(
    label: 'Tafsiri backup',
    extensions: ['json'],
    mimeTypes: ['application/json'],
  );

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Writes [content] to a location the user picks.
  ///
  /// Returns the chosen path/URI, or `null` when the user cancelled.
  Future<String?> save({
    required String suggestedName,
    required String content,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(content));

    if (_isMobile) {
      // On Android the plugin writes the bytes itself through SAF; the
      // returned string is a content URI we must not touch.
      return FilePicker.saveFile(
        fileName: suggestedName,
        bytes: bytes,
      );
    }

    final location = await fs.getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: const [_typeGroup],
    );
    if (location == null) return null;

    // Desktop hands back a path only — writing is ours to do.
    await File(location.path).writeAsBytes(bytes, flush: true);
    return location.path;
  }

  /// Reads a file the user picks. Returns `null` when the user cancelled.
  Future<String?> open() async {
    if (_isMobile) {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      final file = result?.files.singleOrNull;
      if (file == null) return null;
      final bytes = file.bytes;
      if (bytes != null) return utf8.decode(bytes, allowMalformed: true);
      final path = file.path;
      if (path == null) return null;
      return File(path).readAsString();
    }

    final file = await fs.openFile(acceptedTypeGroups: const [_typeGroup]);
    if (file == null) return null;
    return file.readAsString();
  }
}
