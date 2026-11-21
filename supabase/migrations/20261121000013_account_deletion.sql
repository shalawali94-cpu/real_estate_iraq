-- Account deletion: anonymize personal data, retire listings, keep financial history.
-- The auth user is soft-deleted by the backend afterwards (the phone number becomes free).
-- Payment orders reference auth.users (ON DELETE RESTRICT) and must stay immutable.

create or replace function public.account_anonymize(p_user uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (select 1 from public.profiles where id = p_user) then
    raise exception 'NOT_FOUND' using errcode = 'P0002';
  end if;

  -- Listings stop being visible; rows stay (payments / moderation history refer to them).
  update public.properties
     set listing_state = 'archived', deleted_at = coalesce(deleted_at, now())
   where owner_id = p_user and deleted_at is null;

  update public.profiles
     set full_name = null, avatar_path = null, phone = null, email = null,
         show_phone = false, governorate_id = null, district_id = null,
         deleted_at = coalesce(deleted_at, now())
   where id = p_user;

  delete from public.property_favorites where user_id = p_user;
  delete from public.saved_searches     where user_id = p_user;
  delete from public.user_devices       where user_id = p_user;
  delete from public.user_blocks        where blocker_id = p_user or blocked_id = p_user;
  delete from public.user_roles         where user_id = p_user;
end;
$$;

revoke all on function public.account_anonymize(uuid) from public, anon, authenticated;
grant execute on function public.account_anonymize(uuid) to service_role;
