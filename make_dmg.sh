#!/bin/bash
# Package ToneBar.app into a distributable .dmg with an Applications shortcut.
set -euo pipefail
cd "$(dirname "$0")"

APP="ToneBar.app"
VOLNAME="音条 ToneBar"
DMG="ToneBar-1.0.dmg"
STAGING=".dmg_staging"

[ -d "$APP" ] || { echo "✗ $APP not found — run ./build.sh first"; exit 1; }

echo "▸ Staging…"
rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Give the mounted volume the app's icon.
if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "$STAGING/.VolumeIcon.icns"
    SetFile -a C "$STAGING" 2>/dev/null || true
fi

echo "▸ Building $DMG…"
hdiutil create \
    -volname "$VOLNAME" \
    -srcfolder "$STAGING" \
    -fs HFS+ \
    -format UDZO \
    -ov "$DMG" >/dev/null

rm -rf "$STAGING"
echo "✓ Built $(pwd)/$DMG"
du -h "$DMG" | cut -f1 | xargs echo "  size:"
