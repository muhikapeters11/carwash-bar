-- ============================================================
-- DELETE ALL USERS (auth + profiles) — run in Supabase SQL Editor
-- WARNING: Irreversible. You will need to create a new admin after this.
-- ============================================================

-- 1) Clear business data that references profiles (otherwise DELETE fails)
delete from public.sale_items where true;
delete from public.sales where true;
delete from public.credit_payments where true;
delete from public.expenses where true;
delete from public.stock_movements where true;
delete from public.stock_receipts where true;
delete from public.activity_log where true;
delete from public.admin_notifications where true;

-- 2) Remove profile rows
delete from public.profiles where true;

-- 3) Remove Auth users (requires privilege — works in SQL Editor as postgres)
-- If this fails, use Dashboard → Authentication → Users → delete each user
delete from auth.users where true;

-- Optional: confirm empty
-- select count(*) as profiles_left from public.profiles;
-- select count(*) as auth_users_left from auth.users;
