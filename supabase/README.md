# Pixel POS – Supabase setup

## Why aren’t my tables in Supabase?

The SQL in this folder is **not applied automatically**. You have to run it once using one of the options below.

---

## Apply the database schema (one-time)

### Option A: Script from the repo (recommended)

From the **project root**:

1. Get your **database password** from [Supabase Dashboard](https://supabase.com/dashboard) → your project → **Settings** → **Database** (under “Database password”).
2. In a terminal:

**PowerShell:**
```powershell
cd scripts
npm install
$env:SUPABASE_DB_PASSWORD = "your_database_password_here"
node push_db.js
```

**Cmd:**
```cmd
cd scripts
npm install
set SUPABASE_DB_PASSWORD=your_database_password_here
node push_db.js
```

3. In the Dashboard go to **Storage** → **New bucket** → create **`products`** and set it to **Public**.

### Option B: Supabase Dashboard (manual)

1. Open [Supabase Dashboard](https://supabase.com/dashboard) and select your project.
2. Go to **SQL Editor** → **New query**.
3. Copy the **entire contents** of **`supabase/migrations/20260312000000_initial_schema.sql`**, paste into the editor, and click **Run**.
4. In **Storage**, create a bucket named **`products`** and set it to **Public**.

### Option C: Supabase CLI

```bash
supabase link --project-ref eubbmivxtdyvunyblrhd
supabase db push
```

Then create the **`products`** storage bucket in the Dashboard.

---

## What the migration creates

- **profiles** – user profile data (synced from Auth via trigger)
- **products** – products with barcode, prices, stock
- **shop_configs** – single-row shop settings (name, address, etc.)
- RLS policies so authenticated users can read/write as needed

---

## Edge Functions (deploy for full app behavior)

From the project root, with the [Supabase CLI](https://supabase.com/docs/guides/cli) linked to your project:

| Function | Purpose |
|----------|---------|
| `admin-create-user` | Lets an **admin** create cashier accounts from the app **without** losing their session. See `supabase/functions/README_ADMIN_CREATE_USER.md`. |
| `mpesa-stk-push` / `mpesa-callback` | M-Pesa STK push and callback. See `supabase/functions/README_MPESA.md`. |

```bash
supabase functions deploy admin-create-user
supabase functions deploy mpesa-stk-push
supabase functions deploy mpesa-callback
```

### Windows: `supabase` is not recognized

Install the **Supabase CLI** first (official options).

If you see **`scoop` is not recognized**, you have **not installed Scoop yet** — either install Scoop (Option A) or skip it and use **`npx`** (Option B below).

**Option A – Scoop (recommended on Windows)**

1. Install [Scoop](https://scoop.sh/) if you don’t have it (PowerShell):

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   irm get.scoop.sh | iex
   ```

2. Add the Supabase bucket and install the CLI:

   ```powershell
   scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
   scoop install supabase
   ```

3. Close and reopen PowerShell, then check:

   ```powershell
   supabase --version
   ```

**Option B – `npx` (needs Node.js 20+) — no Scoop required**

You don’t need a global `supabase` command. From your project folder:

```powershell
npx supabase@latest login
npx supabase@latest link --project-ref YOUR_PROJECT_REF
npx supabase@latest functions deploy admin-create-user
npx supabase@latest functions deploy mpesa-stk-push
npx supabase@latest functions deploy mpesa-callback
```

Replace `YOUR_PROJECT_REF` with the id in your Supabase dashboard URL (`https://supabase.com/dashboard/project/<project-ref>`).

**After install:** run `supabase login` and `supabase link --project-ref ...` once, then the `supabase functions deploy ...` commands above will work.

#### Windows: `npm error EBUSY` / `resource busy or locked` with `npx supabase`

That comes from the **global npx cache** under `%LocalAppData%\npm-cache\_npx` (Defender, another terminal, or a stuck install can lock it).

**Fix 1 — Use the repo’s local CLI (recommended):** see **`scripts/supabase-cli/README.md`**. Short version:

```powershell
cd C:\Users\Denno\Desktop\POS\scripts\supabase-cli
npm install
cd C:\Users\Denno\Desktop\POS
.\scripts\supabase-cli\supabase.ps1 login
.\scripts\supabase-cli\supabase.ps1 link --project-ref YOUR_PROJECT_REF
.\scripts\supabase-cli\supabase.ps1 functions deploy admin-create-user
.\scripts\supabase-cli\supabase.ps1 functions deploy mpesa-stk-push
.\scripts\supabase-cli\supabase.ps1 functions deploy mpesa-callback
```

**Fix 2 — Clear the broken npx cache** (close Cursor/VS Code terminals and any `node.exe` in Task Manager first):

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\npm-cache\_npx"
```

Then try `npx supabase@latest login` again from the project folder.
