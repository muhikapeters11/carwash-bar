-- DEPRECATED: Profile management is manual in Supabase.
-- Run MANUAL-PROFILE-SETUP.sql instead.
-- This file intentionally does NOT insert profiles or create Auth triggers.

alter table public.profiles enable row level security;
drop trigger if exists on_auth_user_created_barpos on auth.users;
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();
drop policy if exists "profile insert own" on public.profiles;

drop policy if exists "profile read own or admin" on public.profiles;
create policy "profile read own or admin" on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_admin());

drop policy if exists "admin update profiles" on public.profiles;
create policy "admin update profiles" on public.profiles
  for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

select u.id as auth_user_id, u.email, p.id as profile_id, p.full_name, p.role, p.active
from auth.users u
left join public.profiles p on p.id = u.id
order by u.email;
