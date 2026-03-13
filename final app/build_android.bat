@echo off
REM Pixel POS - Build Android APK and AAB, copy to final app (run from project root)
cd /d "%~dp0\.."
echo Building Pixel POS for Android...
call flutter clean
call flutter pub get
call flutter build apk --release --build-name=1.0.0 --build-number=1
if not exist "build\app\outputs\flutter-apk\app-release.apk" (
  echo APK not found. Build may have failed.
  exit /b 1
)
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "final app\Pixel_POS_android_1.0.0.apk"
echo APK saved to: final app\Pixel_POS_android_1.0.0.apk

call flutter build appbundle --release --build-name=1.0.0 --build-number=1
if exist "build\app\outputs\bundle\release\app-release.aab" (
  copy /Y "build\app\outputs\bundle\release\app-release.aab" "final app\Pixel_POS_android_1.0.0.aab"
  echo AAB saved to: final app\Pixel_POS_android_1.0.0.aab
)
echo Done.
