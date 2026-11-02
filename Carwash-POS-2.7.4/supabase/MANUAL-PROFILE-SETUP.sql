-- Carwash POS: manual profile management
-- IMPORTANT: Run this in Supabase SQL Editor (not from the POS).
-- The POS must NEVER create Auth users or profiles.

-- 1) Disable any legacy automatic profile creation trigger/function.
drop trigger if exists on_auth_user_created_barpos on auth.users;
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- 2) Do NOT create an INSERT RLS policy for profiles.
-- Profile rows are created by the administrator in Supabase SQL Editor.
drop policy if exists "profile insert own" on public.profiles;

-- 3) Ensure the admin can edit receipt/display names only through the app.
-- Other profile fields remain controlled in Supabase.
alter table public.profiles enable row level security;

drop policy if exists "profile read own or admin" on public.profiles;
create policy "profile read own or admin" on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_admin());

drop policy if exists "admin update profiles" on public.profiles;
create policy "admin update profiles" on public.profiles
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- 4) Create/link a profile for an existing Auth user.
-- Replace the email below with the EXACT email shown in
-- Authentication > Users. This is run in SQL Editor, where the
-- database owner can insert despite profiles RLS.
--
-- insert into public.profiles
--   (id, full_name, role, active, login_email, allowed_tabs)
-- select
--   u.id,
--   coalesce(nullif(u.raw_user_meta_data->>'full_name',''), split_part(u.email,'@',1)),
--   'cashier',
--   true,
--   lower(u.email),
--   '{}'::text[]
-- from auth.users u
-- where lower(u.email) = lower('USER_EMAIL_HERE')
-- on conflict (id) do update set
--   login_email = excluded.login_email;

-- 5) Verify all Auth users and whether a profile exists.
select
  u.id as auth_user_id,
  u.email,
  p.id as profile_id,
  p.full_name,
  p.role,
  p.active
from auth.users u
left join public.profiles p on p.id = u.id
order by u.email;
