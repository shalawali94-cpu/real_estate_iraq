-- Returns coordinates of a listing the caller may see (published, or own).
create or replace function public.property_coords(p_id uuid)
returns table (lat double precision, lng double precision)
language sql stable security definer set search_path = public, extensions as $$
  select st_y(location::geometry), st_x(location::geometry)
  from public.properties
  where id = p_id and location is not null
    and (publication_status = 'published' or owner_id = auth.uid());
$$;
revoke all on function public.property_coords(uuid) from public;
grant execute on function public.property_coords(uuid) to anon, authenticated;
