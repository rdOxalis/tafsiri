import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

/// Desktop platforms ship no native sqflite implementation, so sqflite has to
/// be routed through the FFI factory backed by the system SQLite (ADR-031).
bool get needsSqfliteFfi =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// Candidate sonames for the system SQLite library on Linux, in load order.
///
/// `sqlite3` only tries the unversioned `libsqlite3.so`, which is provided by
/// the `libsqlite3-dev` package. End users only have the runtime package, which
/// ships the versioned soname — so fall back to that.
const _linuxSqliteNames = ['libsqlite3.so', 'libsqlite3.so.0'];

DynamicLibrary _openLinuxSqlite() {
  Object? lastError;
  for (final name in _linuxSqliteNames) {
    try {
      return DynamicLibrary.open(name);
    } catch (e) {
      lastError = e;
    }
  }
  throw StateError(
    'Could not load SQLite. Tried: ${_linuxSqliteNames.join(', ')}. '
    'Install the system SQLite library (e.g. "apt install libsqlite3-0"). '
    'Last error: $lastError',
  );
}

/// Candidate locations for `sqlite3.dll` on Windows, in load order.
///
/// Windows has no system SQLite, so the DLL ships next to the executable
/// (ADR-035). The bare name is tried last and would resolve through the normal
/// Windows search order; the repo-local copy that `windows/sqlite3.cmake`
/// downloads keeps `flutter test` working from a checkout, where the running
/// executable is the Dart VM rather than the app bundle.
Iterable<String> _windowsSqlitePaths() sync* {
  const dll = 'sqlite3.dll';

  final exeDir = Directory(Platform.resolvedExecutable).parent.path;
  yield '$exeDir\\$dll';

  final cached = Directory('windows\\third_party\\sqlite3');
  if (cached.existsSync()) {
    for (final entry in cached.listSync().whereType<Directory>()) {
      yield '${entry.path}\\$dll';
    }
  }

  yield dll;
}

DynamicLibrary _openWindowsSqlite() {
  final tried = <String>[];
  Object? lastError;
  for (final path in _windowsSqlitePaths()) {
    tried.add(path);
    try {
      return DynamicLibrary.open(path);
    } catch (e) {
      lastError = e;
    }
  }
  throw StateError(
    'Could not load SQLite. Tried: ${tried.join(', ')}. '
    'sqlite3.dll must sit next to tafsiri.exe — reinstall Tafsiri, or rebuild '
    'so windows/sqlite3.cmake can fetch it. Last error: $lastError',
  );
}

/// Teaches `sqlite3` how to find SQLite on the current *host* OS.
///
/// Must be a top-level function: `sqflite_common_ffi` runs it inside its worker
/// isolate, where loader overrides registered on the main isolate do not apply.
void useSystemSqlite() {
  if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, _openLinuxSqlite);
  } else if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, _openWindowsSqlite);
  }
}

/// FFI-backed factory that resolves SQLite via [useSystemSqlite].
DatabaseFactory createDesktopDatabaseFactory() =>
    createDatabaseFactoryFfi(ffiInit: useSystemSqlite);

/// Wires sqflite to the FFI factory on desktop. No-op on mobile and web.
///
/// Safe to call more than once, so tests can reuse it.
void initSqfliteForDesktop() {
  if (!needsSqfliteFfi) return;
  databaseFactory = createDesktopDatabaseFactory();
}
