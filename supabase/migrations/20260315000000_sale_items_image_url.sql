-- Add product image URL to sale_items for display in Sales History "Products sold"
alter table public.sale_items
  add column if not exists image_url text default '';
