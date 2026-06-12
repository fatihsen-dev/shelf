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

cp "$BIN_PATH" "$MACOS/Shelf"
cp "$ROOT/Sources/Shelf/Resources/Info.plist" "$CONTENTS/Info.plist"

# Ad-hoc sign with entitlements (needed for global event taps on modern macOS)
codesign --force --deep --sign - \
    --entitlements "$ROOT/Sources/Shelf/Resources/Shelf.entitlements" \
    "$BUILD_DIR" >/dev/null 2>&1 || true

# Kill any previous instance, launch
pkill -x Shelf 2>/dev/null || true
open "$BUILD_DIR"
echo "Launched: $BUILD_DIR"
