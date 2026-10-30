-- Wipe ALL Auth users and profiles (run in Supabase SQL Editor)
delete from public.sale_items where true;
delete from public.sales where true;
delete from public.credit_payments where true;
delete from public.expenses where true;
delete from public.stock_movements where true;
delete from public.stock_receipts where true;
delete from public.activity_log where true;
delete from public.admin_notifications where true;
delete from public.profiles where true;
delete from auth.users where true;
select
  (select count(*) from public.profiles) as profiles_left,
  (select count(*) from auth.users) as auth_users_left;
