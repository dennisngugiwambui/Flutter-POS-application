# Supabase CLI (local install)

Use this folder so **`npx supabase@latest`** does not touch the global `%LocalAppData%\npm-cache\_npx` folder (which often hits **EBUSY / resource busy** on Windows because of antivirus or locked files).

## One-time setup

In PowerShell:

```powershell
cd C:\Users\Denno\Desktop\POS\scripts\supabase-cli
npm install
```

## Run CLI from repo root (important for `supabase/functions`)

**Option A — wrapper script (easiest)**

From anywhere:

```powershell
cd C:\Users\Denno\Desktop\POS
.\scripts\supabase-cli\supabase.ps1 login
.\scripts\supabase-cli\supabase.ps1 link --project-ref YOUR_PROJECT_REF
.\scripts\supabase-cli\supabase.ps1 functions deploy admin-create-user
.\scripts\supabase-cli\supabase.ps1 functions deploy mpesa-stk-push
.\scripts\supabase-cli\supabase.ps1 functions deploy mpesa-callback
```

**Option B — manual `cd` + binary**

```powershell
cd C:\Users\Denno\Desktop\POS
.\scripts\supabase-cli\node_modules\.bin\supabase.cmd login
.\scripts\supabase-cli\node_modules\.bin\supabase.cmd link --project-ref YOUR_PROJECT_REF
.\scripts\supabase-cli\node_modules\.bin\supabase.cmd functions deploy admin-create-user
```

If `ExecutionPolicy` blocks `.ps1`, run once:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
