#!/bin/bash
set -euo pipefail

APP_NAME="dict8"
INSTALL_DIR="/Applications"
REPO="qazaqninja/dict8"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "Installing $APP_NAME..."

# Get latest release download URL
ZIP_URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep -o '"browser_download_url": *"[^"]*dict8-macos.zip"' \
  | head -1 \
  | cut -d'"' -f4)

if [ -z "$ZIP_URL" ]; then
  echo "Error: Could not find release asset." >&2
  exit 1
fi

echo "Downloading from $ZIP_URL..."
curl -fsSL -o "$TMP_DIR/dict8-macos.zip" "$ZIP_URL"

echo "Extracting..."
ditto -xk "$TMP_DIR/dict8-macos.zip" "$TMP_DIR"

# Remove existing installation
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
  echo "Removing existing $APP_NAME.app..."
  rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi

echo "Installing to $INSTALL_DIR..."
mv "$TMP_DIR/$APP_NAME.app" "$INSTALL_DIR/"

# Clear Gatekeeper quarantine (ad-hoc signed app)
xattr -cr "$INSTALL_DIR/$APP_NAME.app"

echo ""
echo "$APP_NAME installed successfully!"
echo ""
echo "Before launching, grant these permissions in System Settings > Privacy & Security:"
echo "  - Accessibility (for global hotkey and text pasting)"
echo "  - Microphone (for speech capture)"
echo "  - Speech Recognition (for on-device transcription)"
echo ""
echo "Launch with: open /Applications/$APP_NAME.app"
