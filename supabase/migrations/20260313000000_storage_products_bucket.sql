-- Create storage bucket for product images (fixes "Bucket not found" on Add Product)
-- Run this in Supabase Dashboard → SQL Editor if not using migrations.
insert into storage.buckets (id, name, public)
values ('products', 'products', true)
on conflict (id) do nothing;

-- Allow authenticated users to upload to product_images folder (required for add/edit product image)
create policy "Authenticated can upload product images"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'products'
  and (storage.foldername(name))[1] = 'product_images'
);

-- Allow public read (bucket is public)
create policy "Public read product images"
on storage.objects for select
using (bucket_id = 'products');

-- Allow authenticated users to update/delete their uploads if needed
create policy "Authenticated can update product images"
on storage.objects for update
using (bucket_id = 'products' and auth.role() = 'authenticated');

create policy "Authenticated can delete product images"
on storage.objects for delete
using (bucket_id = 'products' and auth.role() = 'authenticated');
