-- Profiles, devices, blocks, avatars bucket.

create type public.account_type as enum ('individual', 'owner', 'agent', 'company', 'developer');

create table public.profiles (
  id                uuid primary key references auth.users (id) on delete cascade,
  full_name         text check (char_length(full_name) between 2 and 80),
  avatar_path       text,
  phone             text,
  email             text,
  governorate_id    smallint references public.governorates (id),
  district_id       integer references public.districts (id),
  account_type      public.account_type not null default 'individual',
  preferred_locale  text not null default 'ckb' check (preferred_locale in ('ckb', 'ar', 'en')),
  show_phone        boolean not null default true,
  -- protected: changed only by the backend (service role)
  phone_verified    boolean not null default false,
  identity_verified boolean not null default false,
  rating_avg        numeric(3,2) not null default 0,
  rating_count      integer not null default 0,
  is_suspended      boolean not null default false,
  onboarded_at      timestamptz,
  deleted_at        timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index profiles_location_idx on public.profiles (governorate_id, district_id);

create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

-- Create a profile row for every new auth user (phone comes from Supabase phone auth).
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, phone, email, phone_verified)
  values (new.id, new.phone, new.email, new.phone_confirmed_at is not null)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep phone_verified in sync when Supabase confirms the phone.
create or replace function public.handle_user_phone_confirmed()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  update public.profiles
     set phone = new.phone,
         phone_verified = new.phone_confirmed_at is not null
   where id = new.id;
  return new;
end;
$$;

create trigger on_auth_user_phone_confirmed
  after update of phone, phone_confirmed_at on auth.users
  for each row execute function public.handle_user_phone_confirmed();

-- Block client changes to protected columns (the service role bypasses this).
create or replace function public.profiles_protect_columns()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if coalesce(auth.role(), '') = 'service_role' then
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

create trigger profiles_protect before update on public.profiles
  for each row execute function public.profiles_protect_columns();

alter table public.profiles enable row level security;

create policy profiles_select_own on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_staff());
create policy profiles_update_own on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

grant select on public.profiles to authenticated;
grant update (full_name, avatar_path, email, governorate_id, district_id, account_type,
              preferred_locale, show_phone, onboarded_at)
  on public.profiles to authenticated;

-- Public view: what anyone may see about a user. Phone only when they allow it.
create view public.public_profiles
with (security_invoker = false) as
select p.id, p.full_name, p.avatar_path, p.account_type,
       p.governorate_id, p.district_id,
       case when p.show_phone then p.phone end as phone,
       p.phone_verified, p.identity_verified, p.rating_avg, p.rating_count, p.created_at
from public.profiles p
where p.deleted_at is null and not p.is_suspended;

revoke all on public.public_profiles from public;
grant select on public.public_profiles to anon, authenticated;

-- Push notification device tokens.
create table public.user_devices (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  fcm_token    text not null unique,
  platform     text not null check (platform in ('android', 'ios')),
  locale       text not null default 'ckb' check (locale in ('ckb', 'ar', 'en')),
  last_seen_at timestamptz not null default now()
);
create index user_devices_user_idx on public.user_devices (user_id);
alter table public.user_devices enable row level security;
create policy user_devices_own on public.user_devices
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
grant select, insert, update, delete on public.user_devices to authenticated;

-- Blocking between users.
create table public.user_blocks (
  blocker_id uuid not null references auth.users (id) on delete cascade,
  blocked_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
alter table public.user_blocks enable row level security;
create policy user_blocks_own on public.user_blocks
  for all to authenticated using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());
grant select, insert, delete on public.user_blocks to authenticated;

-- Avatars: public read, each user writes only under their own folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy avatars_insert_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy avatars_update_own on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy avatars_delete_own on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
