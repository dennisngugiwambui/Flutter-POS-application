# Pixel POS – Build instructions

Run from the **project root** (`POS/`), same folder as `pubspec.yaml`.

**Version** is defined in `pubspec.yaml` (e.g. `1.0.3+4` → `--build-name=1.0.3 --build-number=4`).

## Prerequisites

- Flutter SDK on `PATH`
- **Android:** Android SDK (for APK/AAB)
- **iOS:** macOS + Xcode + Apple Developer (for IPA only)

## Quick: copy builds into `final app/`

- **Windows (CMD):** `final app\build_android.bat`
- **Windows (PowerShell):** `.\build_to_final_app.ps1`
- **macOS (iOS):** `chmod +x "final app/build_ios.sh" && "./final app/build_ios.sh"`

These scripts remove older `Pixel_POS_android_*.apk` / `*.aab` (and iOS `Pixel_POS_ios_*.ipa` for the shell script) in `final app/` before copying the new outputs.

## Android APK

```bash
flutter clean
flutter pub get
flutter test
flutter build apk --release --build-name=1.0.3 --build-number=4
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`  
Copy to `final app/Pixel_POS_android_1.0.3_build4.apk` (or run the scripts above).

## Android App Bundle (Play Store)

```bash
flutter build appbundle --release --build-name=1.0.3 --build-number=4
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

## iOS IPA (macOS only)

```bash
flutter build ipa --build-name=1.0.3 --build-number=4
```

1. Open `ios/Runner.xcworkspace` in Xcode → **Signing & Capabilities** → Team / bundle ID.
2. Copy the IPA from `build/ios/ipa/` to `final app/Pixel_POS_ios_1.0.3_build4.ipa` (or use `build_ios.sh`).

## Optional: obfuscation

```bash
flutter build apk --release --obfuscate --split-debug-info=final_app_debug_info/android --build-name=1.0.3 --build-number=4
```

Keep the `split-debug-info` output for crash symbolication.
