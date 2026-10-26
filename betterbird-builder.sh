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

# -- 2. Download and verify the official appimagetool
TOOL_META="$(curl -fsSL 'https://api.github.com/repos/AppImage/appimagetool/releases/tags/continuous')"
TOOL_INFO="$(printf '%s' "$TOOL_META" | python3 -c '
import json
import sys

assets = json.load(sys.stdin)["assets"]
asset = next(asset for asset in assets if asset["name"] == "appimagetool-x86_64.AppImage")
digest = asset.get("digest", "")
if not digest.startswith("sha256:"):
    raise SystemExit("appimagetool release has no SHA-256 digest")
print(asset["browser_download_url"])
print(digest.split(":", 1)[1])
')"
TOOL_URL="$(printf '%s\n' "$TOOL_INFO" | sed -n '1p')"
TOOL_SHA="$(printf '%s\n' "$TOOL_INFO" | sed -n '2p')"
curl -fsSL "$TOOL_URL" -o appimagetool-x86_64.AppImage
echo "${TOOL_SHA} *appimagetool-x86_64.AppImage" | sha256sum -c -
chmod +x appimagetool-x86_64.AppImage

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
cat > "$APP.AppDir/betterbird.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Type=Application
Name=Betterbird
GenericName=Mail Client
Comment=Cozy, private mail client (IMAP/POP3)
Exec=betterbird %u
Icon=betterbird
Terminal=false
Categories=Network;Email;
MimeType=message/rfc822;x-scheme-handler/mailto;
StartupWMClass=eu.betterbird.Betterbird
StartupNotify=true

[Desktop Action ComposeMessage]
Name=Compose Message
Exec=betterbird -compose

[Desktop Action OpenAddressBook]
Name=Open Address Book
Exec=betterbird -addressbook
EOF

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
  -u "gh-releases-zsync|${REPO_OWNER}|${REPO_NAME}|latest|Betterbird-*-x86_64.AppImage.zsync" \
  "$APP.AppDir" \
  "dist/Betterbird-${CLEAN}-x86_64.AppImage"

echo "Build: dist/Betterbird-${CLEAN}-x86_64.AppImage"
