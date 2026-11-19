-- Central payment engine. All state changes happen in SECURITY DEFINER functions
-- that only the backend (service_role) may execute. Clients can only read their own rows.

-- service_role needs explicit privileges because auto-grant is OFF on the project.
grant usage on schema public to service_role;
grant all on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;
alter default privileges in schema public grant all on tables to service_role;
alter default privileges in schema public grant usage, select on sequences to service_role;

create type public.service_type     as enum ('PROPERTY_PUBLISHING', 'AI_VIDEO_GENERATION');
create type public.payment_provider as enum ('FIB', 'QI_CARD');
create type public.payment_status   as enum ('created', 'pending', 'processing', 'paid', 'failed',
                                             'cancelled', 'expired', 'refunded', 'partially_refunded');
create type public.refund_status    as enum ('none', 'requested', 'processing', 'completed', 'failed');

-- Prices: editable by super admin (through the backend), every change audited.
create table public.payment_settings (
  service_type               public.service_type primary key,
  price_amount               bigint not null check (price_amount > 0),
  currency                   char(3) not null default 'IQD' check (currency = 'IQD'),
  is_enabled                 boolean not null default true,
  applies_to_transaction_types public.transaction_type[] not null default '{sale}',
  updated_by                 uuid references auth.users (id),
  updated_at                 timestamptz not null default now()
);

insert into public.payment_settings (service_type, price_amount, applies_to_transaction_types) values
  ('PROPERTY_PUBLISHING', 30000, '{sale}'),
  ('AI_VIDEO_GENERATION', 30000, '{sale,rent,short_term_rent,investment}');

create table public.payment_orders (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references auth.users (id) on delete restrict,
  service_type       public.service_type not null,
  property_id        uuid references public.properties (id) on delete restrict,
  ai_job_id          uuid,                       -- FK added with ai_jobs (Phase 7)
  provider           public.payment_provider not null,
  amount             bigint not null check (amount > 0),
  currency           char(3) not null check (currency = 'IQD'),
  status             public.payment_status not null default 'created',
  idempotency_key    text not null check (char_length(idempotency_key) between 8 and 100),
  internal_reference text not null unique,
  failure_reason     text,
  refund_status      public.refund_status not null default 'none',
  paid_at            timestamptz,
  expires_at         timestamptz not null default now() + interval '30 minutes',
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (user_id, idempotency_key),
  check ((service_type = 'PROPERTY_PUBLISHING' and property_id is not null)
      or (service_type = 'AI_VIDEO_GENERATION' and ai_job_id is not null))
);
create index payment_orders_user_idx   on public.payment_orders (user_id, created_at desc);
create index payment_orders_status_idx on public.payment_orders (status, created_at);
-- At most one live-or-paid order per property publishing / per AI job: no double charge.
create unique index payment_orders_one_live_property on public.payment_orders (property_id)
  where service_type = 'PROPERTY_PUBLISHING' and status in ('created', 'pending', 'processing', 'paid');
create unique index payment_orders_one_live_ai_job on public.payment_orders (ai_job_id)
  where service_type = 'AI_VIDEO_GENERATION' and status in ('created', 'pending', 'processing', 'paid');
create trigger payment_orders_updated_at before update on public.payment_orders
  for each row execute function public.set_updated_at();

create table public.payment_transactions (
  id                  uuid primary key default gen_random_uuid(),
  order_id            uuid not null references public.payment_orders (id) on delete restrict,
  provider            public.payment_provider not null,
  provider_payment_id text not null,
  amount              bigint not null,
  currency            char(3) not null,
  status              public.payment_status not null default 'pending',
  provider_payload    jsonb not null default '{}',
  valid_until         timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  unique (provider, provider_payment_id)
);
create index payment_transactions_order_idx on public.payment_transactions (order_id);
create trigger payment_transactions_updated_at before update on public.payment_transactions
  for each row execute function public.set_updated_at();

-- Raw webhook / callback events, deduplicated. Never trusted alone.
create table public.payment_provider_events (
  id               bigint generated always as identity primary key,
  provider         public.payment_provider not null,
  dedup_key        text not null,
  payload          jsonb not null,
  signature_valid  boolean,
  processed_at     timestamptz,
  processing_error text,
  received_at      timestamptz not null default now(),
  unique (provider, dedup_key)
);

create table public.payment_refunds (
  id                 uuid primary key default gen_random_uuid(),
  order_id           uuid not null references public.payment_orders (id) on delete restrict,
  transaction_id     uuid references public.payment_transactions (id),
  amount             bigint not null check (amount > 0),
  reason             text not null,
  status             public.refund_status not null default 'requested',
  provider_refund_id text,
  manual_reference   text,
  requested_by       uuid references auth.users (id),
  approved_by        uuid references auth.users (id),
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create trigger payment_refunds_updated_at before update on public.payment_refunds
  for each row execute function public.set_updated_at();

-- Append-only audit trail.
create table public.payment_audit_logs (
  id          bigint generated always as identity primary key,
  order_id    uuid references public.payment_orders (id) on delete restrict,
  actor       text not null,           -- 'system' | 'user:<uuid>' | 'admin:<uuid>' | 'provider:<name>'
  action      text not null,
  from_status public.payment_status,
  to_status   public.payment_status,
  details     jsonb not null default '{}',
  created_at  timestamptz not null default now()
);
create index payment_audit_logs_order_idx on public.payment_audit_logs (order_id, created_at);

create or replace function public.forbid_mutation()
returns trigger language plpgsql set search_path = ''
as $$
begin
  raise exception 'APPEND_ONLY: % on %', tg_op, tg_table_name using errcode = '42501';
end;
$$;
create trigger payment_audit_logs_append_only before update or delete on public.payment_audit_logs
  for each row execute function public.forbid_mutation();
create trigger payment_provider_events_no_delete before delete on public.payment_provider_events
  for each row execute function public.forbid_mutation();

-- Helpers ------------------------------------------------------------------
create or replace function public.payment_new_reference()
returns text language sql volatile set search_path = ''
as $$
  select 'REI-' || to_char(now() at time zone 'Asia/Baghdad', 'YYMMDD') || '-'
         || upper(substr(encode(extensions.gen_random_bytes(5), 'hex'), 1, 8));
$$;

create or replace function public.payment_log(p_order uuid, p_actor text, p_action text,
  p_from public.payment_status, p_to public.payment_status, p_details jsonb default '{}')
returns void language sql security definer set search_path = ''
as $$
  insert into public.payment_audit_logs (order_id, actor, action, from_status, to_status, details)
  values (p_order, p_actor, p_action, p_from, p_to, coalesce(p_details, '{}'));
$$;

-- Does this property need the publishing fee?
create or replace function public.property_fee_required(p_property uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select coalesce((
    select s.is_enabled and p.transaction_type = any (s.applies_to_transaction_types)
    from public.properties p, public.payment_settings s
    where p.id = p_property and s.service_type = 'PROPERTY_PUBLISHING'), false);
$$;

-- Submit a draft. No fee → straight to moderation. Fee → pending_payment.
create or replace function public.property_submit(p_user uuid, p_property uuid)
returns public.publication_status
language plpgsql security definer set search_path = ''
as $$
declare
  v_prop public.properties;
  v_next public.publication_status;
begin
  select * into v_prop from public.properties where id = p_property for update;
  if not found or v_prop.owner_id <> p_user or v_prop.deleted_at is not null then
    raise exception 'NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_prop.publication_status not in ('draft', 'rejected', 'payment_failed', 'pending_payment') then
    raise exception 'PROPERTY_NOT_SUBMITTABLE' using errcode = 'P0001';
  end if;
  -- Already paid for this listing (e.g. resubmitting after rejection): no new fee.
  if exists (select 1 from public.payment_orders
             where property_id = p_property and service_type = 'PROPERTY_PUBLISHING' and status = 'paid') then
    v_next := 'pending_approval';
  elsif public.property_fee_required(p_property) then
    v_next := 'pending_payment';
  else
    v_next := 'pending_approval';
  end if;
  update public.properties set publication_status = v_next, rejection_reason = null where id = p_property;
  return v_next;
end;
$$;

-- Create (or reuse) a payment order. Idempotent per (user, key) and per subject.
create or replace function public.payment_create_order(
  p_user uuid, p_service public.service_type, p_property uuid, p_ai_job uuid,
  p_provider public.payment_provider, p_idempotency_key text)
returns public.payment_orders
language plpgsql security definer set search_path = ''
as $$
declare
  v_order    public.payment_orders;
  v_prop     public.properties;
  v_settings public.payment_settings;
begin
  -- same request repeated → same order
  select * into v_order from public.payment_orders
  where user_id = p_user and idempotency_key = p_idempotency_key;
  if found then
    return v_order;
  end if;

  select * into v_settings from public.payment_settings where service_type = p_service;
  if not found or not v_settings.is_enabled then
    raise exception 'PAYMENT_NOT_REQUIRED' using errcode = 'P0001';
  end if;

  if p_service = 'PROPERTY_PUBLISHING' then
    select * into v_prop from public.properties where id = p_property for update;
    if not found or v_prop.owner_id <> p_user or v_prop.deleted_at is not null then
      raise exception 'NOT_FOUND' using errcode = 'P0002';
    end if;
    if not public.property_fee_required(p_property) then
      raise exception 'PAYMENT_NOT_REQUIRED' using errcode = 'P0001';
    end if;
    if v_prop.publication_status not in ('pending_payment', 'payment_failed', 'payment_processing') then
      raise exception 'PROPERTY_NOT_SUBMITTABLE' using errcode = 'P0001';
    end if;
    -- a live or paid order already exists for this property
    select * into v_order from public.payment_orders
    where property_id = p_property and service_type = 'PROPERTY_PUBLISHING'
      and status in ('created', 'pending', 'processing', 'paid');
    if found then
      if v_order.status = 'paid' then
        raise exception 'PAYMENT_ALREADY_PAID' using errcode = 'P0001';
      end if;
      if v_order.expires_at > now() and v_order.provider = p_provider then
        return v_order;
      end if;
      -- expired or switching provider: close the old one first
      update public.payment_orders set status = 'cancelled', failure_reason = 'SUPERSEDED'
      where id = v_order.id;
      perform public.payment_log(v_order.id, 'system', 'superseded', v_order.status, 'cancelled');
    end if;
  else
    raise exception 'AI_JOB_NOT_PAYABLE' using errcode = 'P0001';  -- enabled with ai_jobs (Phase 7)
  end if;

  insert into public.payment_orders (user_id, service_type, property_id, ai_job_id, provider,
                                     amount, currency, idempotency_key, internal_reference)
  values (p_user, p_service, p_property, p_ai_job, p_provider,
          v_settings.price_amount, v_settings.currency, p_idempotency_key, public.payment_new_reference())
  returning * into v_order;

  update public.properties set publication_status = 'payment_processing' where id = p_property;
  perform public.payment_log(v_order.id, 'user:' || p_user, 'order_created', null, 'created',
                             jsonb_build_object('amount', v_order.amount, 'provider', p_provider));
  return v_order;
end;
$$;

-- Record the provider's payment id after createPayment succeeded.
create or replace function public.payment_attach_transaction(
  p_order uuid, p_provider_payment_id text, p_payload jsonb, p_valid_until timestamptz)
returns public.payment_transactions
language plpgsql security definer set search_path = ''
as $$
declare
  v_order public.payment_orders;
  v_tx    public.payment_transactions;
begin
  select * into v_order from public.payment_orders where id = p_order for update;
  if not found then
    raise exception 'NOT_FOUND' using errcode = 'P0002';
  end if;
  insert into public.payment_transactions (order_id, provider, provider_payment_id, amount, currency,
                                           status, provider_payload, valid_until)
  values (p_order, v_order.provider, p_provider_payment_id, v_order.amount, v_order.currency,
          'pending', coalesce(p_payload, '{}'), p_valid_until)
  returning * into v_tx;
  if v_order.status = 'created' then
    update public.payment_orders set status = 'pending' where id = p_order;
    perform public.payment_log(p_order, 'provider:' || v_order.provider, 'transaction_created',
                               'created', 'pending', jsonb_build_object('provider_payment_id', p_provider_payment_id));
  end if;
  return v_tx;
end;
$$;

-- Called ONLY after the backend verified the status with the provider server-to-server.
create or replace function public.payment_mark_paid(
  p_provider public.payment_provider, p_provider_payment_id text,
  p_amount bigint, p_currency text, p_payload jsonb)
returns public.payment_orders
language plpgsql security definer set search_path = ''
as $$
declare
  v_tx    public.payment_transactions;
  v_order public.payment_orders;
begin
  select * into v_tx from public.payment_transactions
  where provider = p_provider and provider_payment_id = p_provider_payment_id for update;
  if not found then
    raise exception 'NOT_FOUND' using errcode = 'P0002';
  end if;
  select * into v_order from public.payment_orders where id = v_tx.order_id for update;

  if v_order.status = 'paid' then
    return v_order;                                   -- idempotent: duplicate webhook / poll
  end if;

  if p_amount <> v_order.amount or upper(p_currency) <> v_order.currency then
    update public.payment_transactions set status = 'failed', provider_payload = coalesce(p_payload, '{}')
    where id = v_tx.id;
    update public.payment_orders set status = 'failed', failure_reason = 'PAYMENT_AMOUNT_MISMATCH'
    where id = v_order.id returning * into v_order;
    perform public.payment_log(v_order.id, 'provider:' || p_provider, 'amount_mismatch', 'pending', 'failed',
                               jsonb_build_object('expected', v_order.amount, 'got', p_amount, 'currency', p_currency));
    if v_order.property_id is not null then
      update public.properties set publication_status = 'payment_failed' where id = v_order.property_id;
    end if;
    return v_order;
  end if;

  update public.payment_transactions set status = 'paid', provider_payload = coalesce(p_payload, '{}')
  where id = v_tx.id;
  perform public.payment_log(v_order.id, 'provider:' || p_provider, 'paid', v_order.status, 'paid',
                             jsonb_build_object('provider_payment_id', p_provider_payment_id));
  update public.payment_orders set status = 'paid', paid_at = now(), failure_reason = null
  where id = v_order.id returning * into v_order;

  if v_order.service_type = 'PROPERTY_PUBLISHING' then
    -- payment done ≠ approved: it goes to moderation
    update public.properties set publication_status = 'pending_approval' where id = v_order.property_id;
  end if;
  return v_order;
end;
$$;

create or replace function public.payment_mark_failed(p_order uuid, p_status public.payment_status, p_reason text)
returns public.payment_orders
language plpgsql security definer set search_path = ''
as $$
declare
  v_order public.payment_orders;
begin
  if p_status not in ('failed', 'cancelled', 'expired') then
    raise exception 'VALIDATION_FAILED' using errcode = '22023';
  end if;
  select * into v_order from public.payment_orders where id = p_order for update;
  if not found then
    raise exception 'NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_order.status not in ('created', 'pending', 'processing') then
    return v_order;                                   -- never downgrade a paid / closed order
  end if;
  perform public.payment_log(p_order, 'system', 'closed', v_order.status, p_status, jsonb_build_object('reason', p_reason));
  update public.payment_orders set status = p_status, failure_reason = p_reason
  where id = p_order returning * into v_order;
  update public.payment_transactions set status = p_status where order_id = p_order and status = 'pending';
  if v_order.property_id is not null then
    update public.properties set publication_status = 'payment_failed'
    where id = v_order.property_id and publication_status = 'payment_processing';
  end if;
  return v_order;
end;
$$;

-- Only the backend may run these.
do $$
declare f text;
begin
  foreach f in array array[
    'public.payment_new_reference()',
    'public.payment_log(uuid, text, text, public.payment_status, public.payment_status, jsonb)',
    'public.property_submit(uuid, uuid)',
    'public.payment_create_order(uuid, public.service_type, uuid, uuid, public.payment_provider, text)',
    'public.payment_attach_transaction(uuid, text, jsonb, timestamptz)',
    'public.payment_mark_paid(public.payment_provider, text, bigint, text, jsonb)',
    'public.payment_mark_failed(uuid, public.payment_status, text)'] loop
    execute format('revoke all on function %s from public, anon, authenticated', f);
    execute format('grant execute on function %s to service_role', f);
  end loop;
end $$;
revoke all on function public.property_fee_required(uuid) from public, anon;
grant execute on function public.property_fee_required(uuid) to authenticated, service_role;

-- RLS ----------------------------------------------------------------------
alter table public.payment_settings        enable row level security;
alter table public.payment_orders          enable row level security;
alter table public.payment_transactions    enable row level security;
alter table public.payment_provider_events enable row level security;
alter table public.payment_refunds         enable row level security;
alter table public.payment_audit_logs      enable row level security;

create policy payment_settings_read on public.payment_settings
  for select to anon, authenticated using (true);           -- the app shows the price
create policy payment_orders_read on public.payment_orders
  for select to authenticated using (user_id = auth.uid() or public.has_role('finance_admin'));
create policy payment_transactions_read on public.payment_transactions
  for select to authenticated
  using (public.has_role('finance_admin')
         or exists (select 1 from public.payment_orders o where o.id = order_id and o.user_id = auth.uid()));
create policy payment_refunds_read on public.payment_refunds
  for select to authenticated
  using (public.has_role('finance_admin')
         or exists (select 1 from public.payment_orders o where o.id = order_id and o.user_id = auth.uid()));
create policy payment_events_read on public.payment_provider_events
  for select to authenticated using (public.has_role('finance_admin'));
create policy payment_audit_read on public.payment_audit_logs
  for select to authenticated using (public.has_role('finance_admin'));

-- Read-only for clients. No insert/update/delete grants at all.
grant select (service_type, price_amount, currency, is_enabled, applies_to_transaction_types)
  on public.payment_settings to anon, authenticated;
grant select on public.payment_orders, public.payment_transactions, public.payment_refunds,
                public.payment_provider_events, public.payment_audit_logs to authenticated;
-- Never expose raw provider payloads to the client.
revoke select on public.payment_transactions from authenticated;
grant select (id, order_id, provider, provider_payment_id, amount, currency, status, valid_until, created_at)
  on public.payment_transactions to authenticated;
