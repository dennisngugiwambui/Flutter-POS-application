-- Link a sale to a client/customer account (optional; POS sales stay null).
alter table public.sales add column if not exists customer_user_id uuid references auth.users(id) on delete set null;

create index if not exists sales_customer_user_id_idx on public.sales (customer_user_id)
  where customer_user_id is not null;
