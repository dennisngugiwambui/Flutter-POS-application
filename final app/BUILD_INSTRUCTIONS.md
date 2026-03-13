# Pixel POS – Build Instructions

Use these commands from the **project root** (`POS/`).

## Prerequisites

- Flutter SDK installed and on PATH
- Android: Android SDK (for APK)
- iOS: macOS with Xcode and Apple Developer account (for IPA)

## Android APK (Windows / macOS / Linux)

```bash
flutter clean
flutter pub get
flutter build apk --release --build-name=1.0.0 --build-number=1
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

Copy to this folder and rename, e.g.:

- `Pixel_POS_android_1.0.0.apk`

### Optional: obfuscation and debug symbols

```bash
flutter build apk --release --obfuscate --split-debug-info=final\ app/debug-info-android --build-name=1.0.0 --build-number=1
```

Keep the `debug-info-android` folder for symbolication if you get crash reports.

### App Bundle (for Google Play)

```bash
flutter build appbundle --release --build-name=1.0.0 --build-number=1
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

## iOS IPA (macOS only)

```bash
flutter clean
flutter pub get
flutter build ipa --build-name=1.0.0 --build-number=1
```

**Output:** `build/ios/ipa/` (e.g. `Pixel POS.ipa` or `Runner.ipa`)

Copy the IPA into this folder, e.g.:

- `Pixel_POS_ios_1.0.0.ipa`

Before building:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the Runner target → Signing & Capabilities.
3. Choose your Team and ensure “Automatically manage signing” is enabled (or set provisioning profile).
4. Confirm the bundle ID matches your Apple Developer app.

---

**Version format:** `--build-name=1.0.0` (user-facing), `--build-number=1` (build index).
