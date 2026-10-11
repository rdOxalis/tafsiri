# F-Droid Release Process

> **⚠️ ABANDONED (2026-06-14, ADR-030) — partly reopened (2026-10-09, ADR-074).**
> Official F-Droid inclusion was given up because `check apk` rejected six
> `com.google.android.play.core.*` classes in a way that seemed impossible to
> reproduce locally. **That was wrong:** they were references in two Flutter
> classes kept alive by our own `-keep class io.flutter.**` rule, and F-Droid's
> scanner counts references. Fixed in `proguard-rules.pro`; check any APK with
> `tools/fdroid_scan.py` before submitting. ML Kit (wall 2) is the one blocker
> left.
>
> **Update (2026-10-11, ADR-075):** ML Kit is replaced by Tesseract built from
> source, so wall 2 is down as well. The recipe in `fdroid/metadata/` has been
> rebuilt for it: `submodules: true`, `ndk: r27c`, the Flutter version from
> `.flutter-version`, `TAFSIRI_UNSIGNED=1`, and `scandelete` for submodule files
> that are never built. A local build that applies the recipe exactly scans
> clean. Still to do before submitting: a real `fdroid build`.

## The recipe, line by line (1.0.21, ADR-075)

`fdroiddata` keeps no comments — `fdroid rewritemeta` strips them, and its CI
fails a merge request whose metadata is not in canonical form. So the reasons
live here, and `fdroid/metadata/com.njerahouse.tafsiri.yml` stays bare.

| Line | Why |
|---|---|
| `submodules: true` | Tesseract4Android is a submodule, built from source as a Gradle module. Its published AAR comes from JitPack, which F-Droid does not accept. |
| `sdkmanager 'cmake;3.22.1'` | The native build pins CMake 3.22.1, and the build server provisions no CMake at all (`buildserver/provision-android-sdk`). F-Droid's sdkmanager installs it where Gradle looks. |
| `flutterVersion=$(cat .flutter-version)` | The app pins its Flutter version in that file. The release workflow the old recipe read was deleted (ADR-042). |
| `scandelete`: `.pub-cache` and Leptonica's `prog` | The scanner flags binaries in both: test archives in pub packages, and the fuzzing ZIPs among Leptonica's utility programs, which CMake builds only under `BUILD_PROG` (default off). **Only paths the scanner would actually flag belong here** — F-Droid fails the build on an unused `scandelete` entry. The first local run listed three more (the submodule's Gradle wrapper, which the scanner removes by itself, and its sample app and instrumented tests, which hold only images and language data it does not object to) and failed on exactly that. |
| `export TAFSIRI_UNSIGNED=1` | F-Droid signs with its own key and wants the APK unsigned. An explicit switch in `build.gradle.kts`, checked first, rather than `sed`-ing the signing config out. |
| `--dart-define=TAFSIRI_BUILD=$(git rev-parse --short HEAD)` | The same commit stamp the app shows under Settings → About on every other channel (ADR-041). |
| `ndk: r27c` | The NDK Tesseract4Android 4.9.0 is tested with (27.2.12479018). `rewritemeta` puts this field after `build`. |
| `AntiFeatures: NonFreeNet` with a reason | The AI providers are non-free network services. Keep the localised reason map: current `fdroidserver` reads it (`TYPE_STRINGMAP`). The older 2.2.1 in Debian flattens it to a bare list on `rewritemeta`, so do not let a local rewrite "fix" it. |

**Before any submission:** `fdroid lint`, `fdroid rewritemeta --list` (only the
AntiFeatures difference above is acceptable with Debian's fdroidserver), a local
`fdroid build -l --scan-binary`, and `tools/fdroid_scan.py` on the result.

**`fdroid build` exits 0 even when the app failed to build.** Read the log for
`Could not build app` and `ERROR:` rather than trusting the exit code — the
first local run of 1.0.21 failed with three scan errors and still reported
success to the shell. MR #39249 was closed and OCR was restored (1.0.8). This
> document is kept for historical reference. For a FOSS-store presence that keeps
> ML Kit/OCR, use IzzyOnDroid (builds from GitHub release APKs), not this repo.
> Full story: [`docs/fdroid-postmortem.md`](fdroid-postmortem.md).

## How Auto-Updates Work

Once the app is merged into fdroiddata, new releases are picked up automatically:

1. Update `version` in `pubspec.yaml` (e.g. `1.1.0+6`)
2. Update Flutter version in `.github/workflows/release.yml` if changed
3. Commit and push
4. Create and push a new tag: `git tag v1.1.0 && git push origin v1.1.0`
5. F-Droid scans tags periodically, reads the version from `pubspec.yaml`, builds the APK

No manual fdroiddata edits needed for regular releases.

## What F-Droid Reads

- **Version name and code:** from `pubspec.yaml` (format: `name+code`, e.g. `1.0.5+5`)
- **App name:** from `AndroidManifest.xml` (`AutoName` field)
- **Build steps:** from `fdroid/metadata/com.njerahouse.tafsiri.yml`

## Checklist for a New Release

- [ ] Bump version in `pubspec.yaml` (format: `x.y.z+versionCode`)
- [ ] Update Flutter version in `.github/workflows/release.yml` if upgraded
- [ ] Add changelog entry in `fastlane/metadata/android/*/changelogs/<versionCode>.txt`
- [ ] Test APK build locally: `flutter build apk --release`
- [ ] Commit and push to `main`
- [ ] Tag and push: `git tag vX.Y.Z && git push origin main --tags`
- [ ] Wait for F-Droid to pick it up (can take a few days)

## If Something Breaks

F-Droid builds run on Debian Trixie with Java 21, and the buildserver uses a
**bleeding-edge toolchain (AGP 9 / Gradle 9)** because `fdroidserver` is fetched
from `master`. This activates the new Gradle DSL + built-in Kotlin, which an
unmigrated Flutter project (and old plugins like `google_mlkit_commons`) cannot
handle. Common issues:

| Problem | Fix |
|---------|-----|
| NPE configuring `:google_mlkit_commons` / "Failed to notify project evaluation listener" | Opt out of the new DSL **and** built-in Kotlin: set BOTH `android.newDsl=false` and `android.builtInKotlin=false` in `android/gradle.properties`. `newDsl` alone is not enough — it leaves a `kotlin-android` "extension already registered" failure. |
| `kotlin-android` "Cannot add extension with name 'kotlin'" | Add `android.builtInKotlin=false`. |
| Gradle/Java incompatibility | Upgrade Gradle + AGP in `android/` |
| JdkImageTransform/jlink error | AGP must be 8.3.0+ for Java 21 |
| Scanner finds binaries in .pub-cache | `scandelete: - .pub-cache` in YAML handles this |

**Debugging tip — reproduce locally instead of tag-and-pray.** Fetch the failed
job trace from the public GitLab API (no auth needed):
`curl -sL https://gitlab.com/ooocp/fdroiddata/-/jobs/<JOB_ID>/raw`. To reproduce
the AGP 9 environment locally, build with a full JDK 21, bump
`com.android.application` to `9.0.1` + the Gradle wrapper to `9.1.0`, and run
`flutter build apk --release`.

## Key Files

| File | Purpose |
|------|---------|
| `.github/workflows/release.yml` | Pinned Flutter version (for GitHub CI) |
| `pubspec.yaml` | App version (versionName+versionCode) |
| `android/settings.gradle.kts` | AGP, Kotlin, Gradle versions |
| `android/app/build.gradle.kts` | compileSdk, Java target, dependenciesInfo |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle distribution version |
| `fdroid/metadata/com.njerahouse.tafsiri.yml` | F-Droid build recipe |
| `fastlane/metadata/android/` | Store descriptions and changelogs |

## fdroiddata Submission

Repository: https://gitlab.com/fdroid/fdroiddata
Fork: https://gitlab.com/ooocp/fdroiddata
MR: https://gitlab.com/fdroid/fdroiddata/-/merge_requests/39249
Metadata file: `metadata/com.njerahouse.tafsiri.yml`

### Submission Steps

1. Clone the fork: `git clone --depth=1 https://gitlab.com/ooocp/fdroiddata ~/fdroiddata`
2. `cd ~/fdroiddata && git checkout -b com.njerahouse.tafsiri`
3. Copy `fdroid/metadata/com.njerahouse.tafsiri.yml` → `~/fdroiddata/metadata/`
4. Run `fdroid rewritemeta com.njerahouse.tafsiri` to normalize the YAML
5. Run `fdroid readmeta` to validate
6. Commit: `git add metadata/com.njerahouse.tafsiri.yml && git commit -m "New App: Tafsiri"`
7. Push and open MR at https://gitlab.com/fdroid/fdroiddata/-/merge_requests/new

### Lessons Learned (from BluesoundPlayer MR #34693)

- No quotes on `versionName` and `CurrentVersion` (rewritemeta normalizes)
- Use tag name in `commit:` field (e.g. `v1.0.5`) — rewritemeta may convert to hash
- Run `fdroid rewritemeta` before pushing — linter rejects non-canonical format
- Required fields: `AuthorName`, `AuthorWebSite`, `SourceCode`, `IssueTracker`
- Do NOT include `WebSite` if it equals `SourceCode` (auto-derived from GitHub)
  — actually keep it, rewritemeta will handle it
- `scandelete` paths are relative to the build root (repo root since no `subdir`)
- Java 17 in `build.gradle.kts` is required — F-Droid builds with Java 21, and
  `sourceCompatibility = JavaVersion.VERSION_11` is fine too but 17 is safer
- `dependenciesInfo { includeInApk = false; includeInBundle = false }` is mandatory
- **The `fdroid build` CI job must pass** — it is a real build. (An earlier note
  here wrongly claimed it "fails for Flutter apps (expected)"; that misconception
  cost several wasted submit-and-fail cycles. Only treat a red `fdroid build` as
  acceptable if you have independently confirmed the failure is environmental.)

### Anti-Features

Tafsiri has `NonFreeNet` because it connects to proprietary AI API services.
The user provides their own API key. The app itself is fully FOSS.

### Why there is no image-to-text (OCR) — removed in 1.0.6

ML Kit (`google_mlkit_text_recognition`) was **removed** because it pulls
proprietary `com.google.mlkit:*` artifacts from Google's Maven. F-Droid's
scanner strips every `com.google.mlkit` dependency (`Removing usual suspect
'com.google.mlkit'` in the build log; it's on F-Droid's `suss.json` non-free
list), after which the ML Kit plugin code no longer compiles (`package
com.google.mlkit.* does not exist`). This is a licensing incompatibility, not a
build-config bug — no Gradle flag or plugin bump fixes it. See ADR-028.
If OCR is ever wanted back, distribute via **IzzyOnDroid** (builds from GitHub
release APKs, allows NonFree deps), not the official F-Droid repo.

### Notes on Dependencies

- `speech_to_text` — uses Android's SpeechRecognizer API (device-level, not
  tied to Google specifically); F-Droid-clean (no proprietary Maven dependency)
- Google Play Core (`com.google.android.play`) is **excluded** in
  `android/app/build.gradle.kts` (`configurations.all { exclude(...) }`). Flutter's
  embedding pulls it in for deferred components (unused here); its
  `com.google.android.play.core.*` classes are proprietary and make F-Droid's
  `check apk` scanner fail. The `-dontwarn com.google.android.play.core.**`
  ProGuard rules are kept so R8 does not fail on the now-absent classes
  referenced by Flutter's `PlayStoreDeferredComponentManager`. (ADR-029)
