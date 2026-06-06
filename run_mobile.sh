#!/bin/bash
# HarmonyAI Mobile App Runner
# Run this script once Flutter is installed

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/flutter_app"

# Find Flutter
FLUTTER_BIN=""
for candidate in \
  "$HOME/flutter/bin/flutter" \
  "/usr/local/Caskroom/flutter/3.44.1/flutter/bin/flutter" \
  "/opt/homebrew/Caskroom/flutter/3.44.1/flutter/bin/flutter" \
  "$(which flutter 2>/dev/null)"; do
  if [ -x "$candidate" ]; then
    FLUTTER_BIN="$candidate"
    break
  fi
done

if [ -z "$FLUTTER_BIN" ]; then
  echo "❌ Flutter not found. Run: brew install --cask flutter"
  exit 1
fi

export PATH="$(dirname $FLUTTER_BIN):$PATH"
echo "✓ Flutter found: $FLUTTER_BIN"

# Scaffold iOS/Android if missing
cd "$APP_DIR"
if [ ! -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
  echo "→ Scaffolding iOS/Android platform files..."
  # Backup our lib
  cp -r lib /tmp/harmonyai_lib_backup
  flutter create --project-name harmonyai --platforms ios,android .
  # Restore our lib (flutter create overwrites main.dart)
  rm -rf lib
  cp -r /tmp/harmonyai_lib_backup lib
  rm -rf /tmp/harmonyai_lib_backup
  echo "✓ Platform files created"
fi

# Install deps
echo "→ Running flutter pub get..."
flutter pub get

# Boot iPhone 14 simulator
echo "→ Booting iPhone 14 simulator..."
DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 14 (" | grep -v "Plus\|Pro\|unavailable" | head -1 | grep -oE '[A-F0-9-]{36}')
if [ -n "$DEVICE_ID" ]; then
  xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
  open -a Simulator
  sleep 3
fi

# Start Django backend in background if not running
if ! curl -s http://localhost:8000 > /dev/null 2>&1; then
  echo "→ Starting Django backend..."
  cd "$SCRIPT_DIR"
  source venv/bin/activate
  python manage.py runserver 8000 &
  sleep 2
  cd "$APP_DIR"
fi

# Run the app
echo "→ Running HarmonyAI on simulator..."
flutter run
