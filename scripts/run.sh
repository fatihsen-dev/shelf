#!/usr/bin/env bash
# Build SPM binary, wrap it as a .app bundle (LSUIElement), and launch.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build/Shelf.app"
CONTENTS="$BUILD_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RES="$CONTENTS/Resources"

cd "$ROOT"
swift build -c debug

BIN_PATH="$(swift build -c debug --show-bin-path)/Shelf"

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RES"

LOGO="$ROOT/assets/logo.png"
ICONSET="/tmp/shelf-icon.iconset"
rm -rf "$ICONSET" && mkdir -p "$ICONSET"
for size in 16 32 64 128 256 512; do
    sips -z $size $size "$LOGO" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
done
sips -z 32   32   "$LOGO" --out "$ICONSET/icon_16x16@2x.png"   >/dev/null
sips -z 64   64   "$LOGO" --out "$ICONSET/icon_32x32@2x.png"   >/dev/null
sips -z 256  256  "$LOGO" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 512  512  "$LOGO" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 1024 1024 "$LOGO" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET" -o "$ROOT/Sources/Shelf/Resources/AppIcon.icns"
sips -z 32 32 "$LOGO" --out "$ROOT/Sources/Shelf/Resources/MenubarIcon.png" >/dev/null

cp "$BIN_PATH" "$MACOS/Shelf"
cp "$ROOT/Sources/Shelf/Resources/Info.plist" "$CONTENTS/Info.plist"
cp "$ROOT/Sources/Shelf/Resources/AppIcon.icns" "$RES/AppIcon.icns"
cp "$ROOT/Sources/Shelf/Resources/MenubarIcon.png" "$RES/MenubarIcon.png"

# Ad-hoc sign with entitlements (needed for global event taps on modern macOS)
codesign --force --deep --sign - \
    --entitlements "$ROOT/Sources/Shelf/Resources/Shelf.entitlements" \
    "$BUILD_DIR" >/dev/null 2>&1 || true

# Kill any previous instance, launch
pkill -x Shelf 2>/dev/null || true
sleep 0.3
exec "$MACOS/Shelf"
