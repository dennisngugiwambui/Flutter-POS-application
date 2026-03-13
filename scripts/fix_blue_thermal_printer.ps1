# Re-apply namespace fix for blue_thermal_printer (required after flutter pub get).
# Run from project root: .\scripts\fix_blue_thermal_printer.ps1

$buildGradle = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\blue_thermal_printer-1.2.3\android\build.gradle"
if (-not (Test-Path $buildGradle)) {
    Write-Host "blue_thermal_printer not found in pub cache. Run 'flutter pub get' first."
    exit 1
}
$content = Get-Content $buildGradle -Raw
if ($content -match "namespace 'id.kakzaki.blue_thermal_printer'") {
    Write-Host "Namespace already present. No change needed."
    exit 0
}
$content = $content.Replace("android {`r`n    compileSdkVersion 31", "android {`r`n    namespace 'id.kakzaki.blue_thermal_printer'`r`n    compileSdkVersion 31")
$content = $content.Replace("android {`n    compileSdkVersion 31", "android {`n    namespace 'id.kakzaki.blue_thermal_printer'`n    compileSdkVersion 31")
Set-Content $buildGradle -Value $content -NoNewline
Write-Host "Added namespace to blue_thermal_printer. You can run 'flutter run' now."
