# Runs Supabase CLI with cwd = Pixel POS repo root (so supabase/functions is found).
# Usage: .\scripts\supabase-cli\supabase.ps1 login
#        .\scripts\supabase-cli\supabase.ps1 functions deploy admin-create-user
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $here "..\..")).Path
$bin = Join-Path $here "node_modules\.bin\supabase.cmd"
if (-not (Test-Path $bin)) {
    Write-Host "Supabase CLI not installed here. Run:" -ForegroundColor Yellow
    Write-Host "  cd `"$here`"" -ForegroundColor Cyan
    Write-Host "  npm install" -ForegroundColor Cyan
    exit 1
}
Push-Location $repoRoot
try {
    & $bin @args
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
