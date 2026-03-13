alter table public.shop_configs
  add column if not exists printer_type text default 'standard';

comment on column public.shop_configs.printer_type is 'standard | thermal';
