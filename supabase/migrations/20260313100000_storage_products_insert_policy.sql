-- Fix 403 "new row violates row-level security" on product image upload.
-- Ensures INSERT policy exists and allows authenticated uploads to product_images folder.
-- Run in Supabase Dashboard → SQL Editor if uploads still fail.

-- Remove existing policy if present (avoids duplicate)
drop policy if exists "Authenticated can upload product images" on storage.objects;

-- Allow authenticated users to INSERT into products bucket, product_images folder
create policy "Authenticated can upload product images"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'products'
  and (storage.foldername(name))[1] = 'product_images'
);
