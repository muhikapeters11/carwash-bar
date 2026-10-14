-- Run in Supabase SQL Editor to install/update factory reset
create or replace function public.factory_reset()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Only admin can factory reset';
  end if;

  delete from public.sale_items;
  delete from public.sales;
  delete from public.credit_payments;
  delete from public.expenses;
  delete from public.stock_movements;
  delete from public.stock_receipts;
  delete from public.products;
  delete from public.suppliers;
  delete from public.admin_notifications;
  delete from public.activity_log;

  insert into public.activity_log(user_id, action, details)
  values (
    auth.uid(),
    'factory_reset',
    'Full wipe: sales, expenses, credits, stock, products, suppliers, notifications cleared'
  );
end;
$$;

grant execute on function public.factory_reset() to authenticated;
