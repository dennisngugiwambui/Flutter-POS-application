-- Lets the app decide whether self-registration should create the first admin or a client only.
-- Callable by anon (register screen before login).

create or replace function public.has_admin_user()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles
    where lower(trim(coalesce(role, ''))) = 'admin'
  );
$$;

grant execute on function public.has_admin_user() to anon, authenticated;
