-- Optional M-Pesa (STK) configuration for checkout
alter table public.shop_configs
  add column if not exists mpesa_shortcode text default '',
  add column if not exists mpesa_passkey text default '';

comment on column public.shop_configs.mpesa_shortcode is 'M-Pesa till / paybill shortcode (optional)';
comment on column public.shop_configs.mpesa_passkey is 'M-Pesa API passkey (optional, for Daraja)';
