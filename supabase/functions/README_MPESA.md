# M-Pesa Edge Functions

## 1. Database (run in order)

In **Supabase Dashboard → SQL Editor**, run migrations from `supabase/migrations/`:

1. `20260316000000_mpesa_full_config.sql` — `shop_configs` M-Pesa columns + `mpesa_callback_results` base table  
2. `20260321140000_mpesa_receipt_column.sql` — adds `mpesa_receipt_number` (optional but recommended)

You can also use the standalone script at repo root `mpesa_callback_results.sql` for reference; prefer migrations for production.

## 2. JWT verification (`config.toml`)

Each function folder includes `config.toml`:

- **`mpesa-callback/config.toml`** — `verify_jwt = false` so **Safaricom** can POST without a Supabase JWT (required).
- **`mpesa-stk-push/config.toml`** — `verify_jwt = true` so only **authenticated** app users can trigger STK.

CLI deploy picks these up automatically:

```bash
npm install -g supabase
supabase login
supabase link --project-ref eubbmivxtdyvunyblrhd
supabase functions deploy mpesa-stk-push
supabase functions deploy mpesa-callback
```

Or explicitly:

```bash
supabase functions deploy mpesa-callback --no-verify-jwt
```

(Only needed if you do not use `config.toml`; the repo’s `config.toml` already disables JWT for the callback.)

## 3. Callback URL

Set **Shop Settings → M-Pesa Callback URL** to:

`https://eubbmivxtdyvunyblrhd.supabase.co/functions/v1/mpesa-callback`

Register the **same URL** in the **Safaricom Daraja** portal as the Lipa Na M-Pesa Online / STK callback URL.

## 4. Shortcode, Till, and sandbox

- **Sandbox:** Turn on **Sandbox** in Shop Settings (or set `mpesa_is_sandbox` in `shop_configs`). The Edge Function then calls `https://sandbox.safaricom.co.ke`. Using **production** Daraja (`api.safaricom.co.ke`) with **sandbox** consumer keys causes errors such as **500.001.1001 — Merchant does not exist**.
- **Buy Goods:** Put the **Paybill / head office shortcode** in **Shortcode** and the **Till number** in **Till Number**. The passkey in Daraja is tied to the shortcode; `PartyB` in STK must be the Till when both differ.
- **Pay Bill:** Use transaction type **CustomerPayBillOnline**; shortcode is the Paybill; `PartyB` matches Paybill.

Redeploy after changing `mpesa-stk-push/index.ts`:

`supabase functions deploy mpesa-stk-push`

## 5. Flutter

- `lib/features/mpesa/mpesa_service.dart` — `MpesaService.pay()` (used from checkout).  
- `lib/features/sale/data/mpesa_repository.dart` — invokes `mpesa-stk-push` and polls `mpesa_callback_results`.

## Flow

1. App → `mpesa-stk-push` → Daraja OAuth + STK push.  
2. Customer enters PIN; Safaricom → `mpesa-callback` → upsert `mpesa_callback_results` (including `mpesa_receipt_number` when present).  
3. App polls until a row exists for `checkout_request_id`, then completes the sale.
