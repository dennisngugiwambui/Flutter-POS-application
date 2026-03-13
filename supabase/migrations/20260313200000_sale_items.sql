-- Sale line items: products sold per sale (for sales history detail)
create table if not exists public.sale_items (
  id uuid primary key default uuid_generate_v4(),
  sale_id uuid not null references public.sales(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  barcode text default '',
  quantity integer not null,
  unit_price numeric not null,
  total_price numeric not null,
  created_at timestamptz default now()
);

create index if not exists idx_sale_items_sale_id on public.sale_items(sale_id);

alter table public.sale_items enable row level security;

create policy "Authenticated can manage sale_items"
  on public.sale_items for all
  using (auth.role() = 'authenticated');
