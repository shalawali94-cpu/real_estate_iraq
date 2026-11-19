-- Categories, features, properties, images, favorites, status history.

-- Fix for profiles_protect_columns (migration 003): check the executing role, not the
-- JWT, so trusted SECURITY DEFINER triggers (e.g. phone confirmation from Auth) pass.
create or replace function public.profiles_protect_columns()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;
  if new.id                is distinct from old.id
  or new.phone             is distinct from old.phone
  or new.phone_verified    is distinct from old.phone_verified
  or new.identity_verified is distinct from old.identity_verified
  or new.rating_avg        is distinct from old.rating_avg
  or new.rating_count      is distinct from old.rating_count
  or new.is_suspended      is distinct from old.is_suspended
  or new.deleted_at        is distinct from old.deleted_at
  or new.created_at        is distinct from old.created_at then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;
  if new.district_id is not null and not exists (
       select 1 from public.districts
       where id = new.district_id and governorate_id = new.governorate_id) then
    raise exception 'VALIDATION_FAILED' using errcode = '22023';
  end if;
  return new;
end;
$$;

create type public.category_group     as enum ('residential', 'commercial', 'land');
create type public.transaction_type   as enum ('sale', 'rent', 'short_term_rent', 'investment');
create type public.publication_status as enum (
  'draft', 'pending_payment', 'payment_processing', 'payment_failed', 'payment_paid',
  'pending_approval', 'approved', 'rejected', 'published', 'suspended', 'expired');
create type public.listing_state      as enum ('active', 'paused', 'sold', 'rented', 'archived');

-- Catalog ----------------------------------------------------------------
create table public.property_categories (
  id                        smallint generated always as identity primary key,
  slug                      text not null unique check (slug ~ '^[a-z_]+$'),
  "group"                   public.category_group not null,
  name_ckb                  text not null,
  name_ar                   text not null,
  name_en                   text not null,
  icon                      text,
  fields                    text[] not null default '{}',   -- which detail fields the form shows
  allowed_transaction_types public.transaction_type[] not null
                            default '{sale,rent,short_term_rent,investment}',
  sort_order                smallint not null default 0,
  is_active                 boolean not null default true
);

create table public.property_features (
  id         smallint generated always as identity primary key,
  slug       text not null unique,
  name_ckb   text not null,
  name_ar    text not null,
  name_en    text not null,
  icon       text,
  is_active  boolean not null default true
);

-- Properties -------------------------------------------------------------
create table public.properties (
  id                   uuid primary key default gen_random_uuid(),
  owner_id             uuid not null references auth.users (id) on delete cascade,
  category_id          smallint not null references public.property_categories (id),
  transaction_type     public.transaction_type not null,
  title                text not null check (char_length(title) between 5 and 120),
  description          text check (char_length(description) <= 5000),
  price_amount         bigint not null check (price_amount > 0),  -- minor units (IQD: dinars, USD: cents)
  price_currency       char(3) not null default 'IQD' check (price_currency in ('IQD', 'USD')),
  price_negotiable     boolean not null default false,
  governorate_id       smallint not null references public.governorates (id),
  district_id          integer not null references public.districts (id),
  neighborhood_id      uuid references public.neighborhoods (id),
  address_text         text check (char_length(address_text) <= 200),
  location             extensions.geography(point, 4326),
  area_sqm             numeric(10,2) check (area_sqm > 0),
  bedrooms             smallint check (bedrooms between 0 and 50),
  bathrooms            smallint check (bathrooms between 0 and 50),
  floors               smallint check (floors between 0 and 200),
  floor_number         smallint check (floor_number between -5 and 200),
  property_age_years   smallint check (property_age_years between 0 and 200),
  building_condition   text check (building_condition in ('new', 'excellent', 'good', 'needs_renovation', 'under_construction')),
  furnishing           text check (furnishing in ('unfurnished', 'semi_furnished', 'furnished')),
  has_parking          boolean,
  heating              text check (heating in ('none', 'central', 'split', 'other')),
  cooling              text check (cooling in ('none', 'central', 'split', 'other')),
  electricity          text check (electricity in ('national', 'national_generator', 'generator', 'solar', 'none')),
  water                text check (water in ('municipal', 'well', 'tank', 'none')),
  has_internet         boolean,
  ownership_doc_status text check (ownership_doc_status in ('tapu', 'agricultural_contract', 'investment_contract', 'other', 'unknown')),
  availability_date    date,
  contact_phone        text check (contact_phone ~ '^\+9647[0-9]{9}$'),
  show_phone           boolean not null default true,
  attributes           jsonb not null default '{}',
  -- managed by the backend / moderation only
  publication_status   public.publication_status not null default 'draft',
  listing_state        public.listing_state not null default 'active',
  rejection_reason     text,
  is_featured          boolean not null default false,
  featured_until       timestamptz,
  published_at         timestamptz,
  expires_at           timestamptz,
  views_count          integer not null default 0,
  favorites_count      integer not null default 0,
  search_tsv           tsvector generated always as (
                         to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(description, ''))) stored,
  deleted_at           timestamptz,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

create index properties_public_feed_idx on public.properties (published_at desc)
  where publication_status = 'published' and listing_state = 'active' and deleted_at is null;
create index properties_owner_idx       on public.properties (owner_id, created_at desc);
create index properties_location_idx    on public.properties (governorate_id, district_id, neighborhood_id);
create index properties_category_idx    on public.properties (category_id, transaction_type);
create index properties_price_idx       on public.properties (price_currency, price_amount);
create index properties_area_idx        on public.properties (area_sqm);
create index properties_geo_idx         on public.properties using gist (location);
create index properties_tsv_idx         on public.properties using gin (search_tsv);
create index properties_title_trgm_idx  on public.properties using gin (title extensions.gin_trgm_ops);
create index properties_status_idx      on public.properties (publication_status, created_at);

create trigger properties_updated_at before update on public.properties
  for each row execute function public.set_updated_at();

-- Consistency: district belongs to governorate, neighborhood to district,
-- category allows the transaction type.
create or replace function public.properties_validate()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if not exists (select 1 from public.districts
                 where id = new.district_id and governorate_id = new.governorate_id) then
    raise exception 'VALIDATION_FAILED: district' using errcode = '22023';
  end if;
  if new.neighborhood_id is not null and not exists (
       select 1 from public.neighborhoods
       where id = new.neighborhood_id and district_id = new.district_id and status <> 'rejected') then
    raise exception 'VALIDATION_FAILED: neighborhood' using errcode = '22023';
  end if;
  if not exists (select 1 from public.property_categories
                 where id = new.category_id and is_active
                   and new.transaction_type = any (allowed_transaction_types)) then
    raise exception 'VALIDATION_FAILED: category' using errcode = '22023';
  end if;
  return new;
end;
$$;

create trigger properties_validate before insert or update on public.properties
  for each row execute function public.properties_validate();

-- Clients may only create drafts, and may never touch moderation/payment columns.
-- Owners edit content only while draft / rejected / payment_failed; on published
-- listings they may only change listing_state (pause, sold, rented, archived).
create or replace function public.properties_protect()
returns trigger language plpgsql set search_path = ''
as $$
begin
  -- Only API roles are restricted; service_role and trusted SECURITY DEFINER
  -- functions (running as postgres) pass.
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.owner_id is distinct from auth.uid()
       or new.publication_status <> 'draft' or new.listing_state <> 'active'
       or new.is_featured or new.featured_until is not null
       or new.published_at is not null or new.expires_at is not null
       or new.views_count <> 0 or new.favorites_count <> 0
       or new.rejection_reason is not null or new.deleted_at is not null then
      raise exception 'FORBIDDEN' using errcode = '42501';
    end if;
    return new;
  end if;

  if new.owner_id           is distinct from old.owner_id
  or new.publication_status is distinct from old.publication_status
  or new.rejection_reason   is distinct from old.rejection_reason
  or new.is_featured        is distinct from old.is_featured
  or new.featured_until     is distinct from old.featured_until
  or new.published_at       is distinct from old.published_at
  or new.expires_at         is distinct from old.expires_at
  or new.views_count        is distinct from old.views_count
  or new.favorites_count    is distinct from old.favorites_count
  or new.created_at         is distinct from old.created_at then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if old.deleted_at is not null then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  -- listing_state only on published listings
  if new.listing_state is distinct from old.listing_state
     and old.publication_status <> 'published' then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  -- content edits only while editable
  if old.publication_status not in ('draft', 'rejected', 'payment_failed')
     and (to_jsonb(new) - array['listing_state', 'deleted_at', 'updated_at', 'search_tsv'])
         is distinct from
         (to_jsonb(old) - array['listing_state', 'deleted_at', 'updated_at', 'search_tsv']) then
    raise exception 'PROPERTY_NOT_EDITABLE' using errcode = '42501';
  end if;

  return new;
end;
$$;

create trigger properties_protect before insert or update on public.properties
  for each row execute function public.properties_protect();

-- Immutable status history.
create table public.property_status_history (
  id          bigint generated always as identity primary key,
  property_id uuid not null references public.properties (id) on delete cascade,
  from_status public.publication_status,
  to_status   public.publication_status not null,
  actor_id    uuid,
  reason      text,
  created_at  timestamptz not null default now()
);
create index property_status_history_idx on public.property_status_history (property_id, created_at);

create or replace function public.properties_log_status()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or new.publication_status is distinct from old.publication_status then
    insert into public.property_status_history (property_id, from_status, to_status, actor_id, reason)
    values (new.id,
            case when tg_op = 'UPDATE' then old.publication_status end,
            new.publication_status, auth.uid(), new.rejection_reason);
  end if;
  return new;
end;
$$;

create trigger properties_log_status after insert or update on public.properties
  for each row execute function public.properties_log_status();

-- Images ------------------------------------------------------------------
create table public.property_images (
  id           uuid primary key default gen_random_uuid(),
  property_id  uuid not null references public.properties (id) on delete cascade,
  owner_id     uuid not null references auth.users (id) on delete cascade,
  storage_path text not null unique,
  thumb_path   text,
  width        integer,
  height       integer,
  bytes        integer,
  mime         text,
  sort_order   smallint not null default 0,
  is_cover     boolean not null default false,
  phash        bigint,
  ai_variant_of uuid references public.property_images (id) on delete set null,
  ai_label     text check (ai_label in ('enhanced', 'edited', 'virtual_staging')),
  status       text not null default 'uploaded' check (status in ('uploaded', 'verified', 'rejected')),
  created_at   timestamptz not null default now()
);
create index property_images_property_idx on public.property_images (property_id, sort_order);
create unique index property_images_one_cover on public.property_images (property_id) where is_cover;

-- Max 20 photos per property (spec), AI variants excluded.
create or replace function public.property_images_limit()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if new.ai_variant_of is null and (
       select count(*) from public.property_images
       where property_id = new.property_id and ai_variant_of is null) >= 20 then
    raise exception 'VALIDATION_FAILED: max 20 photos' using errcode = '22023';
  end if;
  return new;
end;
$$;
create trigger property_images_limit before insert on public.property_images
  for each row execute function public.property_images_limit();

-- Favorites ---------------------------------------------------------------
create table public.property_favorites (
  user_id     uuid not null references auth.users (id) on delete cascade,
  property_id uuid not null references public.properties (id) on delete cascade,
  folder      text check (char_length(folder) <= 40),
  created_at  timestamptz not null default now(),
  primary key (user_id, property_id)
);
create index property_favorites_property_idx on public.property_favorites (property_id);

create or replace function public.property_favorites_count()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.properties set favorites_count = favorites_count + 1 where id = new.property_id;
  else
    update public.properties set favorites_count = greatest(favorites_count - 1, 0) where id = old.property_id;
  end if;
  return null;
end;
$$;
create trigger property_favorites_count after insert or delete on public.property_favorites
  for each row execute function public.property_favorites_count();

-- Helper: is this property visible to everyone? -----------------------------
create or replace function public.property_is_public(p_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.properties
                 where id = p_id and publication_status = 'published'
                   and listing_state = 'active' and deleted_at is null);
$$;

create or replace function public.property_is_mine_editable(p_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.properties
                 where id = p_id and owner_id = auth.uid() and deleted_at is null
                   and publication_status in ('draft', 'rejected', 'payment_failed'));
$$;

-- RLS ---------------------------------------------------------------------
alter table public.property_categories     enable row level security;
alter table public.property_features       enable row level security;
alter table public.properties              enable row level security;
alter table public.property_status_history enable row level security;
alter table public.property_images         enable row level security;
alter table public.property_favorites      enable row level security;

create policy categories_read on public.property_categories
  for select to anon, authenticated using (is_active);
create policy features_read on public.property_features
  for select to anon, authenticated using (is_active);

create policy properties_read on public.properties
  for select to anon, authenticated
  using ((publication_status = 'published' and listing_state = 'active' and deleted_at is null)
         or owner_id = auth.uid()
         or public.is_staff());
create policy properties_insert_own on public.properties
  for insert to authenticated with check (owner_id = auth.uid());
create policy properties_update_own on public.properties
  for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy status_history_read on public.property_status_history
  for select to authenticated
  using (public.is_staff()
         or exists (select 1 from public.properties p where p.id = property_id and p.owner_id = auth.uid()));

create policy images_read on public.property_images
  for select to anon, authenticated
  using ((status <> 'rejected' and public.property_is_public(property_id))
         or owner_id = auth.uid() or public.is_staff());
create policy images_insert_own on public.property_images
  for insert to authenticated
  with check (owner_id = auth.uid() and public.property_is_mine_editable(property_id));
create policy images_update_own on public.property_images
  for update to authenticated
  using (owner_id = auth.uid() and public.property_is_mine_editable(property_id))
  with check (owner_id = auth.uid());
create policy images_delete_own on public.property_images
  for delete to authenticated
  using (owner_id = auth.uid() and public.property_is_mine_editable(property_id));

create policy favorites_own on public.property_favorites
  for all to authenticated using (user_id = auth.uid())
  with check (user_id = auth.uid() and public.property_is_public(property_id));

-- Grants (auto-grant is OFF on the project) ---------------------------------
grant select on public.property_categories, public.property_features to anon, authenticated;
grant select on public.properties to anon, authenticated;
grant insert, update on public.properties to authenticated;
grant select on public.property_status_history to authenticated;
grant select on public.property_images to anon, authenticated;
grant insert, delete on public.property_images to authenticated;
grant update (sort_order, is_cover) on public.property_images to authenticated;
grant select, insert, update, delete on public.property_favorites to authenticated;
revoke all on function public.property_is_public(uuid) from public;
revoke all on function public.property_is_mine_editable(uuid) from public;
grant execute on function public.property_is_public(uuid) to anon, authenticated;
grant execute on function public.property_is_mine_editable(uuid) to authenticated;

-- Storage: property media. Path = {user_id}/{property_id}/{file}.
-- Size/MIME re-verified server-side on confirm (Phase 4).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('property-media', 'property-media', true, 209715200,
        array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'video/mp4', 'video/quicktime'])
on conflict (id) do nothing;

create policy property_media_insert_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'property-media'
              and (storage.foldername(name))[1] = auth.uid()::text
              and public.property_is_mine_editable(((storage.foldername(name))[2])::uuid));
create policy property_media_delete_own on storage.objects
  for delete to authenticated
  using (bucket_id = 'property-media'
         and (storage.foldername(name))[1] = auth.uid()::text
         and public.property_is_mine_editable(((storage.foldername(name))[2])::uuid));

-- Public-read policies (anon) call is_staff(); it simply returns false for anon.
grant execute on function public.is_staff() to anon;
