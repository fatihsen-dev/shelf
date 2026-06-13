#!/usr/bin/env bash
# Full release pipeline: build, sign, notarize, staple, package.
# Output: ./.build/release/Shelf-<version>.zip ready to upload to GitHub Releases.
#
# Required environment variables:
#   SHELF_SIGN_IDENTITY   e.g. "Developer ID Application: Fatih Sen (TEAMID1234)"
#   SHELF_APPLE_ID        Apple ID email used for notarytool
#   SHELF_TEAM_ID         10-character Team ID
#   SHELF_APP_PASSWORD    App-specific password from appleid.apple.com
#
# Recommended: store credentials in keychain once, then this script uses them:
#   xcrun notarytool store-credentials shelf-notary \
#     --apple-id "$SHELF_APPLE_ID" --team-id "$SHELF_TEAM_ID" --password "$SHELF_APP_PASSWORD"
# After that you can drop SHELF_APPLE_ID / SHELF_APP_PASSWORD and set SHELF_NOTARY_PROFILE=shelf-notary.
set -euo pipefail

: "${SHELF_NOTARY_PROFILE:=shelf}"
: "${SHELF_SIGN_IDENTITY:=Developer ID Application: Fatih Sen (VWY82MA6G6)}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/.build/release/Shelf.app"
ENTITLEMENTS="$ROOT/Sources/Shelf/Resources/Shelf.entitlements"
INFO_PLIST="$APP_DIR/Contents/Info.plist"

: "${SHELF_SIGN_IDENTITY:?Missing SHELF_SIGN_IDENTITY (e.g. 'Developer ID Application: Name (TEAMID)')}"

# Resolve version from Info.plist
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Sources/Shelf/Resources/Info.plist")"
ARCHIVE="$ROOT/.build/release/Shelf-$VERSION.zip"

echo "→ Building universal release bundle..."
bash "$ROOT/scripts/build-release.sh"

echo "→ Code signing with hardened runtime..."
codesign --force --options runtime --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$SHELF_SIGN_IDENTITY" \
    "$APP_DIR"

echo "→ Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "→ Packaging for notarization..."
rm -f "$ARCHIVE"
ditto -c -k --keepParent "$APP_DIR" "$ARCHIVE"

echo "→ Submitting to Apple notary service..."
if [[ -n "${SHELF_NOTARY_PROFILE:-}" ]]; then
    xcrun notarytool submit "$ARCHIVE" --keychain-profile "$SHELF_NOTARY_PROFILE" --wait
else
    : "${SHELF_APPLE_ID:?Missing SHELF_APPLE_ID (or set SHELF_NOTARY_PROFILE)}"
    : "${SHELF_TEAM_ID:?Missing SHELF_TEAM_ID}"
    : "${SHELF_APP_PASSWORD:?Missing SHELF_APP_PASSWORD}"
    xcrun notarytool submit "$ARCHIVE" \
        --apple-id "$SHELF_APPLE_ID" \
        --team-id "$SHELF_TEAM_ID" \
        --password "$SHELF_APP_PASSWORD" \
        --wait
fi

echo "→ Stapling notarization ticket..."
xcrun stapler staple "$APP_DIR"
xcrun stapler validate "$APP_DIR"

echo "→ Re-zipping stapled bundle..."
rm -f "$ARCHIVE"
ditto -c -k --keepParent "$APP_DIR" "$ARCHIVE"

SHA="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"

echo ""
echo "✓ Release ready:"
echo "    File:    $ARCHIVE"
echo "    Version: $VERSION"
echo "    SHA256:  $SHA"
echo ""
echo "Next: upload $ARCHIVE to GitHub release v$VERSION and run scripts/update-cask.sh"
