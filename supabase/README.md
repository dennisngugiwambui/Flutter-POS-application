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
