#!/usr/bin/env bash
# Build, sign, and package Shelf for the Mac App Store.
# Output: ./.build/release/Shelf-<version>.pkg ready to upload via Transporter or xcrun altool.
#
# Required environment variables (set defaults below for convenience):
#   SHELF_APPSTORE_APP_IDENTITY        "Apple Distribution: Fatih Sen (TEAMID)"
#   SHELF_APPSTORE_INSTALLER_IDENTITY  "3rd Party Mac Developer Installer: Fatih Sen (TEAMID)"
#   SHELF_APPSTORE_PROVISION           Path to embedded.provisionprofile downloaded from Developer portal
set -euo pipefail

: "${SHELF_APPSTORE_APP_IDENTITY:=Apple Distribution: Fatih Sen (VWY82MA6G6)}"
: "${SHELF_APPSTORE_INSTALLER_IDENTITY:=3rd Party Mac Developer Installer: Fatih Sen (VWY82MA6G6)}"
: "${SHELF_APPSTORE_PROVISION:=$HOME/Library/MobileDevice/Provisioning Profiles/Shelf_App_Store.provisionprofile}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/.build/release/Shelf.app"
ENTITLEMENTS="$ROOT/Sources/Shelf/Resources/Shelf-AppStore.entitlements"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Sources/Shelf/Resources/Info.plist")"
PKG="$ROOT/.build/release/Shelf-$VERSION.pkg"

if [[ ! -f "$SHELF_APPSTORE_PROVISION" ]]; then
    echo "✗ Provisioning profile not found at: $SHELF_APPSTORE_PROVISION"
    echo "  Download it from https://developer.apple.com/account/resources/profiles/list"
    echo "  Or set SHELF_APPSTORE_PROVISION to the correct path."
    exit 1
fi

echo "→ Building universal release bundle..."
bash "$ROOT/scripts/build-release.sh"

echo "→ Embedding provisioning profile..."
cp "$SHELF_APPSTORE_PROVISION" "$APP_DIR/Contents/embedded.provisionprofile"
xattr -cr "$APP_DIR"

echo "→ Code signing with App Store entitlements..."
codesign --force --options runtime --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$SHELF_APPSTORE_APP_IDENTITY" \
    "$APP_DIR"

echo "→ Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "→ Building installer package..."
rm -f "$PKG"
productbuild --component "$APP_DIR" /Applications \
    --sign "$SHELF_APPSTORE_INSTALLER_IDENTITY" \
    "$PKG"

echo ""
echo "✓ App Store package ready:"
echo "    File:    $PKG"
echo "    Version: $VERSION"
echo ""
echo "Upload with Transporter.app or:"
echo "    xcrun altool --upload-app --type osx --file \"$PKG\" \\"
echo "      --apple-id \"\$SHELF_APPLE_ID\" --password \"\$SHELF_APP_PASSWORD\""
