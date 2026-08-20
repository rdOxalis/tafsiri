#!/bin/bash
#
# Tafsiri — build the Android release artefacts.
#
# Produces the APK that goes on the GitHub release and the App Bundle that goes
# to the Play Console, both stamped with the commit they were built from and
# both verified to carry the real upload key.
#
# Usage:
#   ./build_android.sh          both the APK and the AAB
#   ./build_android.sh --apk    only the APK (GitHub release)
#   ./build_android.sh --aab    only the AAB (Play Console)
#   ./build_android.sh --stamp <commit>
#                               label the build with this commit instead of
#                               HEAD — use the release tag when HEAD has moved
#                               on with changes the app does not contain
#
# Requirements:
#   - Flutter SDK on PATH
#   - android/key.properties, holding the upload key
#

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$PROJECT_DIR/build/app/outputs"
KEY_PROPERTIES="$PROJECT_DIR/android/key.properties"

info()  { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
note()  { printf '    %s\n' "$1"; }
die()   { printf '\033[1;31m error:\033[0m %s\n' "$1" >&2; exit 1; }

WANT_APK="yes"
WANT_AAB="yes"
STAMP=""

while [ $# -gt 0 ]; do
    case "$1" in
        --apk)     WANT_APK="yes"; WANT_AAB="no" ;;
        --aab)     WANT_APK="no";  WANT_AAB="yes" ;;
        --stamp)   shift; [ $# -gt 0 ] || die "--stamp needs a commit."
                   STAMP="$1" ;;
        -h|--help) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)         die "Unknown option: $1" ;;
    esac
    shift
done

# ------------------------------------------------------------------ checks --

# android/app/build.gradle.kts falls back to the *debug* signing config when
# key.properties is absent. That produces a release-looking artefact signed with
# a throwaway key: Play rejects it, and an APK signed that way cannot be
# installed over an existing Tafsiri. Silently shipping one is worse than not
# building at all, so this is a hard stop rather than a warning (ADR-036).
require_upload_key() {
    [ -f "$KEY_PROPERTIES" ] || die "android/key.properties is missing.
       Without it Gradle signs the release with the debug key, which Play
       rejects and which cannot be installed over an existing Tafsiri."
}

require_flutter() {
    command -v flutter >/dev/null || die "flutter is not on PATH."
}

pubspec_version() {
    sed -n 's/^version:[[:space:]]*\([^+]*\).*/\1/p' "$PROJECT_DIR/pubspec.yaml" \
        | tr -d '[:space:]'
}

# ------------------------------------------------------------------- build --

build_stamp() {
    [ -n "$STAMP" ] && { echo "$STAMP"; return; }
    git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "nogit"
}

# What the merged manifest ended up saying, which is the only account of it that
# Gradle and Play both agree on.
report_manifest() {
    local manifest
    manifest="$(find "$PROJECT_DIR/build/app/intermediates/merged_manifests" \
        -name AndroidManifest.xml -path '*release*' 2>/dev/null | head -1)"
    [ -n "$manifest" ] || return 0
    note "$(grep -oE 'android:versionCode="[^"]*"|android:versionName="[^"]*"|android:targetSdkVersion="[^"]*"' \
        "$manifest" | sort -u | tr '\n' ' ')"
}

# Refuses anything signed with Android's debug certificate. The check is on the
# artefact rather than on key.properties, because the question that matters is
# what came out, not what the configuration promised.
#
# `LC_ALL=C` is load-bearing: keytool translates its output, and on a German
# system it prints "Eigentümer:" where this expects "Owner:". Note the shape of
# the check — it demands a name it could read and *then* rejects the debug one.
# Phrased the other way round, as "fail if it says Android Debug", a translated
# output would match nothing and a debug-signed artefact would sail through.
assert_release_signed() {
    local artefact="$1" owner
    owner="$(unzip -p "$artefact" 'META-INF/*.RSA' 2>/dev/null \
        | LC_ALL=C keytool -printcert 2>/dev/null \
        | sed -n 's/^Owner: *//p' | head -1)"

    case "$owner" in
        "")                die "Could not read the signature of ${artefact##*/}." ;;
        *"Android Debug"*) die "${artefact##*/} is signed with the debug key.
       Check android/key.properties." ;;
    esac
    note "signed: $owner"
}

main() {
    require_flutter
    require_upload_key

    local version stamp
    version="$(pubspec_version)"
    [ -n "$version" ] || die "No version found in pubspec.yaml."
    stamp="$(build_stamp)"

    info "Tafsiri $version (release, $stamp)"
    ( cd "$PROJECT_DIR" && flutter pub get )

    if [ "$WANT_APK" = "yes" ]; then
        info "Building the APK…"
        ( cd "$PROJECT_DIR" \
            && flutter build apk --release --dart-define=TAFSIRI_BUILD="$stamp" )
        cp "$OUT_DIR/flutter-apk/app-release.apk" \
           "$OUT_DIR/flutter-apk/tafsiri-$version.apk"
        assert_release_signed "$OUT_DIR/flutter-apk/tafsiri-$version.apk"
    fi

    if [ "$WANT_AAB" = "yes" ]; then
        info "Building the App Bundle…"
        ( cd "$PROJECT_DIR" \
            && flutter build appbundle --release \
                 --dart-define=TAFSIRI_BUILD="$stamp" )
        cp "$OUT_DIR/bundle/release/app-release.aab" \
           "$OUT_DIR/bundle/release/tafsiri-$version.aab"
        assert_release_signed "$OUT_DIR/bundle/release/tafsiri-$version.aab"
    fi

    report_manifest

    printf '\n'
    info "Done."
    [ "$WANT_APK" = "yes" ] && \
        note "GitHub release: $OUT_DIR/flutter-apk/tafsiri-$version.apk"
    [ "$WANT_AAB" = "yes" ] && \
        note "Play Console:   $OUT_DIR/bundle/release/tafsiri-$version.aab"
    printf '\n'
    note "Play needs the versionCode to increase with every upload; it comes"
    note "from the +N suffix in pubspec.yaml."
    return 0
}

main
