# Build Pixel POS and copy APK to "final app" folder
Set-Location $PSScriptRoot

Write-Host "Building release APK..." -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$src = "build\app\outputs\flutter-apk\app-release.apk"
$destDir = "final app"
$dest = "$destDir\app-release.apk"

if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }
Copy-Item -Path $src -Destination $dest -Force
Write-Host "Done. APK copied to: $dest" -ForegroundColor Green
Write-Host "Full path: $(Resolve-Path $dest)" -ForegroundColor Gray
