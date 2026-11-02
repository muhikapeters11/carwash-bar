-- Carwash POS 2.7.6 - automatic internal profile setup
-- Run this file ONCE in Supabase Dashboard > SQL Editor as project owner.
-- It does NOT create Auth users. Create/manage Auth accounts in Authentication > Users.
-- Existing users: creates missing profiles, assigns the known admin explicitly,
-- and sets the PIN lookup hashes used by resolve_pin_login().
-- Auth passwords must separately be set to the matching PIN in Authentication > Users.

create extension if not exists pgcrypto;

-- Ensure the profile columns used by this POS release exist.
alter table public.profiles add column if not exists allowed_tabs text[] default array['Dashboard','Sell','Credits','Expenses'];
alter table public.profiles add column if not exists pin_hash text;
alter table public.profiles add column if not exists staff_code text;
alter table public.profiles add column if not exists login_email text;

-- New Auth users receive an internal POS profile automatically.
-- New accounts default to cashier; promote an account to admin only deliberately.
create or replace function public.handle_new_auth_user_pos()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role, active, login_email, allowed_tabs)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'full_name', ''), split_part(coalesce(new.email, ''), '@', 1)),
    'cashier',
    true,
    lower(new.email),
    array['Dashboard','Sell','Credits','Expenses']::text[]
  )
  on conflict (id) do update
    set login_email = excluded.login_email;
  return new;
end;
$$;

-- Avoid duplicate copies of this specific trigger.
drop trigger if exists on_auth_user_created_carwash_pos on auth.users;
create trigger on_auth_user_created_carwash_pos
after insert on auth.users
for each row execute function public.handle_new_auth_user_pos();

-- Backfill every existing Auth user who is missing a POS profile.
insert into public.profiles (id, full_name, role, active, login_email, allowed_tabs)
select
  u.id,
  coalesce(nullif(u.raw_user_meta_data->>'full_name', ''), split_part(coalesce(u.email, ''), '@', 1)),
  case when lower(u.email) = lower('pmuhika7@gmail.com') then 'admin' else 'cashier' end,
  true,
  lower(u.email),
  array['Dashboard','Sell','Credits','Expenses']::text[]
from auth.users u
on conflict (id) do update
set login_email = excluded.login_email;

-- Explicitly enforce the intended roles for the two known accounts.
update public.profiles p
set role = 'admin', login_email = lower(u.email), active = true
from auth.users u
where p.id = u.id and lower(u.email) = lower('pmuhika7@gmail.com');

update public.profiles p
set role = 'cashier', login_email = lower(u.email), active = true
from auth.users u
where p.id = u.id and lower(u.email) = lower('malikpeters92@gmail.com');

-- Store SHA-256 PIN digests for the current PIN-to-email lookup RPC.
-- The Auth password for each account must ALSO be set to its matching PIN.
update public.profiles p
set pin_hash = encode(extensions.digest(convert_to('233456', 'UTF8'), 'sha256'), 'hex'),
    login_email = lower(u.email)
from auth.users u
where p.id = u.id and lower(u.email) = lower('pmuhika7@gmail.com');

update public.profiles p
set pin_hash = encode(extensions.digest(convert_to('222222', 'UTF8'), 'sha256'), 'hex'),
    login_email = lower(u.email)
from auth.users u
where p.id = u.id and lower(u.email) = lower('malikpeters92@gmail.com');

-- Keep profile RLS enabled. The trigger runs as its function owner (SQL project owner),
-- so clients do not need an INSERT policy and the POS does not insert profiles itself.
alter table public.profiles enable row level security;

-- Verification: both Auth users should have matching profile IDs and expected roles.
select u.id as auth_user_id, u.email, p.id as profile_id, p.full_name, p.role, p.active,
       (p.pin_hash is not null) as pin_configured
from auth.users u
left join public.profiles p on p.id = u.id
where lower(u.email) in (lower('pmuhika7@gmail.com'), lower('malikpeters92@gmail.com'))
order by u.email;
