#!/usr/bin/env bash
# Installs the latest pitchside release (macOS, Apple Silicon).
set -euo pipefail

REPO="josejmorales/pitchside-releases"

if [ "$(uname -s)-$(uname -m)" != "Darwin-arm64" ]; then
  echo "This installer supports macOS on Apple Silicon only (found $(uname -s) $(uname -m))." >&2
  exit 1
fi

asset="pitchside-macos-arm64"
dir="${PITCHSIDE_INSTALL_DIR:-$HOME/.local/bin}"
base="https://github.com/$REPO/releases/latest/download"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading pitchside..."
curl -fsSL "$base/$asset" -o "$tmp/$asset"
curl -fsSL "$base/SHA256SUMS" -o "$tmp/SHA256SUMS"

expected="$(awk -v a="$asset" '$2 == a { print $1 }' "$tmp/SHA256SUMS")"
actual="$(shasum -a 256 "$tmp/$asset" | awk '{ print $1 }')"
if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
  echo "Checksum mismatch, not installing." >&2
  exit 1
fi

mkdir -p "$dir"
install -m 755 "$tmp/$asset" "$dir/pitchside"
echo "Installed pitchside to $dir/pitchside"

case ":$PATH:" in
  *":$dir:"*) ;;
  *)
    echo
    echo "$dir isn't on your PATH yet. Add it with:"
    echo "  echo 'export PATH=\"$dir:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
    ;;
esac

echo
echo "Run: pitchside   (then 'apikey set' to add your football-data.org key)"
