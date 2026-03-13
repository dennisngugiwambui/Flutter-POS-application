# Pixel POS – Release Builds

This folder contains the **release builds** for Pixel POS.

## Contents

| File | Description |
|------|-------------|
| **Pixel_POS_android_1.0.1.apk** | Android release APK – install on devices or sideload (~74 MB) |
| **Pixel_POS_ios_1.0.1.ipa** | iOS build – **must be created on a Mac** (see below) |
| **BUILD_INSTRUCTIONS.md** | How to reproduce these builds |
| **SUPABASE_RUN_THIS_FOR_IMAGES.sql** | Run in Supabase SQL Editor for product image upload (RLS) |
| **build_android.bat** | Script to rebuild APK and copy here (Windows) |
| **build_ios.sh** | Script to build IPA and copy here (macOS only) |

## Android (APK)

- **Built:** `flutter build apk --release --build-name=1.0.1 --build-number=2`
- **Install:** Copy the APK to an Android device and open it (enable “Install from unknown sources” if prompted).
- **Play Store:** Use App Bundle:  
  `flutter build appbundle --release --build-name=1.0.1 --build-number=2`  
  Output: `build/app/outputs/bundle/release/app-release.aab`

## iOS (IPA) – build on Mac only

**iOS cannot be built on Windows.** Use a Mac with Xcode and Flutter.

1. Open Terminal on the Mac and go to the project root (parent of `final app`).
2. Run:
   ```bash
   chmod +x "final app/build_ios.sh"
   "./final app/build_ios.sh"
   ```
   Or manually:
   ```bash
   flutter clean
   flutter pub get
   flutter build ipa --build-name=1.0.1 --build-number=2
   ```
3. Copy the IPA from `build/ios/ipa/` into this folder as **Pixel_POS_ios_1.0.1.ipa**.

You need an Apple Developer account, signing certificate, and provisioning profile (configure in Xcode via `ios/Runner.xcworkspace`).

---

**Version:** 1.0.1 (2)  
**App name:** Pixel POS
