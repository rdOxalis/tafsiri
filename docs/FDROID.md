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

F-Droid builds run on Debian Trixie with Java 21. Common issues:

| Problem | Fix |
|---------|-----|
| Gradle/Java incompatibility | Upgrade Gradle + AGP in `android/` |
| JdkImageTransform/jlink error | AGP must be 8.3.0+ for Java 21 |
| Scanner finds binaries in .pub-cache | `scandelete: - .pub-cache` in YAML handles this |

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
MR: (pending — to be added after submission)
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
- F-Droid CI: `fdroid build` step will fail for Flutter apps (expected) — only
  the lint/schema/rewritemeta steps need to pass before human review

### Anti-Features

Tafsiri has `NonFreeNet` because it connects to proprietary AI API services.
The user provides their own API key. The app itself is fully FOSS.

### Notes on Dependencies

- `google_mlkit_text_recognition` — uses the unbundled ML Kit (Apache 2.0),
  does NOT require Google Play Services; proguard-rules.pro has `-dontwarn` rules
  for unreferenced Play Core classes (dead code in the MLKit library)
- `speech_to_text` — uses Android's SpeechRecognizer API (device-level, not
  tied to Google specifically)
