# =============================================================================
# RUN IN POWERSHELL (Terminal), NOT in Supabase SQL Editor.
# SQL Editor only accepts SQL — pasting this file causes: syntax error near "$".
#
# Database SQL to run in Dashboard → SQL Editor is in:
#   supabase/migrations/*.sql   (e.g. 20260321140000_mpesa_receipt_column.sql)
# =============================================================================
#
# Run once: supabase login
# Optional CI: set SUPABASE_ACCESS_TOKEN in environment
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

npx --yes supabase link --project-ref eubbmivxtdyvunyblrhd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

npx --yes supabase functions deploy mpesa-stk-push
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

npx --yes supabase functions deploy mpesa-callback
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

npx --yes supabase functions deploy admin-create-user
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Done. Deployed: mpesa-stk-push, mpesa-callback, admin-create-user."
