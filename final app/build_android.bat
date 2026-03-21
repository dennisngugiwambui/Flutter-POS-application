@echo off
REM Pixel POS - Build Android APK + AAB, replace files in "final app" (run from project root)
cd /d "%~dp0\.."

set BUILD_NAME=1.0.3
set BUILD_NUMBER=4

echo Cleaning and fetching...
call flutter clean
call flutter pub get
if errorlevel 1 exit /b 1

echo Analyzing...
call flutter analyze --no-fatal-infos --no-fatal-warnings
if errorlevel 1 exit /b 1

echo Tests...
call flutter test
if errorlevel 1 exit /b 1

echo Building APK...
call flutter build apk --release --build-name=%BUILD_NAME% --build-number=%BUILD_NUMBER%
if errorlevel 1 exit /b 1

echo Building AAB...
call flutter build appbundle --release --build-name=%BUILD_NAME% --build-number=%BUILD_NUMBER%
if errorlevel 1 exit /b 1

REM Remove old Android artifacts (keep README, SQL, scripts)
for %%F in ("final app\Pixel_POS_android_*.apk" "final app\Pixel_POS_android_*.aab" "final app\app-release.apk") do if exist %%F del /F /Q %%F

set APK_OUT=final app\Pixel_POS_android_%BUILD_NAME%_build%BUILD_NUMBER%.apk
set AAB_OUT=final app\Pixel_POS_android_%BUILD_NAME%_build%BUILD_NUMBER%.aab

copy /Y "build\app\outputs\flutter-apk\app-release.apk" "%APK_OUT%"
if errorlevel 1 exit /b 1

if exist "build\app\outputs\bundle\release\app-release.aab" (
  copy /Y "build\app\outputs\bundle\release\app-release.aab" "%AAB_OUT%"
)

echo.
echo APK: %APK_OUT%
echo AAB: %AAB_OUT%
echo Done.
