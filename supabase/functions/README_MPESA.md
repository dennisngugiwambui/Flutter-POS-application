# M-Pesa Edge Functions

## Deploy

From project root (where `supabase/` lives):

```bash
supabase functions deploy mpesa-stk-push
supabase functions deploy mpesa-callback
```

## Callback URL for live

After deploying, set **Callback URL** in Shop Settings to your project’s callback endpoint:

- **Production:** `https://YOUR_PROJECT_REF.supabase.co/functions/v1/mpesa-callback`

Example (replace with your project ref):

- `https://eubbmivxtdyvunyblrhd.supabase.co/functions/v1/mpesa-callback`

Register this same URL in the Safaricom Daraja portal as the Lipa Na M-Pesa Online callback URL so Safaricom can POST STK results to it.

## Flow

1. App calls `mpesa-stk-push` with amount, phone, reference.
2. Edge Function reads M-Pesa config from `shop_configs`, gets OAuth token, sends STK push to Safaricom.
3. Customer enters PIN on phone; Safaricom POSTs the result to `mpesa-callback`.
4. `mpesa-callback` writes the result to `mpesa_callback_results`.
5. App polls `mpesa_callback_results` by `checkout_request_id` until it gets the result, then shows success or failure.

## Database

Run the migration that adds M-Pesa columns to `shop_configs` and creates `mpesa_callback_results` (e.g. `20260316000000_mpesa_full_config.sql`).
