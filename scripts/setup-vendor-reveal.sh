#!/usr/bin/env sh
set -eu

VERSION="${1:-5.2.1}"
TAG="$VERSION"

case "$TAG" in
  v*) ;;
  *) TAG="v$TAG" ;;
esac

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
ARCHIVE="$TMP_DIR/reveal.tar.gz"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "Downloading reveal.js $TAG ..."
curl -fsSL "https://github.com/hakimel/reveal.js/archive/refs/tags/${TAG}.tar.gz" -o "$ARCHIVE"
tar -xzf "$ARCHIVE" -C "$TMP_DIR"

SRC_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d -name 'reveal.js-*' | head -n 1)"
if [ -z "$SRC_DIR" ]; then
  echo "Could not locate extracted reveal.js folder."
  exit 1
fi

DEST_DIR="$ROOT_DIR/vendor/reveal.js"
mkdir -p "$DEST_DIR"
rm -rf "$DEST_DIR/dist" "$DEST_DIR/plugin"

cp -R "$SRC_DIR/dist" "$DEST_DIR/dist"
cp -R "$SRC_DIR/plugin" "$DEST_DIR/plugin"
cp "$SRC_DIR/LICENSE" "$DEST_DIR/LICENSE"

echo "Vendor assets ready at $DEST_DIR"
