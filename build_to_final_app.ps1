# Build Pixel POS (Android APK + AAB) and replace artifacts in "final app"
# Version must match pubspec.yaml (name: Pixel_POS_android_<build-name>_build<build-number>)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$buildName = "1.0.3"
$buildNumber = "4"
$finalDir = Join-Path $PSScriptRoot "final app"

Write-Host "flutter clean + pub get..." -ForegroundColor Cyan
flutter clean
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Analyzing..." -ForegroundColor Cyan
flutter analyze --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Running tests..." -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Building release APK (build-name=$buildName build-number=$buildNumber)..." -ForegroundColor Cyan
flutter build apk --release --build-name=$buildName --build-number=$buildNumber
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Building release App Bundle..." -ForegroundColor Cyan
flutter build appbundle --release --build-name=$buildName --build-number=$buildNumber
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not (Test-Path $finalDir)) { New-Item -ItemType Directory -Path $finalDir | Out-Null }

# Remove previous Android deliverables in final app (keep docs, SQL, scripts)
Get-ChildItem -Path $finalDir -File -ErrorAction SilentlyContinue | Where-Object {
  $_.Name -match '^Pixel_POS_android_.*\.(apk|aab)$' -or $_.Name -eq 'app-release.apk'
} | Remove-Item -Force

$apkSrc = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk\app-release.apk"
$aabSrc = Join-Path $PSScriptRoot "build\app\outputs\bundle\release\app-release.aab"
$apkDest = Join-Path $finalDir "Pixel_POS_android_${buildName}_build${buildNumber}.apk"
$aabDest = Join-Path $finalDir "Pixel_POS_android_${buildName}_build${buildNumber}.aab"

Copy-Item -Path $apkSrc -Destination $apkDest -Force
Write-Host "APK: $apkDest" -ForegroundColor Green
if (Test-Path $aabSrc) {
  Copy-Item -Path $aabSrc -Destination $aabDest -Force
  Write-Host "AAB: $aabDest" -ForegroundColor Green
}

Write-Host "Done." -ForegroundColor Green
