#!/bin/bash
# Package TuneBar.app into a styled "drag to Applications" .dmg installer.
set -euo pipefail
cd "$(dirname "$0")"

APP="TuneBar.app"
VOLNAME="调条 TuneBar"
DMG="TuneBar-1.0.dmg"
RW=".rw.dmg"
STAGING=".dmg_staging"
MOUNT="/Volumes/$VOLNAME"

[ -d "$APP" ] || { echo "✗ $APP not found — run ./build.sh first"; exit 1; }

echo "▸ Staging…"
rm -rf "$STAGING" "$DMG" "$RW"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Give the mounted volume the app's own icon.
if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "$STAGING/.VolumeIcon.icns"
    SetFile -a C "$STAGING" 2>/dev/null || true
fi

echo "▸ Creating writable image…"
hdiutil create -volname "$VOLNAME" -srcfolder "$STAGING" \
    -fs HFS+ -format UDRW -ov "$RW" >/dev/null

DEV="$(hdiutil attach -readwrite -noverify -noautoopen "$RW" | grep -E '^/dev/' | head -1 | awk '{print $1}')"
sleep 1

echo "▸ Laying out window (Finder)…"
osascript <<OSA 2>/dev/null || echo "  (Finder layout skipped — DMG still works)"
tell application "Finder"
    tell disk "$VOLNAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 150, 740, 480}
        set vo to the icon view options of container window
        set arrangement of vo to not arranged
        set icon size of vo to 112
        set text size of vo to 12
        set position of item "$APP" of container window to {150, 175}
        set position of item "Applications" of container window to {400, 175}
        update without registering applications
        delay 1
        close
    end tell
end tell
OSA

sync
hdiutil detach "$DEV" >/dev/null 2>&1 || hdiutil detach "$MOUNT" >/dev/null 2>&1 || true

echo "▸ Compressing…"
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null

rm -rf "$STAGING" "$RW"
echo "✓ Built $(pwd)/$DMG"
du -h "$DMG" | cut -f1 | xargs echo "  size:"
