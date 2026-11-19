-- Companies (agencies / developers), members, leads.

create type public.company_role   as enum ('owner', 'manager', 'agent', 'viewer');
create type public.lead_source    as enum ('call', 'whatsapp', 'message');
create type public.lead_status    as enum ('new', 'contacted', 'qualified', 'closed_won', 'closed_lost');

create table public.companies (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null references auth.users (id) on delete restrict,
  name            text not null check (char_length(name) between 2 and 100),
  slug            text not null unique check (slug ~ '^[a-z0-9-]{3,60}$'),
  logo_path       text,
  description_ckb text check (char_length(description_ckb) <= 3000),
  description_ar  text check (char_length(description_ar) <= 3000),
  description_en  text check (char_length(description_en) <= 3000),
  governorate_id  smallint references public.governorates (id),
  district_id     integer references public.districts (id),
  office_address  text check (char_length(office_address) <= 200),
  office_location extensions.geography(point, 4326),
  phones          text[] not null default '{}',
  socials         jsonb not null default '{}',
  is_developer    boolean not null default false,
  verified        boolean not null default false,       -- staff only
  deleted_at      timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index companies_owner_idx on public.companies (owner_id);
create trigger companies_updated_at before update on public.companies
  for each row execute function public.set_updated_at();

create table public.company_members (
  company_id uuid not null references public.companies (id) on delete cascade,
  user_id    uuid not null references auth.users (id) on delete cascade,
  role       public.company_role not null default 'agent',
  status     text not null default 'active' check (status in ('invited', 'active', 'removed')),
  invited_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  primary key (company_id, user_id)
);
create index company_members_user_idx on public.company_members (user_id) where status = 'active';

-- Role of the current user in a company (null if none).
create or replace function public.company_role_of(p_company uuid)
returns public.company_role language sql stable security definer set search_path = ''
as $$
  select role from public.company_members
  where company_id = p_company and user_id = auth.uid() and status = 'active';
$$;
revoke all on function public.company_role_of(uuid) from public;
grant execute on function public.company_role_of(uuid) to anon, authenticated, service_role;

-- The creator becomes the owner member.
create or replace function public.companies_add_owner()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.company_members (company_id, user_id, role, status)
  values (new.id, new.owner_id, 'owner', 'active');
  return new;
end;
$$;
create trigger companies_add_owner after insert on public.companies
  for each row execute function public.companies_add_owner();

create or replace function public.companies_protect()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;
  if tg_op = 'INSERT' then
    if new.owner_id is distinct from auth.uid() or new.verified or new.deleted_at is not null then
      raise exception 'FORBIDDEN' using errcode = '42501';
    end if;
    return new;
  end if;
  if new.owner_id is distinct from old.owner_id or new.verified is distinct from old.verified
     or new.created_at is distinct from old.created_at then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;
  return new;
end;
$$;
create trigger companies_protect before insert or update on public.companies
  for each row execute function public.companies_protect();

-- Listings can belong to a company and be assigned to an agent.
alter table public.properties
  add column company_id        uuid references public.companies (id) on delete set null,
  add column assigned_agent_id uuid references auth.users (id) on delete set null;
create index properties_company_idx on public.properties (company_id) where company_id is not null;

-- Company members (any role) can see the company's listings in every status.
drop policy properties_read on public.properties;
create policy properties_read on public.properties
  for select to anon, authenticated
  using ((publication_status = 'published' and listing_state = 'active' and deleted_at is null)
         or owner_id = auth.uid()
         or (company_id is not null and public.company_role_of(company_id) is not null)
         or public.is_staff());

-- A client may only attach a listing to a company where they are owner/manager/agent.
create or replace function public.properties_company_check()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;
  if new.company_id is not null
     and (tg_op = 'INSERT' or new.company_id is distinct from old.company_id)
     and coalesce(public.company_role_of(new.company_id)::text, 'viewer') = 'viewer' then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;
  if new.assigned_agent_id is not null
     and (tg_op = 'INSERT' or new.assigned_agent_id is distinct from old.assigned_agent_id)
     and not exists (select 1 from public.company_members
                     where company_id = new.company_id and user_id = new.assigned_agent_id and status = 'active') then
    raise exception 'VALIDATION_FAILED: agent' using errcode = '22023';
  end if;
  return new;
end;
$$;
create trigger properties_company_check before insert or update on public.properties
  for each row execute function public.properties_company_check();

-- Leads --------------------------------------------------------------------
create table public.leads (
  id          uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  company_id  uuid references public.companies (id) on delete set null,
  owner_id    uuid not null references auth.users (id) on delete cascade,   -- listing owner
  customer_id uuid not null references auth.users (id) on delete cascade,
  source      public.lead_source not null,
  status      public.lead_status not null default 'new',
  assigned_to uuid references auth.users (id) on delete set null,
  note        text check (char_length(note) <= 1000),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (property_id, customer_id, source)
);
create index leads_owner_idx   on public.leads (owner_id, created_at desc);
create index leads_company_idx on public.leads (company_id, created_at desc) where company_id is not null;
create trigger leads_updated_at before update on public.leads
  for each row execute function public.set_updated_at();

-- Called by the app when a buyer taps Call / WhatsApp / Message.
create or replace function public.lead_record(p_property uuid, p_source public.lead_source)
returns void language plpgsql security definer set search_path = ''
as $$
declare
  v_prop public.properties;
begin
  if auth.uid() is null then
    raise exception 'UNAUTHENTICATED' using errcode = '28000';
  end if;
  select * into v_prop from public.properties where id = p_property;
  if not found or not public.property_is_public(p_property) then
    raise exception 'NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_prop.owner_id = auth.uid() then
    return;                                   -- owners viewing their own listing
  end if;
  insert into public.leads (property_id, company_id, owner_id, customer_id, source, assigned_to)
  values (p_property, v_prop.company_id, v_prop.owner_id, auth.uid(), p_source, v_prop.assigned_agent_id)
  on conflict (property_id, customer_id, source) do nothing;
end;
$$;
revoke all on function public.lead_record(uuid, public.lead_source) from public, anon;
grant execute on function public.lead_record(uuid, public.lead_source) to authenticated, service_role;

-- RLS ----------------------------------------------------------------------
alter table public.companies       enable row level security;
alter table public.company_members enable row level security;
alter table public.leads           enable row level security;

create policy companies_read on public.companies
  for select to anon, authenticated using (deleted_at is null or public.is_staff());
create policy companies_insert on public.companies
  for insert to authenticated with check (owner_id = auth.uid());
create policy companies_update on public.companies
  for update to authenticated
  using (public.company_role_of(id) in ('owner', 'manager'))
  with check (public.company_role_of(id) in ('owner', 'manager'));

-- Members see their colleagues; adding/removing members goes through the backend (invites).
create policy company_members_read on public.company_members
  for select to authenticated
  using (user_id = auth.uid() or public.company_role_of(company_id) is not null or public.is_staff());

create policy leads_read on public.leads
  for select to authenticated
  using (owner_id = auth.uid()
         or assigned_to = auth.uid()
         or (company_id is not null and public.company_role_of(company_id) in ('owner', 'manager'))
         or public.is_staff());
create policy leads_update on public.leads
  for update to authenticated
  using (owner_id = auth.uid() or assigned_to = auth.uid()
         or (company_id is not null and public.company_role_of(company_id) in ('owner', 'manager')));

grant select on public.companies to anon, authenticated;
grant insert on public.companies to authenticated;
grant update (name, slug, logo_path, description_ckb, description_ar, description_en, governorate_id,
              district_id, office_address, office_location, phones, socials, is_developer, deleted_at)
  on public.companies to authenticated;
grant select on public.company_members to authenticated;
grant select on public.leads to authenticated;
grant update (status, assigned_to, note) on public.leads to authenticated;
