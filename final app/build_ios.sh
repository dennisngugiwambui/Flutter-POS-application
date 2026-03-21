#!/bin/bash
# Pixel POS – Build iOS IPA (run on macOS with Xcode only)
set -e
cd "$(dirname "$0")/.."
BUILD_NAME=1.0.3
BUILD_NUMBER=4
echo "Building Pixel POS for iOS (build-name=$BUILD_NAME build-number=$BUILD_NUMBER)..."
flutter clean
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build ipa --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"
IPA=$(find build/ios/ipa -name "*.ipa" -type f 2>/dev/null | head -1)
DEST="final app/Pixel_POS_ios_${BUILD_NAME}_build${BUILD_NUMBER}.ipa"
rm -f "final app"/Pixel_POS_ios_*.ipa 2>/dev/null || true
if [ -n "$IPA" ]; then
  cp "$IPA" "$DEST"
  echo "Done. IPA saved to: $DEST"
else
  echo "IPA not found. Open ios/Runner.xcworkspace in Xcode, set Signing & Capabilities, then run flutter build ipa again."
  exit 1
fi
