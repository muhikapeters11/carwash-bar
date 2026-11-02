-- CARWASH POS: Admin + Cashier account/profile setup
-- Run in Supabase SQL Editor AFTER creating both Auth users in Authentication > Users.
-- Auth passwords must be set to the same PINs shown below in the Auth dashboard.
-- This script NEVER inserts or edits auth.users and NEVER touches other profiles.

create extension if not exists pgcrypto with schema extensions;

-- Fail safely if either Auth account has not been created yet.
do $$
begin
  if not exists (select 1 from auth.users where lower(email) = 'pmuhika7@gmail.com') then
    raise exception 'Missing Auth user pmuhika7@gmail.com. Create it in Authentication > Users first.';
  end if;
  if not exists (select 1 from auth.users where lower(email) = 'malikpeters92@gmail.com') then
    raise exception 'Missing Auth user malikpeters92@gmail.com. Create it in Authentication > Users first.';
  end if;
end $$;

-- Create/update ONLY these two matching profiles.
insert into public.profiles
  (id, full_name, role, active, login_email, allowed_tabs, pin_hash)
select
  u.id,
  'Peter Muhika',
  'admin',
  true,
  lower(u.email),
  array['Dashboard','Sell','Receive Stock','Inventory','Products','Credits','Suppliers','Expenses','Reports','Users','Activity Log','Backup & Settings'],
  encode(extensions.digest(convert_to('233456', 'UTF8'), 'sha256'), 'hex')
from auth.users u
where lower(u.email) = 'pmuhika7@gmail.com'
on conflict (id) do update set
  full_name = excluded.full_name,
  role = 'admin',
  active = true,
  login_email = excluded.login_email,
  allowed_tabs = excluded.allowed_tabs,
  pin_hash = excluded.pin_hash,
  updated_at = now();

insert into public.profiles
  (id, full_name, role, active, login_email, allowed_tabs, pin_hash)
select
  u.id,
  'Malik Peters',
  'cashier',
  true,
  lower(u.email),
  array['Dashboard','Sell','Credits','Expenses'],
  encode(extensions.digest(convert_to('222222', 'UTF8'), 'sha256'), 'hex')
from auth.users u
where lower(u.email) = 'malikpeters92@gmail.com'
on conflict (id) do update set
  full_name = excluded.full_name,
  role = 'cashier',
  active = true,
  login_email = excluded.login_email,
  allowed_tabs = excluded.allowed_tabs,
  pin_hash = excluded.pin_hash,
  updated_at = now();

-- Verify exactly these two account/profile links and PIN hashes.
select
  u.id as auth_user_id,
  u.email,
  p.id as profile_id,
  p.full_name,
  p.role,
  p.active,
  (p.pin_hash is not null) as pin_configured,
  (u.id = p.id) as auth_profile_ids_match
from auth.users u
left join public.profiles p on p.id = u.id
where lower(u.email) in ('pmuhika7@gmail.com', 'malikpeters92@gmail.com')
order by p.role;

-- Expected: 2 rows, both auth_profile_ids_match = true and pin_configured = true.
-- Auth password must separately be set to 233456 / 222222 in Authentication > Users.
