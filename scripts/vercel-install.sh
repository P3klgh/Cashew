#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.22.0"
FLUTTER_HOME="$HOME/flutter"

if [ ! -d "$FLUTTER_HOME" ]; then
  echo "Installing Flutter $FLUTTER_VERSION..."
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
flutter precache --web --no-android --no-ios
flutter config --no-analytics
