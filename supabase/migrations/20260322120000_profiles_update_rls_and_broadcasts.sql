-- Allow admins/managers to update any profile (activate/deactivate, role), not only own row.
drop policy if exists "Users can update own profile" on public.profiles;

create policy "profiles_update_self_or_staff"
  on public.profiles for update
  using (
    auth.uid() = id
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('admin', 'manager')
    )
  )
  with check (
    auth.uid() = id
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid()
        and p.role in ('admin', 'manager')
    )
  );

-- In-app broadcast notifications (promotions / alerts)
create table if not exists public.app_broadcasts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  sender_id uuid references auth.users (id) on delete set null,
  target_roles text[] not null default array['all']::text[],
  created_at timestamptz default now()
);

create index if not exists app_broadcasts_created_idx on public.app_broadcasts (created_at desc);

alter table public.app_broadcasts enable row level security;

-- Recipients see a row if their role is targeted or broadcast is for all
create policy "app_broadcasts_select_visible"
  on public.app_broadcasts for select
  using (
    exists (
      select 1
      from public.profiles pr
      where pr.id = auth.uid()
        and (
          'all' = any (app_broadcasts.target_roles)
          or pr.role = any (app_broadcasts.target_roles)
        )
    )
  );

-- Inserts only via RPC (validated sender + targets)
revoke insert on public.app_broadcasts from authenticated;

create or replace function public.send_app_broadcast(
  p_title text,
  p_body text,
  p_target_roles text[]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
  v_id uuid;
  t text[];
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  if p_title is null or trim(p_title) = '' then
    raise exception 'Title required';
  end if;

  select role into v_role from public.profiles where id = v_uid;
  if v_role is null then
    raise exception 'Profile not found';
  end if;

  t := coalesce(p_target_roles, array[]::text[]);
  if array_length(t, 1) is null or array_length(t, 1) = 0 then
    t := array['all']::text[];
  end if;

  -- Admin: any combination of admin, manager, cashier, client, all
  if v_role = 'admin' then
    null;
  elsif v_role = 'manager' then
    if 'admin' = any (t) then
      raise exception 'Managers cannot target admins';
    end if;
    if 'all' = any (t) then
      raise exception 'Only admins can broadcast to everyone';
    end if;
  elsif v_role = 'client' then
    if not (
      t <@ array['admin', 'manager']::text[]
      or (array_length(t, 1) = 1 and t[1] = 'admin')
      or (array_length(t, 1) = 1 and t[1] = 'manager')
    ) then
      raise exception 'Clients may only message admins and/or managers';
    end if;
  else
    raise exception 'Your role cannot send broadcasts';
  end if;

  insert into public.app_broadcasts (title, body, sender_id, target_roles)
  values (trim(p_title), trim(p_body), v_uid, t)
  returning id into v_id;

  return v_id;
end;
$$;

grant execute on function public.send_app_broadcast(text, text, text[]) to authenticated;
