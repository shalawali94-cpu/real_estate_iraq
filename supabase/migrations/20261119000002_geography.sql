-- Geography: governorates → districts → neighborhoods.
-- Neighborhoods can be suggested by users (status = pending) and approved by staff.

create type public.place_status as enum ('approved', 'pending', 'rejected');

-- Normalizes Arabic/Kurdish/Latin names for duplicate detection.
create or replace function public.normalize_place_name(p text)
returns text
language sql immutable set search_path = ''
as $$
  select regexp_replace(
           translate(
             regexp_replace(lower(trim(p)), '[ً-ْـ]', '', 'g'), -- harakat, tatweel
             'يىكةأإآ', 'ییکەااا'),                                              -- unify letters
           '[\s\-_.''"]+', '', 'g');                                               -- spaces/punctuation
$$;

create table public.governorates (
  id         smallint generated always as identity primary key,
  code       text not null unique,
  name_ckb   text not null,
  name_ar    text not null,
  name_en    text not null,
  center     extensions.geography(point, 4326),
  sort_order smallint not null default 0,
  is_active  boolean not null default true
);

create table public.districts (
  id             integer generated always as identity primary key,
  governorate_id smallint not null references public.governorates (id) on delete restrict,
  name_ckb       text not null,
  name_ar        text not null,
  name_en        text not null,
  center         extensions.geography(point, 4326),
  is_active      boolean not null default true,
  unique (governorate_id, name_en)
);
create index districts_governorate_idx on public.districts (governorate_id);

create table public.neighborhoods (
  id              uuid primary key default gen_random_uuid(),
  district_id     integer not null references public.districts (id) on delete restrict,
  name_ckb        text,
  name_ar         text,
  name_en         text,
  name_original   text not null,               -- as typed by the creator
  original_locale text not null default 'ckb' check (original_locale in ('ckb', 'ar', 'en')),
  name_normalized text generated always as (public.normalize_place_name(name_original)) stored,
  center          extensions.geography(point, 4326),
  status          public.place_status not null default 'approved',
  created_by      uuid references auth.users (id) on delete set null,
  reviewed_by     uuid references auth.users (id) on delete set null,
  reviewed_at     timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint neighborhoods_name_len check (char_length(name_original) between 2 and 80)
);
create index neighborhoods_district_idx on public.neighborhoods (district_id, status);
-- One live entry per normalized name per district (rejected ones don't block).
create unique index neighborhoods_unique_name
  on public.neighborhoods (district_id, name_normalized)
  where status <> 'rejected';
create trigger neighborhoods_updated_at before update on public.neighborhoods
  for each row execute function public.set_updated_at();

-- RLS ---------------------------------------------------------------
alter table public.governorates  enable row level security;
alter table public.districts     enable row level security;
alter table public.neighborhoods enable row level security;

create policy governorates_read on public.governorates
  for select to anon, authenticated using (is_active);
create policy districts_read on public.districts
  for select to anon, authenticated using (is_active);

-- Approved: everyone. Pending: the creator (so they can use it on their own listing) and staff.
create policy neighborhoods_read on public.neighborhoods
  for select to anon, authenticated
  using (status = 'approved'
         or (status = 'pending' and created_by = auth.uid())
         or public.is_staff());
-- No client insert/update/delete: users add via suggest_neighborhood(), staff via backend.

-- User suggestion RPC ---------------------------------------------------
-- Returns the existing neighborhood if the name already exists in that district,
-- otherwise creates a pending one. Max 5 pending suggestions per user per day.
create or replace function public.suggest_neighborhood(
  p_district_id integer,
  p_name        text,
  p_locale      text default 'ckb'
)
returns public.neighborhoods
language plpgsql security definer set search_path = ''
as $$
declare
  v_uid  uuid := auth.uid();
  v_name text := regexp_replace(trim(coalesce(p_name, '')), '\s+', ' ', 'g');
  v_row  public.neighborhoods;
  v_recent int;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = '28000';
  end if;
  if char_length(v_name) not between 2 and 80 then
    raise exception 'VALIDATION_FAILED' using errcode = '22023';
  end if;
  if p_locale not in ('ckb', 'ar', 'en') then
    raise exception 'VALIDATION_FAILED' using errcode = '22023';
  end if;
  if not exists (select 1 from public.districts where id = p_district_id and is_active) then
    raise exception 'NOT_FOUND' using errcode = 'P0002';
  end if;

  select * into v_row from public.neighborhoods
  where district_id = p_district_id
    and name_normalized = public.normalize_place_name(v_name)
    and status <> 'rejected'
  limit 1;
  if found then
    return v_row;
  end if;

  select count(*) into v_recent from public.neighborhoods
  where created_by = v_uid and status = 'pending'
    and created_at > now() - interval '1 day';
  if v_recent >= 5 then
    raise exception 'RATE_LIMITED' using errcode = 'P0001';
  end if;

  insert into public.neighborhoods (district_id, name_original, original_locale, status, created_by,
                                    name_ckb, name_ar, name_en)
  values (p_district_id, v_name, p_locale, 'pending', v_uid,
          case when p_locale = 'ckb' then v_name end,
          case when p_locale = 'ar'  then v_name end,
          case when p_locale = 'en'  then v_name end)
  returning * into v_row;
  return v_row;
end;
$$;

revoke all on function public.suggest_neighborhood(integer, text, text) from public, anon;
grant execute on function public.suggest_neighborhood(integer, text, text) to authenticated;

-- Explicit API grants (project is created with "auto-grant new tables" OFF).
grant select on public.governorates, public.districts, public.neighborhoods to anon, authenticated;
