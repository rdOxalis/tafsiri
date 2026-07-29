#!/bin/bash
#
# Tafsiri — build and install the Linux desktop app for the current user.
#
# Installs into ~/.local (no root required) and registers a desktop entry so
# Tafsiri shows up in the application menu.
#
# Usage:
#   ./install.sh              build if needed, then install
#   ./install.sh --rebuild    force a clean rebuild first
#   ./install.sh --uninstall  remove everything this script installed
#

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The GTK runner calls g_set_prgname(APPLICATION_ID) in
# linux/runner/my_application.cc, so the Wayland app_id is the application ID —
# NOT the binary name. The desktop entry and the icon must both be named after
# it, otherwise the compositor cannot map the window to this .desktop file and
# the app shows a generic placeholder icon in the dash/task switcher.
APP_ID="ke.darkman.tafsiri"
BINARY_NAME="tafsiri"
APP_NAME="Tafsiri"

BUNDLE_DIR="$PROJECT_DIR/build/linux/x64/release/bundle"
INSTALL_DIR="$HOME/.local/share/$BINARY_NAME"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_BASE="$HOME/.local/share/icons/hicolor"
ICON_PNG="$PROJECT_DIR/assets/icon/icon_1024.png"
ICON_SVG="$PROJECT_DIR/assets/icon/icon.svg"
ICON_SIZES=(16 24 32 48 64 128 256 512)

info()  { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m warning:\033[0m %s\n' "$1" >&2; }
die()   { printf '\033[1;31m error:\033[0m %s\n' "$1" >&2; exit 1; }

# ---------------------------------------------------------------- uninstall --

remove_installed_files() {
    rm -rf "$INSTALL_DIR"
    rm -f  "$BIN_DIR/$BINARY_NAME"
    rm -f  "$DESKTOP_DIR/$APP_ID.desktop"
    for size in "${ICON_SIZES[@]}"; do
        rm -f "$ICON_BASE/${size}x${size}/apps/$APP_ID.png"
    done
    rm -f "$ICON_BASE/scalable/apps/$APP_ID.svg"
}

refresh_caches() {
    gtk-update-icon-cache -f -t "$ICON_BASE" >/dev/null 2>&1 || true
    update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
}

do_uninstall() {
    info "Removing $APP_NAME…"
    remove_installed_files
    refresh_caches
    info "$APP_NAME has been removed."
    echo "  Your settings and translation history were kept:"
    echo "    ~/.local/share/$APP_ID/"
    echo "  Delete that directory too if you want a clean slate."
}

# ------------------------------------------------------------------ install --

check_build_deps() {
    command -v flutter >/dev/null 2>&1 \
        || die "flutter not found in PATH. Install the Flutter SDK first."
    pkg-config --exists gtk+-3.0 2>/dev/null \
        || die "GTK 3 development libraries are missing. Install them with:
             sudo apt install libgtk-3-dev"
}

check_runtime_deps() {
    # sqflite runs through sqflite_common_ffi on desktop (ADR-031), which loads
    # the system SQLite at runtime. The unversioned soname only ships in the
    # -dev package, so the app falls back to libsqlite3.so.0 — but one of the
    # two has to exist.
    # Note: grep -c, not grep -q. Under `set -o pipefail`, grep -q exits on the
    # first match and leaves ldconfig with SIGPIPE (141), which would fail the
    # whole pipeline and warn even when SQLite is perfectly fine.
    local found
    found="$(ldconfig -p 2>/dev/null | grep -c 'libsqlite3\.so' || true)"
    if [ "${found:-0}" -eq 0 ]; then
        warn "Could not find libsqlite3 via ldconfig. If history and saving
             translations fail at runtime, install it with:
             sudo apt install libsqlite3-0"
    fi
}

build_app() {
    local cache="$PROJECT_DIR/build/linux/x64/release/CMakeCache.txt"

    # A configure run that fails before CMake reaches Flutter's install block
    # (a missing GTK, typically) still leaves a CMakeCache.txt pinning
    # CMAKE_INSTALL_PREFIX=/usr/local. Flutter's linux/CMakeLists.txt only
    # rewrites that prefix when CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT is
    # set, which is true only on the *first* configure in a build tree — so
    # every later build tries to install into /usr/local and dies with
    # "Permission denied". Drop the tree when the cached prefix is wrong.
    if [ -f "$cache" ] && ! grep -qxF "CMAKE_INSTALL_PREFIX:PATH=$BUNDLE_DIR" "$cache"; then
        warn "Stale CMake cache with a bad install prefix — wiping build/linux."
        rm -rf "$PROJECT_DIR/build/linux"
    fi

    info "Building $APP_NAME (release)…"
    ( cd "$PROJECT_DIR" && flutter build linux --release )

    [ -x "$BUNDLE_DIR/$BINARY_NAME" ] \
        || die "Build finished but $BUNDLE_DIR/$BINARY_NAME is missing."
}

install_icons() {
    mkdir -p "$ICON_BASE/scalable/apps"

    # The vector icon is what Wayland compositors and HiDPI shells prefer.
    if [ -f "$ICON_SVG" ]; then
        cp "$ICON_SVG" "$ICON_BASE/scalable/apps/$APP_ID.svg"
    fi

    if [ ! -f "$ICON_PNG" ]; then
        warn "No raster icon at $ICON_PNG — installing the SVG only."
        return
    fi

    # Rasterise from the PNG master rather than the SVG: ImageMagick's SVG
    # rendering depends on an optional delegate that is often missing.
    local resizer=""
    if command -v magick >/dev/null 2>&1;  then resizer="magick"
    elif command -v convert >/dev/null 2>&1; then resizer="convert"
    elif python3 -c "import PIL" >/dev/null 2>&1; then resizer="pil"
    fi

    if [ -z "$resizer" ]; then
        warn "Neither ImageMagick nor Python Pillow found — installing the
             master icon at 512x512 only. Menu icons may look soft."
        mkdir -p "$ICON_BASE/512x512/apps"
        cp "$ICON_PNG" "$ICON_BASE/512x512/apps/$APP_ID.png"
        return
    fi

    for size in "${ICON_SIZES[@]}"; do
        local dir="$ICON_BASE/${size}x${size}/apps"
        mkdir -p "$dir"
        case "$resizer" in
            magick)
                magick "$ICON_PNG" -resize "${size}x${size}" "$dir/$APP_ID.png" ;;
            convert)
                convert "$ICON_PNG" -resize "${size}x${size}" "$dir/$APP_ID.png" ;;
            pil)
                python3 -c "
from PIL import Image
im = Image.open('$ICON_PNG').convert('RGBA')
im.resize(($size, $size), Image.LANCZOS).save('$dir/$APP_ID.png')
" ;;
        esac
    done
}

write_desktop_entry() {
    mkdir -p "$DESKTOP_DIR"
    # Filename must equal the Wayland app_id so the shell matches window→entry.
    cat > "$DESKTOP_DIR/$APP_ID.desktop" << DESKTOP
[Desktop Entry]
Type=Application
Version=1.4
Name=$APP_NAME
GenericName=Translator
GenericName[de]=Übersetzer
GenericName[sw]=Mtafsiri
GenericName[fr]=Traducteur
GenericName[nl]=Vertaler
GenericName[es]=Traductor
GenericName[da]=Oversætter
GenericName[nb]=Oversetter
GenericName[sv]=Översättare
GenericName[pl]=Tłumacz
Comment=AI-powered text translation
Comment[de]=KI-gestützte Textübersetzung
Comment[sw]=Tafsiri ya maandishi kwa kutumia AI
Comment[fr]=Traduction de texte par IA
Comment[nl]=AI-gestuurde tekstvertaling
Comment[es]=Traducción de texto con IA
Comment[da]=AI-drevet tekstoversættelse
Comment[nb]=AI-drevet tekstoversettelse
Comment[sv]=AI-driven textöversättning
Comment[pl]=Tłumaczenie tekstu oparte na AI
Exec="$INSTALL_DIR/$BINARY_NAME"
Icon=$APP_ID
Terminal=false
StartupNotify=true
StartupWMClass=$APP_ID
Categories=Utility;TextTools;Dictionary;
Keywords=translate;translation;translator;language;ai;swahili;
DESKTOP

    if command -v desktop-file-validate >/dev/null 2>&1; then
        desktop-file-validate "$DESKTOP_DIR/$APP_ID.desktop" \
            || warn "desktop-file-validate reported issues (see above)."
    fi
}

do_install() {
    local force_rebuild="$1"

    check_build_deps
    check_runtime_deps

    if [ "$force_rebuild" = "yes" ]; then
        rm -rf "$PROJECT_DIR/build/linux"
        build_app
    elif [ ! -x "$BUNDLE_DIR/$BINARY_NAME" ]; then
        build_app
    else
        info "Reusing existing build at $BUNDLE_DIR (use --rebuild to force)."
    fi

    info "Installing to $INSTALL_DIR…"
    remove_installed_files
    mkdir -p "$INSTALL_DIR"
    cp -r "$BUNDLE_DIR"/. "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/$BINARY_NAME"

    mkdir -p "$BIN_DIR"
    ln -sf "$INSTALL_DIR/$BINARY_NAME" "$BIN_DIR/$BINARY_NAME"

    info "Installing icons…"
    install_icons

    info "Registering desktop entry…"
    write_desktop_entry
    refresh_caches

    echo
    info "$APP_NAME is installed."
    echo "  Launch it from your application menu, or run: $BINARY_NAME"
    echo

    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) warn "$BIN_DIR is not in your PATH — the '$BINARY_NAME' command will
             not work until you add it. The menu entry works regardless." ;;
    esac

    echo "  Note: voice input and image OCR are unavailable on Linux —"
    echo "  those plugins have no Linux implementation (see docs/decisions.md, ADR-031)."
}

# ---------------------------------------------------------------------- main --

MODE="install"
REBUILD="no"

while [ $# -gt 0 ]; do
    case "$1" in
        --uninstall) MODE="uninstall" ;;
        --rebuild)   REBUILD="yes" ;;
        -h|--help)
            sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) die "Unknown option: $1 (try --help)" ;;
    esac
    shift
done

if [ "$MODE" = "uninstall" ]; then
    do_uninstall
else
    do_install "$REBUILD"
fi
