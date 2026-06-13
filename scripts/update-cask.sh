#!/usr/bin/env bash
# Render Casks/shelf.rb for the homebrew-shelf tap from the template,
# substituting version + sha256 from the latest local release artifact.
#
# Usage:
#   ./scripts/update-cask.sh ../homebrew-shelf
#
# The tap repo must contain a Casks/ directory.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAP_DIR="${1:?Usage: $0 <path-to-homebrew-shelf-tap>}"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Sources/Shelf/Resources/Info.plist")"
ARCHIVE="$ROOT/.build/release/Shelf-$VERSION.zip"

if [[ ! -f "$ARCHIVE" ]]; then
    echo "✗ Archive not found: $ARCHIVE"
    echo "  Run scripts/release.sh first."
    exit 1
fi

SHA="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"

mkdir -p "$TAP_DIR/Casks"
sed -e "s|__VERSION__|$VERSION|g" \
    -e "s|__SHA256__|$SHA|g" \
    "$ROOT/scripts/cask-template.rb" > "$TAP_DIR/Casks/shelf.rb"

echo "✓ Wrote $TAP_DIR/Casks/shelf.rb"
echo "    version: $VERSION"
echo "    sha256:  $SHA"
echo ""
echo "Next:"
echo "    cd $TAP_DIR"
echo "    git add Casks/shelf.rb"
echo "    git commit -m 'shelf $VERSION'"
echo "    git push"
