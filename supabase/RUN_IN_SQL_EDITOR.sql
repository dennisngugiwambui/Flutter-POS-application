-- =============================================================================
-- PIXEL POS – PASTE THIS ENTIRE FILE INTO SUPABASE SQL EDITOR AND CLICK RUN
-- Dashboard → SQL Editor → New query → Paste all below → Run
-- =============================================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Profiles: extends auth.users for app user data
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  phone_number text,
  role text default 'cashier',
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Keep profile in sync with auth.users
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, email, phone_number, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'phone_number', ''),
    coalesce(new.raw_user_meta_data->>'role', 'cashier')
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Products table
create table if not exists public.products (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  barcode text not null,
  buying_price numeric not null,
  selling_price numeric not null,
  stock_quantity integer not null default 0,
  image_url text default '',
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

-- Sales (for dashboard stats and history)
create table if not exists public.sales (
  id uuid primary key default uuid_generate_v4(),
  total_amount numeric not null,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table public.sales enable row level security;
create policy "Authenticated can manage sales" on public.sales for all using (auth.role() = 'authenticated');

-- Shop config (single row)
create table if not exists public.shop_configs (
  id uuid primary key default uuid_generate_v4(),
  shop_name text default 'Pixel POS',
  logo_url text default '',
  po_box text default '',
  address text default '',
  phone_number text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.shop_configs enable row level security;

-- Policies: profiles
create policy "Users can view all profiles" on public.profiles for select using (true);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

-- Policies: products
create policy "Authenticated users can manage products" on public.products
  for all using (auth.role() = 'authenticated');

-- Policies: shop_configs
create policy "Authenticated can read shop_configs" on public.shop_configs for select using (auth.role() = 'authenticated');
create policy "Authenticated can update shop_configs" on public.shop_configs for update using (auth.role() = 'authenticated');
create policy "Authenticated can insert shop_configs" on public.shop_configs for insert with check (auth.role() = 'authenticated');
