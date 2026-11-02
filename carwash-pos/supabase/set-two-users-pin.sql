-- Admin + cashier PIN setup (Auth password must match PIN in Dashboard)
create extension if not exists pgcrypto with schema extensions;

insert into public.profiles (id, full_name, role, active, login_email)
select u.id,
       coalesce(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)),
       'cashier', true, lower(u.email)
from auth.users u
on conflict (id) do update set login_email = excluded.login_email, active = true;

-- Admin: pmuhika7@gmail.com / PIN 233456
update public.profiles p
set pin_hash = encode(extensions.digest(convert_to('233456', 'UTF8'), 'sha256'), 'hex'),
    active = true, role = 'admin', login_email = 'pmuhika7@gmail.com',
    full_name = coalesce(nullif(p.full_name, ''), 'Admin')
from auth.users u
where p.id = u.id and lower(u.email) = 'pmuhika7@gmail.com';

-- Cashier: pmuhika23@gmail.com / PIN 222222
update public.profiles p
set pin_hash = encode(extensions.digest(convert_to('222222', 'UTF8'), 'sha256'), 'hex'),
    active = true, role = 'cashier', login_email = 'pmuhika23@gmail.com',
    full_name = coalesce(nullif(p.full_name, ''), 'Cashier')
from auth.users u
where p.id = u.id and lower(u.email) = 'pmuhika23@gmail.com';

select public.resolve_pin_login('233456');
select public.resolve_pin_login('222222');

select u.email, p.role, p.active, (p.pin_hash is not null) as has_pin
from public.profiles p
join auth.users u on u.id = p.id
order by u.email;
