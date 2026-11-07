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

# macOS doesn't put ~/.local/bin on the PATH, so add it to the shell's startup file.
case ":$PATH:" in
  *":$dir:"*) ;;
  *)
    case "$(basename "${SHELL:-/bin/zsh}")" in
      zsh)  rc="$HOME/.zshrc" ;;
      bash) rc="$HOME/.bash_profile" ;;
      *)    rc="" ;;
    esac
    line="export PATH=\"$dir:\$PATH\"  # added by the pitchside installer"
    if [ -z "$rc" ]; then
      echo
      echo "Add $dir to your PATH to run 'pitchside' from anywhere:"
      echo "  export PATH=\"$dir:\$PATH\""
    else
      if grep -qF "added by the pitchside installer" "$rc" 2>/dev/null; then
        echo "$dir is already set up in $rc."
      else
        printf '\n%s\n' "$line" >> "$rc"
        echo "Added $dir to your PATH in $rc."
      fi
      echo "Open a NEW Terminal window (or run: source $rc) before using it."
    fi
    ;;
esac

echo
echo "Then type: pitchside   (the first run helps you get a free API key)"
