#!/bin/bash
#
# Tafsiri — build and install the macOS desktop app.
#
# Produces a release .app and copies it into /Applications, which is where
# Finder looks and what Spotlight indexes. No installer format: on macOS an
# application *is* a directory, so installing it means putting it somewhere.
#
# Usage:
#   ./build_macos.sh              build, then install
#   ./build_macos.sh --rebuild    delete build/macos first
#   ./build_macos.sh --user       install into ~/Applications instead
#   ./build_macos.sh --no-install build only, leave it in build/
#   ./build_macos.sh --package    build and zip it for a GitHub release
#   ./build_macos.sh --uninstall  remove the installed app
#
# Requirements:
#   - Xcode with its command line tools
#   - CocoaPods (brew install cocoapods)
#   - Tesseract for image-to-text (brew install tesseract tesseract-lang)
#

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_NAME="tafsiri.app"
BUNDLE_ID="ke.darkman.tafsiri"
BUILT_APP="$PROJECT_DIR/build/macos/Build/Products/Release/$APP_NAME"

info()  { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
note()  { printf '    %s\n' "$1"; }
warn()  { printf '\033[1;33m warning:\033[0m %s\n' "$1" >&2; }
die()   { printf '\033[1;31m error:\033[0m %s\n' "$1" >&2; exit 1; }

MODE="install"
REBUILD="no"
INSTALL_DIR="/Applications"

while [ $# -gt 0 ]; do
    case "$1" in
        --uninstall)  MODE="uninstall" ;;
        --no-install) MODE="build" ;;
        --package)    MODE="package" ;;
        --rebuild)    REBUILD="yes" ;;
        --user)       INSTALL_DIR="$HOME/Applications" ;;
        -h|--help)    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)            die "Unknown option: $1" ;;
    esac
    shift
done

TARGET="$INSTALL_DIR/$APP_NAME"

# ------------------------------------------------------------------ checks --

require_macos() {
    [ "$(uname -s)" = "Darwin" ] || die "This script only runs on macOS."
}

require_flutter() {
    command -v flutter >/dev/null || die "flutter is not on PATH."
}

# speech_to_text ships a Package.swift declaring .macOS("10.14") while its own
# podspec declares 11.00, and its Swift uses SFTranscription, which needs 10.15.
# Under Swift Package Manager the wrong manifest wins and the build fails on
# availability, so this project needs CocoaPods until that is fixed upstream.
# The setting is per machine, not per project, which is exactly why it is worth
# checking rather than assuming (ADR-053).
require_cocoapods_integration() {
    command -v pod >/dev/null \
        || die "CocoaPods is not installed. Run: brew install cocoapods"

    if flutter config 2>/dev/null | grep -q 'enable-swift-package-manager: true'; then
        die "Swift Package Manager is enabled, and speech_to_text cannot build
       under it. Run this once, then try again:

         flutter config --no-enable-swift-package-manager
         flutter clean"
    fi
}

# ------------------------------------------------------------------- build --

# Short commit the tree is at, baked into the binary so Settings can show which
# build is running. Just the commit — see ADR-041 for why there is no -dirty.
build_stamp() {
    git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "nogit"
}

build_app() {
    if [ "$REBUILD" = "yes" ]; then
        info "Removing build/macos for a clean rebuild…"
        rm -rf "$PROJECT_DIR/build/macos"
    fi

    info "Fetching packages…"
    ( cd "$PROJECT_DIR" && flutter pub get )

    local stamp
    stamp="$(build_stamp)"
    info "Building Tafsiri (release, $stamp)…"
    ( cd "$PROJECT_DIR" \
        && flutter build macos --release --dart-define=TAFSIRI_BUILD="$stamp" )

    [ -d "$BUILT_APP" ] || die "Build finished but $BUILT_APP is missing."
}

# ----------------------------------------------------------------- install --

install_app() {
    [ -d "$INSTALL_DIR" ] || mkdir -p "$INSTALL_DIR"
    [ -w "$INSTALL_DIR" ] || die "$INSTALL_DIR is not writable. Either run this
       with an administrator account, or use --user to install into
       ~/Applications instead."

    # Replace rather than merge: an .app is a directory, and copying over an
    # older one leaves whatever the new build no longer ships.
    if [ -d "$TARGET" ]; then
        info "Replacing the existing ${TARGET}…"
        rm -rf "$TARGET"
    fi

    info "Installing to ${TARGET}…"
    cp -R "$BUILT_APP" "$TARGET"

    # Spotlight picks new applications up on its own, but not always promptly,
    # and "it is not in Spotlight yet" is indistinguishable from "the install
    # failed" to anyone waiting for it.
    if command -v mdimport >/dev/null; then
        mdimport "$TARGET" >/dev/null 2>&1 || true
    fi
}

# ----------------------------------------------------------------- package --

# The version, without the build number Inno Setup also rejects.
pubspec_version() {
    sed -n 's/^version:[[:space:]]*\([^+]*\).*/\1/p' "$PROJECT_DIR/pubspec.yaml" \
        | tr -d '[:space:]'
}

package_app() {
    local version arch out
    version="$(pubspec_version)"
    [ -n "$version" ] || die "No version found in pubspec.yaml."

    # Named after what the binary actually contains rather than what the build
    # machine happens to be: Flutter builds for the host architecture, so an
    # Apple silicon Mac produces an arm64-only app and saying "macos" alone
    # would promise an Intel user something that will not start.
    arch="$(lipo -archs "$BUILT_APP/Contents/MacOS/tafsiri" 2>/dev/null \
            | tr ' ' '-' | tr -d '\n')"
    [ -n "$arch" ] || arch="unknown"

    out="$PROJECT_DIR/build/macos/tafsiri-$version-macos-$arch.zip"
    rm -f "$out"

    # ditto, not zip: it preserves symlinks inside the frameworks and the code
    # signature, both of which a plain `zip -r` quietly mangles into an app that
    # refuses to launch on someone else's machine.
    info "Packaging ${out##*/}…"
    ditto -c -k --sequesterRsrc --keepParent "$BUILT_APP" "$out"

    PACKAGE_PATH="$out"
}

uninstall_app() {
    local removed="no"
    for dir in /Applications "$HOME/Applications"; do
        if [ -d "$dir/$APP_NAME" ]; then
            info "Removing $dir/${APP_NAME}…"
            rm -rf "$dir/$APP_NAME"
            removed="yes"
        fi
    done
    [ "$removed" = "yes" ] || note "Nothing to remove."

    note "Settings, API keys and history are left alone. To remove those too:"
    note "  rm -rf ~/Library/'Application Support'/$BUNDLE_ID"
    note "  defaults delete $BUNDLE_ID"
}

# -------------------------------------------------------------------- main --

require_macos

if [ "$MODE" = "uninstall" ]; then
    uninstall_app
    exit 0
fi

require_flutter
require_cocoapods_integration
build_app

if [ "$MODE" = "build" ]; then
    info "Done."
    note "App: $BUILT_APP"
    exit 0
fi

if [ "$MODE" = "package" ]; then
    package_app
    printf '\n'
    info "Done."
    note "Upload this to the release:"
    note "  $PACKAGE_PATH"
    note ""
    note "It is ad-hoc signed and not notarized, so anyone else who downloads it"
    note "gets a Gatekeeper warning and has to right-click - Open the first time."
    exit 0
fi

install_app

printf '\n'
info "Done."
note "Installed: $TARGET"
note "Open it from Finder or Spotlight, or run: open -a Tafsiri"
printf '\n'
note "Image-to-text needs Tesseract, which is not bundled:"
note "  brew install tesseract tesseract-lang"
note ""
note "The microphone asks for permission the first time you use it. macOS only"
note "shows that prompt to an app in the foreground, so click the window first."
note "If it was ever refused, macOS will not ask again — reset it with:"
note "  tccutil reset SpeechRecognition $BUNDLE_ID"
note "  tccutil reset Microphone $BUNDLE_ID"
note ""
note "When something misbehaves, read \$TMPDIR/tafsiri.log — it records which"
note "Tesseract binary ran, the languages found, the script detected, every"
note "command run, and whether speech recognition initialised."
