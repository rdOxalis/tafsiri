# F-Droid Release Process

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
- The Play Core `-dontwarn` rules in `proguard-rules.pro` are required by
  Flutter's `PlayStoreDeferredComponentManager` (not ML Kit) — keep them, or R8
  minification fails with "Missing class com.google.android.play.core.*"
