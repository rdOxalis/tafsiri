# F-Droid Submission — Postmortem

**Date:** 2026-06-14
**Outcome:** Official F-Droid inclusion **abandoned**. OCR restored. Released as v1.0.8.
**MR:** https://gitlab.com/fdroid/fdroiddata/-/merge_requests/39249 (closed)
**Related decisions:** ADR-027, ADR-028, ADR-029, ADR-030.

## Goal

Get Tafsiri into the official F-Droid repository, which builds apps **from source**
on its own infrastructure and forbids proprietary/non-free dependencies and
prebuilt binaries.

## Why we were going in circles before this session

Earlier commits (`ee2b338`, `28eed06`, `d2afa69`) only varied *how* a single
gradle flag (`android.newDsl=false`) was applied, then re-tagged and waited days
for F-Droid CI to fail again. The loop broke once we **reproduced the F-Droid
build locally** instead of tag-and-pray:

- F-Droid's failing job logs are public via the GitLab API — no auth needed:
  `curl -sL https://gitlab.com/ooocp/fdroiddata/-/jobs/<JOB_ID>/raw`
- The dev box already had the exact Flutter F-Droid uses (`3.41.9`), an Android
  SDK, and (after a one-off download) a full JDK 21. Reproducing F-Droid's
  bleeding-edge toolchain locally meant **AGP 9.0.1 + Gradle 9.1.0 + JDK 21**.

This turned "guess and wait" into "reproduce, fix, verify in minutes."

## The three walls (each real, each proven)

### Wall 1 — AGP 9 build failure (ADR-027)
F-Droid's buildserver pulls `fdroidserver` from `master`, so it builds with a
bleeding-edge **AGP 9 / Gradle 9** toolchain (the project pins AGP 8.7.3, but the
environment overrides it). That activates the new Gradle DSL **and** built-in
Kotlin. The fix needed **both** opt-out flags — `android.newDsl=false` *and*
`android.builtInKotlin=false`. `newDsl` alone left a `kotlin-android`
"extension already registered" error. Proven locally; both flags are harmless on
AGP 8.x so they were kept.

### Wall 2 — ML Kit is proprietary (ADR-028)
With AGP fixed, `fdroid build` reached `google_mlkit_commons` and failed. The log
showed `INFO: Removing usual suspect 'com.google.mlkit'`: F-Droid's scanner
**strips every `com.google.mlkit:*` dependency** (ML Kit is proprietary Google
software on F-Droid's `suss.json` non-free list). Replicating the strip locally
produced 23 compile errors (`package com.google.mlkit.* does not exist`). This is
a licensing incompatibility, not a build bug — no flag fixes it. ML Kit was the
**only** non-free dependency flagged (speech_to_text, the AI HTTP calls, sqflite,
etc. are all clean). Decision at the time: remove the image-to-text/OCR feature.
`fdroid build` then **passed**.

### Wall 3 — Flutter bundles Google Play Core (ADR-029 → ADR-030)
With the build green, the `check apk` job (which only runs once a build exists,
so it had never run before) rejected **6 `com.google.android.play.core.*`
classes** — Google Play Core, which Flutter's embedding bundles for Play Store
"deferred components" (unused here). This is the long-standing, unresolved
[flutter#104219](https://github.com/flutter/flutter/issues/104219).

This wall could **not be cleared with local verification**:
- Locally, R8 strips those classes regardless of any gradle exclude — the APK
  always had 0 `com.google.android.play.core` class definitions (checked with
  `dexdump`, after an initial `strings`-based false positive).
- On F-Droid the classes survived into the APK (53.0 MB vs the local 52.7 MB).
- The difference is R8/minification behaviour between the toolchains, which the
  dev box could not reproduce — so any further fix would again be blind
  tag-and-pray against F-Droid CI.

## Decision (ADR-030)

Given OCR was already lost to Wall 2 and Wall 3 was unverifiable locally, the
cost/benefit no longer justified continuing. We **abandoned official F-Droid**,
**closed MR #39249**, and **restored OCR** (v1.0.8).

## Final state

- OCR/image-to-text restored (ML Kit + image_picker, permissions, ProGuard
  rules, strings, store-description mentions).
- Google Play Core exclusion removed from `build.gradle.kts` (was F-Droid-only).
- **AGP bumped 8.7.3 → 8.9.1** — current `image_picker` transitives
  (androidx activity/core 1.18.x) require AGP ≥ 8.9.1; Gradle wrapper 8.12 is
  compatible. `flutter build apk --release` verified (84.5 MB).
- `android.newDsl=false` + `android.builtInKotlin=false` kept (harmless).
- `fdroid/` recipe + fastlane metadata remain as unused historical artifacts;
  `docs/FDROID.md` carries an "abandoned" banner.
- Tags `v1.0.6`/`v1.0.7` (F-Droid attempts, never published) deleted. Current: `v1.0.8`.
- Distribution: Play Store / direct APK / GitHub releases.

## Lessons learned

1. **Reproduce the CI build locally before iterating.** Pull the public job log
   via the GitLab API; match the toolchain (Flutter version, JDK, AGP/Gradle).
   This is the single thing that stopped the circling.
2. **F-Droid is strict by design.** ML Kit (proprietary) and Flutter's bundled
   Play Core both trip the non-free scanner. An app that depends on them cannot
   go in the official repo unmodified — and that's a policy stance, not a bug to
   out-engineer.
3. **Verify the fix, not just the build.** `flutter analyze` + a real release
   build catches regressions a green compile hides (e.g., the Play Core
   `-dontwarn` rules turned out to be needed by Flutter itself, not ML Kit; and
   re-adding `image_picker` forced the AGP bump).
4. **If a FOSS-store presence is wanted later, use IzzyOnDroid** — it builds from
   GitHub release APKs and allows ML Kit / NonFree deps, so it keeps OCR. The
   official F-Droid repo does not.
