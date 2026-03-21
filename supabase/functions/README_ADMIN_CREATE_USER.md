# `admin-create-user` Edge Function

Creates a new Supabase Auth user (e.g. cashier) **without** calling client `signUp()`, so the **admin stays logged in**. The `on_auth_user_created` trigger still inserts a row in `profiles`.

## Deploy

From the project root (with [Supabase CLI](https://supabase.com/docs/guides/cli) linked to your project):

```bash
supabase functions deploy admin-create-user
```

The function verifies the caller with their JWT and requires `profiles.role = 'admin'` before creating users.

## Required secrets

Hosted Supabase injects `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` automatically for Edge Functions.

## App usage

The POS app calls:

`Supabase.instance.client.functions.invoke('admin-create-user', body: { ... })`

If you see a snackbar about the function missing, deploy it as above.
