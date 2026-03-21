-- Pre-signup checks: case-insensitive email + digit-normalized phone uniqueness vs profiles.
-- Also used by Edge Function admin-create-user.

create or replace function public.check_registration_available(p_email text, p_phone text)
returns jsonb
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  e_norm text := lower(trim(coalesce(p_email, '')));
  p_digits text := regexp_replace(coalesce(trim(p_phone), ''), '\D', '', 'g');
  email_taken boolean := false;
  phone_taken boolean := false;
begin
  if e_norm = '' then
    return jsonb_build_object('email_taken', false, 'phone_taken', false, 'error', 'email_empty');
  end if;

  select exists(
    select 1 from public.profiles p
    where lower(trim(coalesce(p.email, ''))) = e_norm
  ) into email_taken;

  if p_digits is not null and length(p_digits) >= 1 then
    select exists(
      select 1 from public.profiles p
      where regexp_replace(coalesce(p.phone_number, ''), '\D', '', 'g') = p_digits
        and length(regexp_replace(coalesce(p.phone_number, ''), '\D', '', 'g')) >= 1
    ) into phone_taken;
  end if;

  return jsonb_build_object('email_taken', email_taken, 'phone_taken', phone_taken);
end;
$$;

grant execute on function public.check_registration_available(text, text) to anon, authenticated;

-- Optional (run after cleaning duplicates): enforce uniqueness on profiles.
-- create unique index profiles_email_lower_unique on public.profiles (lower(trim(email)))
--   where email is not null and trim(email) <> '';
-- create unique index profiles_phone_digits_unique on public.profiles ((regexp_replace(coalesce(phone_number, ''), '\D', '', 'g')))
--   where length(regexp_replace(coalesce(phone_number, ''), '\D', '', 'g')) >= 1;
