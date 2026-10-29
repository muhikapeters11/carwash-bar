-- ============================================================
-- Users created in Supabase Auth → PIN login in Carwash POS
-- ============================================================
-- How to create a user in Supabase Dashboard:
--   Authentication → Users → Add user
--   Email: staff@example.com
--   Password: 4–12 digit PIN (e.g. 222222)  ← this IS the PIN
--   Auto Confirm User: ON
--   Optional User Metadata (JSON):  {"pin":"222222"}
--
-- Then run this whole script once (or again after adding users).
-- ============================================================

create extension if not exists pgcrypto with schema extensions;

alter table public.profiles add column if not exists pin_hash text;
alter table public.profiles add column if not exists login_email text;
alter table public.profiles add column if not exists staff_code text;
alter table public.profiles add column if not exists allowed_tabs text[];
alter table public.profiles add column if not exists active boolean default true;
alter table public.profiles add column if not exists role text default 'cashier';
alter table public.profiles add column if not exists full_name text;
alter table public.profiles add column if not exists updated_at timestamptz default now();

-- Ensure every Auth user has a profile
insert into public.profiles (id, full_name, role, active, login_email)
select
  u.id,
  coalesce(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)),
  coalesce(u.raw_user_meta_data->>'role', 'cashier'),
  true,
  lower(u.email)
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id)
on conflict (id) do nothing;

-- Sync login_email + pin_hash from Auth metadata pin (if provided)
update public.profiles p
set
  login_email = lower(u.email),
  active = true,
  pin_hash = case
    when coalesce(u.raw_user_meta_data->>'pin', '') ~ '^[0-9]{4,12}$' then
      encode(extensions.digest(convert_to(u.raw_user_meta_data->>'pin', 'UTF8'), 'sha256'), 'hex')
    else p.pin_hash
  end,
  role = coalesce(nullif(p.role, ''), u.raw_user_meta_data->>'role', 'cashier'),
  updated_at = now()
from auth.users u
where p.id = u.id;

-- PIN login: match profiles.pin_hash OR auth metadata pin
create or replace function public.resolve_pin_login(p_pin text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_hash_sha text;
  v_hash_b64 text;
  v_count int;
  v_email text;
  v_name text;
  v_role text;
  v_pin text := trim(p_pin);
begin
  if v_pin is null or length(v_pin) < 4 then
    raise exception 'Enter a valid PIN';
  end if;

  v_hash_sha := encode(extensions.digest(convert_to(v_pin, 'UTF8'), 'sha256'), 'hex');
  v_hash_b64 := encode(convert_to(v_pin, 'UTF8'), 'base64');

  -- Count matches: profile hash OR metadata pin
  select count(*) into v_count
  from auth.users u
  left join public.profiles p on p.id = u.id
  where (p.active is distinct from false)
    and (
      (p.pin_hash is not null and (p.pin_hash = v_hash_sha or p.pin_hash = v_hash_b64))
      or (coalesce(u.raw_user_meta_data->>'pin', '') = v_pin)
    );

  if v_count = 0 then
    raise exception 'Invalid PIN';
  end if;
  if v_count > 1 then
    raise exception 'PIN is not unique';
  end if;

  select lower(u.email),
         coalesce(p.full_name, u.raw_user_meta_data->>'full_name'),
         coalesce(p.role, u.raw_user_meta_data->>'role', 'cashier')
  into v_email, v_name, v_role
  from auth.users u
  left join public.profiles p on p.id = u.id
  where (p.id is null or p.active is distinct from false)
    and (
      (p.pin_hash is not null and (p.pin_hash = v_hash_sha or p.pin_hash = v_hash_b64))
      or (coalesce(u.raw_user_meta_data->>'pin', '') = v_pin)
    )
  limit 1;

  if v_email is null or v_email = '' then
    raise exception 'Account has no email';
  end if;

  -- Keep profile pin_hash in sync for offline vault later
  update public.profiles
  set pin_hash = v_hash_sha,
      login_email = v_email,
      active = true,
      updated_at = now()
  where id = (select id from auth.users where lower(email) = v_email limit 1);

  return jsonb_build_object(
    'email', v_email,
    'full_name', v_name,
    'role', v_role
  );
end;
$$;

grant execute on function public.resolve_pin_login(text) to anon, authenticated;

-- Optional: set PINs here if you did not use metadata (password in Auth must still = PIN)
-- update public.profiles p set pin_hash = encode(extensions.digest(convert_to('233456','UTF8'),'sha256'),'hex'),
--   active = true, role = 'admin', login_email = 'pmuhika7@gmail.com'
-- from auth.users u where p.id = u.id and lower(u.email) = 'pmuhika7@gmail.com';

select u.email, p.role, p.active, (p.pin_hash is not null) as has_pin_hash,
       u.raw_user_meta_data->>'pin' as meta_pin
from auth.users u
left join public.profiles p on p.id = u.id
order by u.email;
