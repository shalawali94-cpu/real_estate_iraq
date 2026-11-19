-- Replace the SECURITY DEFINER view public_profiles (flagged CRITICAL by the Supabase
-- linter) with a function that returns only the safe columns for the ids asked for.
drop view if exists public.public_profiles;

create or replace function public.get_public_profiles(p_ids uuid[])
returns table (
  id uuid, full_name text, avatar_path text, account_type public.account_type,
  governorate_id smallint, district_id integer, phone text,
  phone_verified boolean, identity_verified boolean,
  rating_avg numeric, rating_count integer, created_at timestamptz)
language sql stable security definer set search_path = ''
as $$
  select p.id, p.full_name, p.avatar_path, p.account_type,
         p.governorate_id, p.district_id,
         case when p.show_phone then p.phone end,
         p.phone_verified, p.identity_verified, p.rating_avg, p.rating_count, p.created_at
  from public.profiles p
  where p.id = any (p_ids[1:100])          -- at most 100 per call: no bulk scraping
    and p.deleted_at is null
    and not p.is_suspended;
$$;

revoke all on function public.get_public_profiles(uuid[]) from public;
grant execute on function public.get_public_profiles(uuid[]) to anon, authenticated, service_role;
