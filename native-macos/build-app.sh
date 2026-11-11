#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGE="$ROOT/native-macos"
OUTPUT="$ROOT/release/Stroke.app"

swift build --package-path "$PACKAGE" --configuration release
BIN_DIR="$(swift build --package-path "$PACKAGE" --configuration release --show-bin-path)"

rm -rf "$OUTPUT"
mkdir -p "$OUTPUT/Contents/MacOS" "$OUTPUT/Contents/Resources"
cp "$BIN_DIR/Stroke" "$OUTPUT/Contents/MacOS/Stroke"
cp "$ROOT/app/app.icns" "$OUTPUT/Contents/Resources/Stroke.icns"

cat > "$OUTPUT/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Stroke</string>
    <key>CFBundleIdentifier</key>
    <string>li.llllll.stroke</string>
    <key>CFBundleName</key>
    <string>Stroke</string>
    <key>CFBundleDisplayName</key>
    <string>Stroke</string>
    <key>CFBundleIconFile</key>
    <string>Stroke</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

printf 'Built native macOS app: %s\n' "$OUTPUT"
printf 'Architecture: %s\n' "$(uname -m)"
