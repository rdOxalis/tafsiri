#!/bin/bash
#
# Tafsiri — build a Debian package of the Linux desktop app.
#
# install.sh installs into ~/.local for whoever runs it, from a source tree
# with a Flutter SDK in it. This produces the other thing: a .deb that a user
# without either can install with their package manager (ADR-056).
#
# Usage:
#   ./build_deb.sh              build if needed, then package
#   ./build_deb.sh --rebuild    force a clean rebuild first
#   ./build_deb.sh --no-build   package the existing bundle, do not build
#

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Same identifiers as install.sh, and for the same reason: the GTK runner sets
# the Wayland app_id from APPLICATION_ID, so the desktop entry and the icons
# have to be named after it rather than after the binary (ADR-032).
APP_ID="ke.darkman.tafsiri"
BINARY_NAME="tafsiri"
APP_NAME="Tafsiri"
PACKAGE="tafsiri"
MAINTAINER="Ralf Dünkelmann <rd@oxalis.cologne>"
HOMEPAGE="https://github.com/rdOxalis/tafsiri"

BUNDLE_DIR="$PROJECT_DIR/build/linux/x64/release/bundle"
OUT_DIR="$PROJECT_DIR/build/deb"
ICON_PNG="$PROJECT_DIR/assets/icon/icon_1024.png"
ICON_SVG="$PROJECT_DIR/assets/icon/icon.svg"
ICON_SIZES=(16 24 32 48 64 128 256 512)
STAMP_FILE=".tafsiri-build"

info()  { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m warning:\033[0m %s\n' "$1" >&2; }
die()   { printf '\033[1;31m error:\033[0m %s\n' "$1" >&2; exit 1; }

build_stamp() {
    git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "nogit"
}

# The version dpkg compares, taken from the single place it is maintained.
# pubspec carries `1.0.14+14`; the build number after the + is Android's and
# means nothing to dpkg, so it is dropped rather than translated into a Debian
# revision, which would claim a repackaging that did not happen.
pubspec_version() {
    sed -n 's/^version: \([0-9][^+]*\).*/\1/p' "$PROJECT_DIR/pubspec.yaml" | head -1
}

build_app() {
    command -v flutter >/dev/null 2>&1 \
        || die "flutter not found in PATH. Install the Flutter SDK, or use
             --no-build to package an existing bundle."

    local stamp
    stamp="$(build_stamp)"
    info "Building $APP_NAME (release, $stamp)…"
    ( cd "$PROJECT_DIR" \
        && flutter build linux --release --dart-define=TAFSIRI_BUILD="$stamp" )
    echo "$stamp" > "$BUNDLE_DIR/$STAMP_FILE"
}

# Rasterised from the PNG master, not the SVG: ImageMagick's SVG support is an
# optional delegate that is often absent, and a package that silently ships no
# icons is worse than one that refuses to build.
install_icons() {
    local root="$1"
    local base="$root/usr/share/icons/hicolor"

    if [ -f "$ICON_SVG" ]; then
        install -Dm644 "$ICON_SVG" "$base/scalable/apps/$APP_ID.svg"
    fi
    [ -f "$ICON_PNG" ] || die "No icon at $ICON_PNG."

    local resizer=""
    if command -v magick >/dev/null 2>&1;  then resizer="magick"
    elif command -v convert >/dev/null 2>&1; then resizer="convert"
    elif python3 -c "import PIL" >/dev/null 2>&1; then resizer="pil"
    else die "Need ImageMagick or Python Pillow to produce the icon sizes."
    fi

    for size in "${ICON_SIZES[@]}"; do
        local dir="$base/${size}x${size}/apps"
        mkdir -p "$dir"
        case "$resizer" in
            magick)  magick "$ICON_PNG" -resize "${size}x${size}" "$dir/$APP_ID.png" ;;
            convert) convert "$ICON_PNG" -resize "${size}x${size}" "$dir/$APP_ID.png" ;;
            pil) python3 -c "
from PIL import Image
im = Image.open('$ICON_PNG').convert('RGBA')
im.resize(($size, $size), Image.LANCZOS).save('$dir/$APP_ID.png')
" ;;
        esac
        chmod 644 "$dir/$APP_ID.png"
    done
}

write_desktop_entry() {
    local root="$1"
    local file="$root/usr/share/applications/$APP_ID.desktop"
    mkdir -p "$(dirname "$file")"

    # Exec is the command, not the path: /usr/bin/tafsiri is on everyone's PATH,
    # and naming the private directory here would break if it ever moves.
    cat > "$file" << DESKTOP
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
Exec=$BINARY_NAME
Icon=$APP_ID
Terminal=false
StartupNotify=true
StartupWMClass=$APP_ID
Categories=Utility;TextTools;Dictionary;
Keywords=translate;translation;translator;language;ai;swahili;
DESKTOP
    chmod 644 "$file"

    if command -v desktop-file-validate >/dev/null 2>&1; then
        desktop-file-validate "$file" \
            || warn "desktop-file-validate reported issues (see above)."
    fi
}

write_metadata() {
    local root="$1" version="$2" stamp="$3" size_kb="$4"

    mkdir -p "$root/DEBIAN"
    # Depends is written by hand rather than derived with dpkg-shlibdeps: the
    # bundle's own libraries are private plugin .so files that shlibdeps has no
    # package for, and the engine links nothing exotic beyond GTK. These four
    # are what `ldd` on the runner and the plugins actually resolves to, minus
    # the ones every Debian system has by definition.
    #
    # Tesseract is Recommends, not Depends: without it every part of the app
    # works except image-to-text, which then says so for itself (ADR-037).
    cat > "$root/DEBIAN/control" << CONTROL
Package: $PACKAGE
Version: $version
Section: utils
Priority: optional
Architecture: amd64
Depends: libc6, libgtk-3-0 | libgtk-3-0t64, libglib2.0-0 | libglib2.0-0t64, libsqlite3-0
Recommends: tesseract-ocr
Suggests: tesseract-ocr-deu, tesseract-ocr-swa
Installed-Size: $size_kb
Maintainer: $MAINTAINER
Homepage: $HOMEPAGE
Description: AI-powered text translation with correction mode
 Tafsiri translates text with Mistral, Claude or ChatGPT, detecting the
 source language itself and switching direction accordingly: text already
 in your primary language goes to your alternative one, everything else
 comes back in your primary language.
 .
 It also corrects: in correction mode your own attempt in the language you
 are learning is improved rather than translated, with notes explaining
 each change. Translations are kept in a local history with favourites,
 text can be read out of images, and the interface is available in twelve
 languages.
 .
 This package holds the desktop application; an API key for one of the
 three providers is entered in the app and never leaves the machine
 except to that provider. Image-to-text needs the tesseract-ocr package
 and the trained data for the languages you use.
 Built from commit $stamp.
CONTROL
    chmod 644 "$root/DEBIAN/control"

    # Debian expects a copyright file per package, and it is the one piece of
    # metadata a user is entitled to find in a fixed place.
    local doc="$root/usr/share/doc/$PACKAGE"
    mkdir -p "$doc"
    {
        echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/"
        echo "Upstream-Name: $APP_NAME"
        echo "Source: $HOMEPAGE"
        echo
        echo "Files: *"
        echo "Copyright: 2026 Ralf Dünkelmann"
        echo "License: MIT"
        echo
        sed 's/^$/./; s/^/ /' "$PROJECT_DIR/LICENSE"
    } > "$doc/copyright"
    chmod 644 "$doc/copyright"

    # No postinst/postrm. Debian's desktop-file-utils and gtk-update-icon-cache
    # both ship dpkg triggers on the directories written here, so the caches are
    # refreshed by dpkg itself — a maintainer script would duplicate that and be
    # one more thing to get wrong.
}

package() {
    local version stamp
    version="$(pubspec_version)"
    [ -n "$version" ] || die "Could not read the version from pubspec.yaml."
    stamp="$(cat "$BUNDLE_DIR/$STAMP_FILE" 2>/dev/null || build_stamp)"

    local root="$OUT_DIR/$PACKAGE-$version"
    rm -rf "$root"
    mkdir -p "$root"

    info "Assembling the package tree…"
    # /usr/lib/<package> is where Debian policy puts a program's private
    # binaries, and the Flutter runner is exactly that: it resolves its engine
    # and plugins through an $ORIGIN-relative rpath, so the bundle has to stay
    # together in one directory.
    local libdir="$root/usr/lib/$PACKAGE"
    mkdir -p "$libdir"
    cp -r "$BUNDLE_DIR"/. "$libdir/"
    rm -f "$libdir/$STAMP_FILE"

    find "$libdir" -type f -exec chmod 644 {} +
    find "$libdir" -type d -exec chmod 755 {} +
    chmod 755 "$libdir/$BINARY_NAME"
    find "$libdir" -name '*.so*' -type f -exec chmod 755 {} +

    mkdir -p "$root/usr/bin"
    ln -sf "../lib/$PACKAGE/$BINARY_NAME" "$root/usr/bin/$BINARY_NAME"

    install_icons "$root"
    write_desktop_entry "$root"

    local size_kb
    size_kb="$(du -ks "$root" | cut -f1)"
    write_metadata "$root" "$version" "$stamp" "$size_kb"

    # The builder's umask leaks into every directory mkdir -p creates, and a
    # group-writable directory in a package installed as root is a real finding,
    # not a cosmetic one. Normalise the whole tree rather than each mkdir.
    find "$root" -type d -exec chmod 755 {} +

    local deb="$OUT_DIR/${PACKAGE}_${version}_amd64.deb"
    info "Building $deb…"
    # --root-owner-group makes every file root:root without needing fakeroot,
    # which is what a package installed system-wide has to be owned by.
    dpkg-deb --root-owner-group --build "$root" "$deb" >/dev/null

    if command -v lintian >/dev/null 2>&1; then
        lintian --no-tag-display-limit "$deb" || warn "lintian reported issues."
    fi

    info "Done: $deb ($(du -h "$deb" | cut -f1), built from $stamp)"
    echo "  Install it with:  sudo apt install $deb"
    echo "  Remove it with:   sudo apt remove $PACKAGE"
    echo "  Settings and history live in ~/.local/share/$APP_ID/ and survive both."
}

# ---------------------------------------------------------------------- main --

REBUILD="no"
DO_BUILD="yes"

while [ $# -gt 0 ]; do
    case "$1" in
        --rebuild)  REBUILD="yes" ;;
        --no-build) DO_BUILD="no" ;;
        -h|--help)
            sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) die "Unknown option: $1 (try --help)" ;;
    esac
    shift
done

if [ "$REBUILD" = "yes" ]; then
    rm -rf "$PROJECT_DIR/build/linux"
    build_app
elif [ "$DO_BUILD" = "yes" ]; then
    build_app
elif [ ! -x "$BUNDLE_DIR/$BINARY_NAME" ]; then
    die "No bundle at $BUNDLE_DIR — drop --no-build."
fi

package
