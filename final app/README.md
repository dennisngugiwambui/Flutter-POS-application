# Pixel POS – Release builds

This folder holds **release deliverables** for Pixel POS (Android APK/AAB; iOS IPA when built on a Mac).

## Current release (UI refresh + shop kit)

| File | Description |
|------|-------------|
| **Pixel_POS_android_1.0.3_build6.apk** | Android release APK – sideload / internal testing |
| **Pixel_POS_android_1.0.3_build4.aab** | Google Play App Bundle (rebuild with `build_android.bat` if needed) |
| **Pixel_POS_ios_1.0.3_build6.ipa** | iOS – **build on macOS** (see `iOS_BUILD_NOTE.txt`; not produced on Windows) |

> If those files are missing, run **`build_android.bat`** (Windows) or **`build_to_final_app.ps1`** from the project root, or on a Mac **`bash "final app/build_ios.sh"`**.

## Scripts

| File | Use |
|------|-----|
| **BUILD_INSTRUCTIONS.md** | Manual `flutter build` commands |
| **build_android.bat** | Windows: clean, test, APK + AAB → this folder |
| **build_to_final_app.ps1** | PowerShell: same as batch |
| **build_ios.sh** | macOS only: IPA → this folder |
| **SUPABASE_RUN_THIS_FOR_IMAGES.sql** | Supabase SQL for product image RLS |

## Version

- **1.0.3** (build **6**) – matches `pubspec.yaml` `version: 1.0.3+6`
- **App display name:** Pixel POS

## iOS note

iOS **cannot** be built on Windows. Use Xcode on a Mac; see **`iOS_BUILD_NOTE.txt`**.
