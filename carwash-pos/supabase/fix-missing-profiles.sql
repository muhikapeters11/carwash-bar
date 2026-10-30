-- ============================================================
-- Fix "No profile for this account"
-- Run once in Supabase SQL Editor after creating Auth users
-- ============================================================

alter table public.profiles add column if not exists pin_hash text;
alter table public.profiles add column if not exists login_email text;
alter table public.profiles add column if not exists staff_code text;
alter table public.profiles add column if not exists allowed_tabs text[];
alter table public.profiles add column if not exists active boolean default true;
alter table public.profiles add column if not exists role text default 'cashier';
alter table public.profiles add column if not exists full_name text;

-- Backfill: one profile per Auth user
insert into public.profiles (id, full_name, role, active, login_email)
select
  u.id,
  coalesce(
    u.raw_user_meta_data->>'full_name',
    u.raw_user_meta_data->>'name',
    split_part(u.email, '@', 1)
  ),
  coalesce(u.raw_user_meta_data->>'role', 'cashier'),
  true,
  lower(u.email)
from auth.users u
on conflict (id) do update set
  login_email = excluded.login_email,
  active = true,
  full_name = coalesce(nullif(public.profiles.full_name, ''), excluded.full_name);

-- Auto-create profile whenever a user is created in Authentication
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role, active, login_email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'cashier'),
    true,
    lower(new.email)
  )
  on conflict (id) do update set
    login_email = excluded.login_email,
    active = true;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_barpos on auth.users;
create trigger on_auth_user_created_barpos
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- RLS: user can read/update own profile; admin can manage
alter table public.profiles enable row level security;

drop policy if exists "profile read own or admin" on public.profiles;
create policy "profile read own or admin" on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_admin());

drop policy if exists "profile insert own" on public.profiles;
create policy "profile insert own" on public.profiles
  for insert to authenticated
  with check (id = auth.uid() or public.is_admin());

drop policy if exists "profile update own or admin" on public.profiles;
create policy "profile update own or admin" on public.profiles
  for update to authenticated
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

-- Verify
select u.email, p.role, p.active, p.login_email
from auth.users u
left join public.profiles p on p.id = u.id
order by u.email;
