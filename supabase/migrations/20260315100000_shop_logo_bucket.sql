-- Bucket for shop logo (single file); public read, authenticated upload
insert into storage.buckets (id, name, public)
values ('shop', 'shop', true)
on conflict (id) do nothing;

drop policy if exists "Authenticated can upload shop logo" on storage.objects;
create policy "Authenticated can upload shop logo"
on storage.objects for insert
to authenticated
with check (bucket_id = 'shop');

drop policy if exists "Authenticated can update shop logo" on storage.objects;
create policy "Authenticated can update shop logo"
on storage.objects for update
to authenticated
using (bucket_id = 'shop');

drop policy if exists "Public read shop" on storage.objects;
create policy "Public read shop"
on storage.objects for select
using (bucket_id = 'shop');
