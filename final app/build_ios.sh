#!/bin/bash
# Pixel POS – Build iOS IPA (run on macOS with Xcode only)
set -e
cd "$(dirname "$0")/.."
echo "Building Pixel POS for iOS..."
flutter clean
flutter pub get
flutter build ipa --build-name=1.0.1 --build-number=2
IPA=$(find build/ios/ipa -name "*.ipa" -type f 2>/dev/null | head -1)
if [ -n "$IPA" ]; then
  cp "$IPA" "final app/Pixel_POS_ios_1.0.1.ipa"
  echo "Done. IPA saved to: final app/Pixel_POS_ios_1.0.1.ipa"
else
  echo "IPA not found. Check build/ios/ipa/ after opening ios/Runner.xcworkspace in Xcode and configuring signing."
fi
