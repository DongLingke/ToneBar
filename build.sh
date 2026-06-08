#!/bin/bash
# Build ToneBar and assemble a runnable .app bundle.
set -euo pipefail

cd "$(dirname "$0")"

CONFIG="release"
APP="ToneBar.app"
BIN="ToneBar"

echo "▸ Compiling ($CONFIG)…"
swift build -c "$CONFIG"

BINPATH="$(swift build -c "$CONFIG" --show-bin-path)/$BIN"

echo "▸ Assembling $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp "$BINPATH" "$APP/Contents/MacOS/$BIN"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

echo "▸ Ad-hoc signing…"
codesign --force --sign - "$APP" >/dev/null 2>&1 || echo "  (codesign skipped)"

echo "✓ Built $APP"
echo "  Run with:  open $APP"
echo "  Install :  cp -R $APP /Applications/"
