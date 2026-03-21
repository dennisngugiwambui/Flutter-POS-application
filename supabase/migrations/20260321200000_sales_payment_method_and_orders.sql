-- Optional payment channel for POS receipts / reporting
alter table public.sales add column if not exists payment_method text default 'cash';

-- Client orders (catalog checkout — separate from POS `sales`)
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references auth.users(id),
  client_name text,
  total_amount numeric not null,
  payment_method text not null,
  phone text,
  address text,
  notes text,
  status text default 'pending',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid,
  product_name text,
  quantity int not null,
  unit_price numeric,
  total_price numeric
);

create index if not exists orders_client_id_idx on public.orders (client_id);
create index if not exists order_items_order_id_idx on public.order_items (order_id);

alter table public.orders enable row level security;
alter table public.order_items enable row level security;

create policy "Authenticated can manage orders"
  on public.orders for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

create policy "Authenticated can manage order_items"
  on public.order_items for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');
