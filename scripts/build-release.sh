#!/usr/bin/env bash
# Build a universal (arm64 + x86_64) release .app bundle.
# Output: ./.build/release/Shelf.app
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/.build/release/Shelf.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RES="$CONTENTS/Resources"

cd "$ROOT"

echo "→ Building arm64..."
swift build -c release --arch arm64
ARM_BIN="$(swift build -c release --arch arm64 --show-bin-path)/Shelf"

echo "→ Building x86_64..."
swift build -c release --arch x86_64
INTEL_BIN="$(swift build -c release --arch x86_64 --show-bin-path)/Shelf"

echo "→ Assembling .app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RES"

# Create universal binary
lipo -create -output "$MACOS/Shelf" "$ARM_BIN" "$INTEL_BIN"
chmod +x "$MACOS/Shelf"

# Refresh icons from source PNG (idempotent)
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

cp "$ROOT/Sources/Shelf/Resources/Info.plist" "$CONTENTS/Info.plist"
cp "$ROOT/Sources/Shelf/Resources/AppIcon.icns" "$RES/AppIcon.icns"
cp "$ROOT/Sources/Shelf/Resources/MenubarIcon.png" "$RES/MenubarIcon.png"

echo "✓ Built: $APP_DIR"
file "$MACOS/Shelf"
