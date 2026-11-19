-- Search RPC, views / recently viewed, saved searches, comparisons, reports, verification.

-- ===== Views & recently viewed ===========================================
create table public.property_views (
  property_id uuid not null references public.properties (id) on delete cascade,
  viewer_id   uuid not null references auth.users (id) on delete cascade,
  viewed_on   date not null default (now() at time zone 'Asia/Baghdad')::date,
  primary key (property_id, viewer_id, viewed_on)
);

create table public.recently_viewed (
  user_id     uuid not null references auth.users (id) on delete cascade,
  property_id uuid not null references public.properties (id) on delete cascade,
  viewed_at   timestamptz not null default now(),
  primary key (user_id, property_id)
);
create index recently_viewed_user_idx on public.recently_viewed (user_id, viewed_at desc);

-- One counted view per user per listing per day; owners don't count.
create or replace function public.record_property_view(p_property uuid)
returns void language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_rows integer;
begin
  if v_me is null or not public.property_is_public(p_property) then
    return;
  end if;
  insert into public.recently_viewed (user_id, property_id) values (v_me, p_property)
  on conflict (user_id, property_id) do update set viewed_at = now();
  if exists (select 1 from public.properties where id = p_property and owner_id = v_me) then
    return;
  end if;
  insert into public.property_views (property_id, viewer_id) values (p_property, v_me)
  on conflict do nothing;
  get diagnostics v_rows = row_count;
  if v_rows > 0 then
    update public.properties set views_count = views_count + 1 where id = p_property;
  end if;
  -- keep the last 100 per user
  delete from public.recently_viewed r
  where r.user_id = v_me and r.property_id in (
    select property_id from public.recently_viewed where user_id = v_me
    order by viewed_at desc offset 100);
end;
$$;

-- ===== Saved searches & comparisons ======================================
create table public.saved_searches (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users (id) on delete cascade,
  name            text not null check (char_length(name) between 1 and 60),
  filters         jsonb not null,
  alert_enabled   boolean not null default false,
  last_alerted_at timestamptz,
  created_at      timestamptz not null default now()
);
create index saved_searches_user_idx on public.saved_searches (user_id);
create index saved_searches_alerts_idx on public.saved_searches (last_alerted_at) where alert_enabled;

create or replace function public.saved_searches_limit()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if (select count(*) from public.saved_searches where user_id = new.user_id) >= 20 then
    raise exception 'VALIDATION_FAILED: max 20 saved searches' using errcode = '22023';
  end if;
  return new;
end;
$$;
create trigger saved_searches_limit before insert on public.saved_searches
  for each row execute function public.saved_searches_limit();

create table public.search_alerts (
  saved_search_id uuid not null references public.saved_searches (id) on delete cascade,
  property_id     uuid not null references public.properties (id) on delete cascade,
  sent_at         timestamptz not null default now(),
  primary key (saved_search_id, property_id)
);

create table public.property_comparisons (
  user_id      uuid primary key references auth.users (id) on delete cascade,
  property_ids uuid[] not null default '{}' check (cardinality(property_ids) <= 4),
  updated_at   timestamptz not null default now()
);

-- ===== Reports ============================================================
create table public.property_reports (
  id          uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  reporter_id uuid not null references auth.users (id) on delete cascade,
  reason      text not null check (reason in ('fake', 'wrong_price', 'sold', 'duplicate', 'fraud', 'offensive', 'other')),
  details     text check (char_length(details) <= 1000),
  status      text not null default 'open' check (status in ('open', 'resolved', 'dismissed')),
  handled_by  uuid references auth.users (id),
  created_at  timestamptz not null default now(),
  unique (property_id, reporter_id)
);
create index property_reports_open_idx on public.property_reports (created_at) where status = 'open';

-- ===== Verification =======================================================
create type public.verification_kind  as enum ('identity', 'agency', 'company', 'property_document');
create type public.verification_state as enum ('pending', 'approved', 'rejected');

create table public.verification_requests (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  kind        public.verification_kind not null,
  company_id  uuid references public.companies (id) on delete cascade,
  property_id uuid references public.properties (id) on delete cascade,
  documents   text[] not null check (cardinality(documents) between 1 and 10),
  state       public.verification_state not null default 'pending',
  notes       text,                 -- staff note (e.g. rejection reason)
  decided_by  uuid references auth.users (id),
  decided_at  timestamptz,
  created_at  timestamptz not null default now(),
  check ((kind = 'company' and company_id is not null)
      or (kind = 'property_document' and property_id is not null)
      or kind in ('identity', 'agency'))
);
create unique index verification_one_pending on public.verification_requests
  (user_id, kind, coalesce(company_id, property_id, user_id)) where state = 'pending';

create or replace function public.verification_requests_check()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;
  if new.user_id <> auth.uid() or new.state <> 'pending' or new.decided_by is not null then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;
  if new.company_id is not null and coalesce(public.company_role_of(new.company_id)::text, '') <> 'owner' then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;
  if new.property_id is not null
     and not exists (select 1 from public.properties where id = new.property_id and owner_id = auth.uid()) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;
  -- documents must live in the user's own folder of the private bucket
  if exists (select 1 from unnest(new.documents) d where d not like auth.uid()::text || '/%') then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;
  return new;
end;
$$;
create trigger verification_requests_check before insert on public.verification_requests
  for each row execute function public.verification_requests_check();

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('verification', 'verification', false, 20971520, array['image/jpeg', 'image/png', 'application/pdf'])
on conflict (id) do nothing;
create policy verification_insert_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'verification' and (storage.foldername(name))[1] = auth.uid()::text);
create policy verification_read_own on storage.objects
  for select to authenticated
  using (bucket_id = 'verification' and (storage.foldername(name))[1] = auth.uid()::text);

-- ===== Search ==============================================================
-- Public listings only. Filters (all optional) in a jsonb object:
--   q, governorate_id, district_id, neighborhood_id, category_id, category_group, transaction_type,
--   currency, min_price, max_price, min_bedrooms, min_bathrooms, min_area, max_area,
--   furnishing, building_condition, verified_owner, featured, published_within_days,
--   near {lat, lng, radius_m}, bbox {west, south, east, north},
--   sort: newest | price_asc | price_desc | area_desc | popular | nearest
create or replace function public.search_properties(
  p_filters jsonb default '{}', p_limit integer default 20, p_offset integer default 0)
returns table (
  id uuid, title text, transaction_type public.transaction_type, category_id smallint,
  price_amount bigint, price_currency char(3), price_negotiable boolean,
  governorate_id smallint, district_id integer, neighborhood_id uuid,
  area_sqm numeric, bedrooms smallint, bathrooms smallint,
  lat double precision, lng double precision, distance_m double precision,
  cover_path text, is_featured boolean, published_at timestamptz,
  views_count integer, favorites_count integer,
  owner_phone_verified boolean, owner_identity_verified boolean, company_verified boolean)
language plpgsql stable security definer set search_path = ''
as $$
declare
  f        jsonb := coalesce(p_filters, '{}');
  v_q      text  := nullif(trim(f->>'q'), '');
  v_sort   text  := coalesce(f->>'sort', 'newest');
  v_point  extensions.geography;
  v_radius double precision;
  v_bbox   extensions.geography;
begin
  if p_limit is null or p_limit < 1 or p_limit > 50 then p_limit := 20; end if;
  if p_offset is null or p_offset < 0 then p_offset := 0; end if;
  if p_offset > 1000 then
    raise exception 'VALIDATION_FAILED: offset' using errcode = '22023';
  end if;

  if f ? 'near' then
    v_point  := extensions.st_setsrid(extensions.st_makepoint((f->'near'->>'lng')::float8,
                                                              (f->'near'->>'lat')::float8), 4326)::extensions.geography;
    v_radius := least(coalesce((f->'near'->>'radius_m')::float8, 5000), 100000);
  end if;
  if f ? 'bbox' then
    v_bbox := extensions.st_makeenvelope((f->'bbox'->>'west')::float8, (f->'bbox'->>'south')::float8,
                                         (f->'bbox'->>'east')::float8, (f->'bbox'->>'north')::float8, 4326)::extensions.geography;
  end if;

  return query
  select p.id, p.title, p.transaction_type, p.category_id,
         p.price_amount, p.price_currency, p.price_negotiable,
         p.governorate_id, p.district_id, p.neighborhood_id,
         p.area_sqm, p.bedrooms, p.bathrooms,
         extensions.st_y(p.location::extensions.geometry), extensions.st_x(p.location::extensions.geometry),
         case when v_point is not null then extensions.st_distance(p.location, v_point) end,
         (select i.storage_path from public.property_images i
           where i.property_id = p.id and i.status <> 'rejected'
           order by i.is_cover desc, i.sort_order limit 1),
         (p.is_featured and (p.featured_until is null or p.featured_until > now())),
         p.published_at, p.views_count, p.favorites_count,
         o.phone_verified, o.identity_verified, coalesce(c.verified, false)
  from public.properties p
  join public.profiles o on o.id = p.owner_id
  left join public.companies c on c.id = p.company_id
  where p.publication_status = 'published' and p.listing_state = 'active' and p.deleted_at is null
    and not o.is_suspended
    and (v_q is null or p.search_tsv @@ plainto_tsquery('simple', v_q) or p.title ilike '%' || v_q || '%')
    and (f->>'governorate_id'   is null or p.governorate_id   = (f->>'governorate_id')::smallint)
    and (f->>'district_id'      is null or p.district_id      = (f->>'district_id')::integer)
    and (f->>'neighborhood_id'  is null or p.neighborhood_id  = (f->>'neighborhood_id')::uuid)
    and (f->>'category_id'      is null or p.category_id      = (f->>'category_id')::smallint)
    and (f->>'category_group'   is null or p.category_id in
          (select pc.id from public.property_categories pc where pc."group" = (f->>'category_group')::public.category_group))
    and (f->>'transaction_type' is null or p.transaction_type = (f->>'transaction_type')::public.transaction_type)
    and (f->>'currency'         is null or p.price_currency   = upper(f->>'currency'))
    and (f->>'min_price'        is null or p.price_amount    >= (f->>'min_price')::bigint)
    and (f->>'max_price'        is null or p.price_amount    <= (f->>'max_price')::bigint)
    and (f->>'min_bedrooms'     is null or p.bedrooms        >= (f->>'min_bedrooms')::smallint)
    and (f->>'min_bathrooms'    is null or p.bathrooms       >= (f->>'min_bathrooms')::smallint)
    and (f->>'min_area'         is null or p.area_sqm        >= (f->>'min_area')::numeric)
    and (f->>'max_area'         is null or p.area_sqm        <= (f->>'max_area')::numeric)
    and (f->>'furnishing'       is null or p.furnishing       = f->>'furnishing')
    and (f->>'building_condition' is null or p.building_condition = f->>'building_condition')
    and (coalesce((f->>'verified_owner')::boolean, false) = false or o.identity_verified or coalesce(c.verified, false))
    and (coalesce((f->>'featured')::boolean, false) = false
         or (p.is_featured and (p.featured_until is null or p.featured_until > now())))
    and (f->>'published_within_days' is null
         or p.published_at >= now() - make_interval(days => (f->>'published_within_days')::integer))
    and (v_point is null or extensions.st_dwithin(p.location, v_point, v_radius))
    and (v_bbox  is null or extensions.st_intersects(p.location, v_bbox))
  order by
    case when v_sort = 'price_asc'  then p.price_amount end asc nulls last,
    case when v_sort = 'price_desc' then p.price_amount end desc nulls last,
    case when v_sort = 'area_desc'  then p.area_sqm end desc nulls last,
    case when v_sort = 'popular'    then p.views_count + 3 * p.favorites_count end desc nulls last,
    case when v_sort = 'nearest' and v_point is not null then extensions.st_distance(p.location, v_point) end asc nulls last,
    p.published_at desc, p.id
  limit p_limit offset p_offset;
end;
$$;

-- ===== RLS & grants =======================================================
alter table public.property_views        enable row level security;
alter table public.recently_viewed       enable row level security;
alter table public.saved_searches        enable row level security;
alter table public.search_alerts         enable row level security;
alter table public.property_comparisons  enable row level security;
alter table public.property_reports      enable row level security;
alter table public.verification_requests enable row level security;

create policy recently_viewed_own on public.recently_viewed
  for select to authenticated using (user_id = auth.uid());
create policy recently_viewed_delete_own on public.recently_viewed
  for delete to authenticated using (user_id = auth.uid());
create policy saved_searches_own on public.saved_searches
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy search_alerts_own on public.search_alerts
  for select to authenticated
  using (exists (select 1 from public.saved_searches s where s.id = saved_search_id and s.user_id = auth.uid()));
create policy comparisons_own on public.property_comparisons
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy reports_insert on public.property_reports
  for insert to authenticated
  with check (reporter_id = auth.uid() and public.property_is_public(property_id));
create policy reports_read on public.property_reports
  for select to authenticated using (reporter_id = auth.uid() or public.is_staff());
create policy verification_insert_own on public.verification_requests
  for insert to authenticated with check (user_id = auth.uid());
create policy verification_read on public.verification_requests
  for select to authenticated using (user_id = auth.uid() or public.is_staff());

grant select, delete on public.recently_viewed to authenticated;
grant select, insert, update, delete on public.saved_searches to authenticated;
grant select on public.search_alerts to authenticated;
grant select, insert, update, delete on public.property_comparisons to authenticated;
grant select on public.property_reports to authenticated;
grant insert (property_id, reporter_id, reason, details) on public.property_reports to authenticated;
grant select on public.verification_requests to authenticated;
grant insert (user_id, kind, company_id, property_id, documents) on public.verification_requests to authenticated;

revoke all on function public.search_properties(jsonb, integer, integer) from public;
grant execute on function public.search_properties(jsonb, integer, integer) to anon, authenticated, service_role;
revoke all on function public.record_property_view(uuid) from public, anon;
grant execute on function public.record_property_view(uuid) to authenticated, service_role;
