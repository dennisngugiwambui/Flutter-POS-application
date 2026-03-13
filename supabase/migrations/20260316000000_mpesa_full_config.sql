-- Full M-Pesa configuration columns (Daraja API)
alter table public.shop_configs
  add column if not exists mpesa_consumer_key text default '',
  add column if not exists mpesa_consumer_secret text default '',
  add column if not exists mpesa_till_number text default '',
  add column if not exists mpesa_base_url text default 'https://api.safaricom.co.ke',
  add column if not exists mpesa_callback_url text default '',
  add column if not exists mpesa_confirmation_url text default '',
  add column if not exists mpesa_validation_url text default '',
  add column if not exists mpesa_transaction_type text default 'CustomerBuyGoodsOnline',
  add column if not exists mpesa_is_sandbox boolean default false;

comment on column public.shop_configs.mpesa_consumer_key is 'Daraja API Consumer Key';
comment on column public.shop_configs.mpesa_till_number is 'Till (Buy Goods) number for STK';
comment on column public.shop_configs.mpesa_base_url is 'Daraja base URL (sandbox or production)';
comment on column public.shop_configs.mpesa_callback_url is 'STK callback URL (e.g. Supabase Edge Function)';

-- Store STK callback results so the app can poll for completion
create table if not exists public.mpesa_callback_results (
  id uuid primary key default uuid_generate_v4(),
  checkout_request_id text not null unique,
  result_code int not null,
  result_desc text default '',
  merchant_request_id text default '',
  payload jsonb default '{}',
  created_at timestamptz default now()
);

create index if not exists idx_mpesa_callback_checkout on public.mpesa_callback_results(checkout_request_id);

alter table public.mpesa_callback_results enable row level security;

create policy "Authenticated can read mpesa_callback_results"
  on public.mpesa_callback_results for select
  using (auth.role() = 'authenticated');

-- Inserts from Edge Function use service role (bypasses RLS)
