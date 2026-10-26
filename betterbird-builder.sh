#!/usr/bin/env bash

set -euo pipefail

APP=betterbird
ARCH=x86_64
REPO_OWNER="erickCantu"
REPO_NAME="betterbird-appimage"

# -- 1. Prepare the upstream archive
TARBALL="$(find . -maxdepth 1 -type f -name '*.tar.xz' -print -quit)"
[ -n "$TARBALL" ] || { echo "No upstream .tar.xz archive found" >&2; exit 1; }
CLEAN="${TARBALL##*/}"
CLEAN="${CLEAN#betterbird-}"
CLEAN="${CLEAN%%.en-US.*}"
CLEAN="${CLEAN//esr/}"

# -- 2. Download the official appimagetool
if [ ! -x ./appimagetool-x86_64.AppImage ]; then
  wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x appimagetool-x86_64.AppImage
fi

# -- 3. Assemble the AppDir
rm -rf "$APP.AppDir"
mkdir -p "$APP.AppDir/usr/share/icons/hicolor"
tar xf "$TARBALL"
[ -d "./$APP" ] || { echo "Archive does not contain ./$APP/" >&2; exit 1; }
cp -a "./$APP"/. "$APP.AppDir/usr/"
touch "$APP.AppDir/is_packaged_app"
convert "$APP.AppDir/usr/chrome/icons/default/default128.png" \
        -resize 256x256 "$APP.AppDir/.DirIcon"

ICON_SRC="$APP.AppDir/usr/chrome/icons/default"
for png in "$ICON_SRC"/default*.png; do
  s="${png##*default}"; s="${s%.png}"
  mkdir -p "$APP.AppDir/usr/share/icons/hicolor/${s}x${s}/apps"
  cp "$png" "$APP.AppDir/usr/share/icons/hicolor/${s}x${s}/apps/betterbird.png"
done
convert "$ICON_SRC/default128.png" -resize 256x256 \
        "$APP.AppDir/usr/share/icons/hicolor/256x256/apps/betterbird.png"
cat > "$APP.AppDir/AppRun" << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr:${PATH}"
export MOZ_LEGACY_PROFILES=1
export MOZ_APP_LAUNCHER="${APPIMAGE}"
exec "${HERE}/usr/betterbird-bin" "$@"
EOF
chmod +x "$APP.AppDir/AppRun"

# -- 4. Package creation
mkdir -p dist
ARCH=x86_64 ./appimagetool-x86_64.AppImage \
  -u "gh-rleases-zsync|${REPO_OWNER}|${REPO_NAME}|latest|Betterbird-*-x86_64.AppImage.zsync" \
  "$APP.AppDir" \
  "dist/Betterbird-${CLEAN}-x86_64.AppImage"

echo "Build: dist/Betterbird-${CLEAN}-x86_64.AppImage"
