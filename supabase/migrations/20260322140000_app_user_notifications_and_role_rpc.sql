-- Per-user inbox (role changes, account messages)
create table if not exists public.app_user_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  body text not null,
  read_at timestamptz,
  created_at timestamptz default now()
);

create index if not exists app_user_notifications_user_idx
  on public.app_user_notifications (user_id, created_at desc);

alter table public.app_user_notifications enable row level security;

drop policy if exists "app_user_notifications_select_own" on public.app_user_notifications;
create policy "app_user_notifications_select_own"
  on public.app_user_notifications for select
  using (auth.uid() = user_id);

drop policy if exists "app_user_notifications_update_own_read" on public.app_user_notifications;
create policy "app_user_notifications_update_own_read"
  on public.app_user_notifications for update
  using (auth.uid() = user_id);

revoke insert on public.app_user_notifications from authenticated;

-- Staff change role + notify affected user (bypasses RLS on profiles)
create or replace function public.staff_set_user_role(
  p_target_user_id uuid,
  p_new_role text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_actor_role text;
  v_old text;
  r text;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  select role into v_actor_role from public.profiles where id = v_uid;
  if v_actor_role is null then
    raise exception 'Profile not found';
  end if;

  if v_actor_role not in ('admin', 'manager') then
    raise exception 'Not allowed';
  end if;

  if p_target_user_id is null or p_new_role is null or trim(p_new_role) = '' then
    raise exception 'Invalid arguments';
  end if;

  r := lower(trim(p_new_role));
  if r not in ('admin', 'manager', 'cashier', 'client') then
    raise exception 'Invalid role';
  end if;

  if v_actor_role = 'manager' and r = 'admin' then
    raise exception 'Managers cannot assign admin role';
  end if;

  select role into v_old from public.profiles where id = p_target_user_id;
  if v_old is null then
    raise exception 'User not found';
  end if;

  if v_old = r then
    return;
  end if;

  update public.profiles
  set role = r, updated_at = now()
  where id = p_target_user_id;

  insert into public.app_user_notifications (user_id, title, body)
  values (
    p_target_user_id,
    'Your role was updated',
    format(
      'Your account role was changed from %s to %s. Sign out and back in if the app still shows the old role.',
      initcap(v_old),
      initcap(r)
    )
  );
end;
$$;

grant execute on function public.staff_set_user_role(uuid, text) to authenticated;
