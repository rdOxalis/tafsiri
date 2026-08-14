/// Identifies the exact build the app was compiled from.
///
/// Exists to answer one question that keeps coming up on desktop: *is the
/// running app actually the code I just changed?* An installed bundle is a copy
/// — rebuilding the source does not touch it — so behaviour that contradicts
/// the source is far more often a stale binary than a bug.
///
/// Injected at build time by `install.sh` and `build_windows.ps1`:
///
/// ```
/// flutter build linux --release --dart-define=TAFSIRI_BUILD=4d02f63
/// ```
///
/// Empty when a build passes no define (a plain `flutter run`, for instance),
/// in which case the UI simply shows the version on its own.
const kBuildStamp = String.fromEnvironment('TAFSIRI_BUILD');

/// What to show under Settings: `1.0.10+10 · 4d02f63`, or just the version when
/// nothing was injected. A `-dirty` suffix means the working tree had
/// uncommitted changes when this was built.
String buildLabel({required String version, required String buildNumber}) {
  final full = buildNumber.isEmpty ? version : '$version+$buildNumber';
  return kBuildStamp.isEmpty ? full : '$full · $kBuildStamp';
}
