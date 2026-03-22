-- Normalize role from auth metadata on signup (admin API and self-register).
create or replace function public.handle_new_user()
returns trigger as $$
declare
  r text;
begin
  r := nullif(lower(trim(coalesce(new.raw_user_meta_data->>'role', ''))), '');
  if r is not null and r not in ('admin', 'manager', 'cashier', 'client') then
    r := 'cashier';
  end if;
  insert into public.profiles (id, full_name, email, phone_number, role)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), ''),
    coalesce(new.email, ''),
    coalesce(nullif(trim(new.raw_user_meta_data->>'phone_number'), ''), ''),
    coalesce(r, 'cashier')
  );
  return new;
end;
$$ language plpgsql security definer;
