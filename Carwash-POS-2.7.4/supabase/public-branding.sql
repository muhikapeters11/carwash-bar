-- Run this once in Supabase SQL Editor for the login screen to read the logo/name before authentication.
create or replace function public.get_public_branding()
returns table (bar_name text, logo_url text)
language sql
security definer
set search_path = public
as $$
  select s.bar_name, s.logo_url from public.app_settings s where s.id = 1;
$$;
grant execute on function public.get_public_branding() to anon, authenticated;
