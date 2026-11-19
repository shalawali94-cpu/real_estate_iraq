-- AI Studio jobs (paid video orders), property videos, usage/cost, admin audit, settings, banners, job queue.

create type public.ai_job_kind   as enum ('video', 'image_enhance', 'virtual_staging', 'text');
create type public.ai_job_status as enum (
  'draft', 'pending_payment', 'payment_processing', 'payment_failed', 'payment_paid',
  'queued', 'processing', 'completed', 'failed', 'cancelled', 'refund_pending', 'refunded');

create table public.ai_jobs (
  id                     uuid primary key default gen_random_uuid(),
  user_id                uuid not null references auth.users (id) on delete cascade,
  property_id            uuid references public.properties (id) on delete cascade,
  kind                   public.ai_job_kind not null,
  status                 public.ai_job_status not null default 'draft',
  options                jsonb not null default '{}',
  input_image_ids        uuid[] not null default '{}',
  render_mode            text check (render_mode in ('ai', 'template')),   -- what was actually produced
  provider               text,
  progress               smallint not null default 0 check (progress between 0 and 100),
  attempts               smallint not null default 0,
  max_attempts           smallint not null default 3,
  free_regenerations     smallint not null default 0,
  error                  text,
  output_path            text,
  locked_at              timestamptz,
  started_at             timestamptz,
  completed_at           timestamptz,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  check (kind <> 'video' or (
    (options->>'duration')::int in (15, 30, 60)
    and options->>'aspect' in ('9:16', '16:9', '1:1')
    and cardinality(input_image_ids) between 3 and 20))
);
create index ai_jobs_user_idx  on public.ai_jobs (user_id, created_at desc);
create index ai_jobs_queue_idx on public.ai_jobs (created_at) where status = 'queued';
create trigger ai_jobs_updated_at before update on public.ai_jobs
  for each row execute function public.set_updated_at();

alter table public.payment_orders
  add constraint payment_orders_ai_job_fk foreign key (ai_job_id) references public.ai_jobs (id) on delete restrict;

create table public.ai_generations (
  id              uuid primary key default gen_random_uuid(),
  job_id          uuid not null references public.ai_jobs (id) on delete cascade,
  provider        text not null,
  model           text,
  input_ref       text,
  output_path     text,
  cost_usd_micros bigint not null default 0,
  latency_ms      integer,
  status          text not null check (status in ('succeeded', 'failed')),
  error           text,
  created_at      timestamptz not null default now()
);
create index ai_generations_job_idx on public.ai_generations (job_id);

create table public.ai_usage (
  user_id         uuid not null references auth.users (id) on delete cascade,
  feature         public.ai_job_kind not null,
  day             date not null default (now() at time zone 'Asia/Baghdad')::date,
  units           integer not null default 0,
  cost_usd_micros bigint not null default 0,
  primary key (user_id, feature, day)
);

create table public.ai_provider_config (
  provider                text not null,
  feature                 public.ai_job_kind not null,
  model                   text,
  is_enabled              boolean not null default false,
  priority                smallint not null default 0,
  daily_budget_usd_micros bigint,
  updated_at              timestamptz not null default now(),
  primary key (provider, feature)
);

-- Videos shown on a listing: user uploads, AI videos, template slideshows (always labeled).
create table public.property_videos (
  id           uuid primary key default gen_random_uuid(),
  property_id  uuid not null references public.properties (id) on delete cascade,
  owner_id     uuid not null references auth.users (id) on delete cascade,
  storage_path text not null unique,
  poster_path  text,
  duration_s   smallint,
  aspect       text check (aspect in ('9:16', '16:9', '1:1')),
  source       text not null check (source in ('user_upload', 'ai_generated', 'template_slideshow')),
  ai_job_id    uuid references public.ai_jobs (id) on delete set null,
  sort_order   smallint not null default 0,
  created_at   timestamptz not null default now()
);
create index property_videos_property_idx on public.property_videos (property_id, sort_order);

-- ===== AI video order lifecycle (backend / worker only) ======================

-- Create a draft video job after validating the photos belong to the user's property.
create or replace function public.ai_video_create(p_user uuid, p_property uuid, p_image_ids uuid[], p_options jsonb)
returns public.ai_jobs language plpgsql security definer set search_path = ''
as $$
declare
  v_job public.ai_jobs;
begin
  if not exists (select 1 from public.properties where id = p_property and owner_id = p_user and deleted_at is null) then
    raise exception 'NOT_FOUND' using errcode = 'P0002';
  end if;
  if (select count(*) from public.property_images
      where id = any (p_image_ids) and property_id = p_property and status <> 'rejected')
     <> cardinality(p_image_ids) then
    raise exception 'VALIDATION_FAILED: images' using errcode = '22023';
  end if;
  insert into public.ai_jobs (user_id, property_id, kind, status, options, input_image_ids)
  values (p_user, p_property, 'video', 'pending_payment', p_options, p_image_ids)
  returning * into v_job;
  return v_job;
end;
$$;

-- Worker: claim the next queued job (safe with many workers).
create or replace function public.ai_job_claim(p_kind public.ai_job_kind default 'video')
returns public.ai_jobs language plpgsql security definer set search_path = ''
as $$
declare
  v_job public.ai_jobs;
begin
  select * into v_job from public.ai_jobs
  where status = 'queued' and kind = p_kind
  order by created_at
  for update skip locked
  limit 1;
  if not found then
    return null;
  end if;
  update public.ai_jobs
     set status = 'processing', attempts = attempts + 1, locked_at = now(),
         started_at = coalesce(started_at, now()), progress = 0, error = null
   where id = v_job.id
  returning * into v_job;
  return v_job;
end;
$$;

create or replace function public.ai_job_progress(p_job uuid, p_progress smallint)
returns void language sql security definer set search_path = ''
as $$
  update public.ai_jobs set progress = greatest(least(p_progress, 99), 0)
  where id = p_job and status = 'processing';
$$;

create or replace function public.ai_job_complete(p_job uuid, p_output_path text, p_render_mode text,
  p_provider text, p_duration smallint)
returns public.ai_jobs language plpgsql security definer set search_path = ''
as $$
declare
  v_job public.ai_jobs;
begin
  update public.ai_jobs
     set status = 'completed', progress = 100, output_path = p_output_path, render_mode = p_render_mode,
         provider = p_provider, completed_at = now(), locked_at = null
   where id = p_job and status = 'processing'
  returning * into v_job;
  if not found then
    raise exception 'AI_JOB_NOT_PROCESSING' using errcode = 'P0001';
  end if;
  insert into public.notifications (user_id, type, title_key, body_key, data)
  values (v_job.user_id, 'ai_video_completed', 'notif_ai_video_done_title', 'notif_ai_video_done_body',
          jsonb_build_object('ai_job_id', v_job.id, 'property_id', v_job.property_id, 'render_mode', p_render_mode));
  return v_job;
end;
$$;

-- Worker failure: retry until max_attempts, then 'failed' (user may regenerate free once,
-- or the backend requests a refund — payment is never silently kept).
create or replace function public.ai_job_fail(p_job uuid, p_error text)
returns public.ai_jobs language plpgsql security definer set search_path = ''
as $$
declare
  v_job public.ai_jobs;
begin
  select * into v_job from public.ai_jobs where id = p_job for update;
  if not found or v_job.status <> 'processing' then
    raise exception 'AI_JOB_NOT_PROCESSING' using errcode = 'P0001';
  end if;
  if v_job.attempts < v_job.max_attempts then
    update public.ai_jobs set status = 'queued', error = left(p_error, 1000), locked_at = null
    where id = p_job returning * into v_job;
  else
    update public.ai_jobs set status = 'failed', error = left(p_error, 1000), locked_at = null
    where id = p_job returning * into v_job;
    insert into public.notifications (user_id, type, title_key, body_key, data)
    values (v_job.user_id, 'ai_video_failed', 'notif_ai_video_failed_title', 'notif_ai_video_failed_body',
            jsonb_build_object('ai_job_id', v_job.id));
  end if;
  return v_job;
end;
$$;

-- Free regeneration of a paid job that was not delivered (one time).
create or replace function public.ai_job_regenerate(p_user uuid, p_job uuid)
returns public.ai_jobs language plpgsql security definer set search_path = ''
as $$
declare
  v_job public.ai_jobs;
begin
  update public.ai_jobs
     set status = 'queued', attempts = 0, free_regenerations = free_regenerations + 1, error = null, progress = 0
   where id = p_job and user_id = p_user and status = 'failed' and free_regenerations < 1
     and exists (select 1 from public.payment_orders o where o.ai_job_id = p_job and o.status = 'paid')
  returning * into v_job;
  if not found then
    raise exception 'AI_JOB_NOT_REGENERABLE' using errcode = 'P0001';
  end if;
  return v_job;
end;
$$;

-- Ask for a refund on a paid order whose service failed.
create or replace function public.payment_request_refund(p_order uuid, p_reason text, p_actor uuid)
returns public.payment_refunds language plpgsql security definer set search_path = ''
as $$
declare
  v_order  public.payment_orders;
  v_refund public.payment_refunds;
begin
  select * into v_order from public.payment_orders where id = p_order for update;
  if not found or v_order.status <> 'paid' or v_order.refund_status <> 'none' then
    raise exception 'REFUND_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  insert into public.payment_refunds (order_id, transaction_id, amount, reason, requested_by)
  values (p_order,
          (select id from public.payment_transactions where order_id = p_order and status = 'paid' limit 1),
          v_order.amount, p_reason, p_actor)
  returning * into v_refund;
  update public.payment_orders set refund_status = 'requested' where id = p_order;
  if v_order.ai_job_id is not null then
    update public.ai_jobs set status = 'refund_pending' where id = v_order.ai_job_id;
  end if;
  perform public.payment_log(p_order, coalesce('user:' || p_actor::text, 'system'), 'refund_requested',
                             'paid', 'paid', jsonb_build_object('reason', p_reason, 'amount', v_order.amount));
  return v_refund;
end;
$$;

-- ===== Payment engine: add the AI video branch ===============================
create or replace function public.payment_create_order(
  p_user uuid, p_service public.service_type, p_property uuid, p_ai_job uuid,
  p_provider public.payment_provider, p_idempotency_key text)
returns public.payment_orders
language plpgsql security definer set search_path = ''
as $$
declare
  v_order    public.payment_orders;
  v_prop     public.properties;
  v_job      public.ai_jobs;
  v_settings public.payment_settings;
begin
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
    select * into v_order from public.payment_orders
    where property_id = p_property and service_type = 'PROPERTY_PUBLISHING'
      and status in ('created', 'pending', 'processing', 'paid');
  else
    select * into v_job from public.ai_jobs where id = p_ai_job for update;
    if not found or v_job.user_id <> p_user or v_job.kind <> 'video' then
      raise exception 'NOT_FOUND' using errcode = 'P0002';
    end if;
    if v_job.status not in ('pending_payment', 'payment_failed', 'payment_processing') then
      raise exception 'AI_JOB_NOT_PAYABLE' using errcode = 'P0001';
    end if;
    select * into v_order from public.payment_orders
    where ai_job_id = p_ai_job and service_type = 'AI_VIDEO_GENERATION'
      and status in ('created', 'pending', 'processing', 'paid');
  end if;

  if v_order.id is not null then
    if v_order.status = 'paid' then
      raise exception 'PAYMENT_ALREADY_PAID' using errcode = 'P0001';
    end if;
    if v_order.expires_at > now() and v_order.provider = p_provider then
      return v_order;
    end if;
    update public.payment_orders set status = 'cancelled', failure_reason = 'SUPERSEDED' where id = v_order.id;
    perform public.payment_log(v_order.id, 'system', 'superseded', v_order.status, 'cancelled');
  end if;

  insert into public.payment_orders (user_id, service_type, property_id, ai_job_id, provider,
                                     amount, currency, idempotency_key, internal_reference)
  values (p_user, p_service,
          case when p_service = 'PROPERTY_PUBLISHING' then p_property end,
          case when p_service = 'AI_VIDEO_GENERATION' then p_ai_job end,
          p_provider, v_settings.price_amount, v_settings.currency, p_idempotency_key,
          public.payment_new_reference())
  returning * into v_order;

  if p_service = 'PROPERTY_PUBLISHING' then
    update public.properties set publication_status = 'payment_processing' where id = p_property;
  else
    update public.ai_jobs set status = 'payment_processing' where id = p_ai_job;
  end if;
  perform public.payment_log(v_order.id, 'user:' || p_user, 'order_created', null, 'created',
                             jsonb_build_object('amount', v_order.amount, 'provider', p_provider));
  return v_order;
end;
$$;

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
    return v_order;
  end if;

  if p_amount <> v_order.amount or upper(p_currency) <> v_order.currency then
    update public.payment_transactions set status = 'failed', provider_payload = coalesce(p_payload, '{}') where id = v_tx.id;
    update public.payment_orders set status = 'failed', failure_reason = 'PAYMENT_AMOUNT_MISMATCH'
    where id = v_order.id returning * into v_order;
    perform public.payment_log(v_order.id, 'provider:' || p_provider, 'amount_mismatch', 'pending', 'failed',
                               jsonb_build_object('expected', v_order.amount, 'got', p_amount, 'currency', p_currency));
    if v_order.property_id is not null then
      update public.properties set publication_status = 'payment_failed' where id = v_order.property_id;
    end if;
    if v_order.ai_job_id is not null then
      update public.ai_jobs set status = 'payment_failed' where id = v_order.ai_job_id;
    end if;
    return v_order;
  end if;

  update public.payment_transactions set status = 'paid', provider_payload = coalesce(p_payload, '{}') where id = v_tx.id;
  perform public.payment_log(v_order.id, 'provider:' || p_provider, 'paid', v_order.status, 'paid',
                             jsonb_build_object('provider_payment_id', p_provider_payment_id));
  update public.payment_orders set status = 'paid', paid_at = now(), failure_reason = null
  where id = v_order.id returning * into v_order;

  if v_order.service_type = 'PROPERTY_PUBLISHING' then
    update public.properties set publication_status = 'pending_approval' where id = v_order.property_id;
  else
    -- only now may the generation job run
    update public.ai_jobs set status = 'queued' where id = v_order.ai_job_id;
  end if;

  insert into public.notifications (user_id, type, title_key, body_key, params, data)
  values (v_order.user_id, 'payment_success', 'notif_payment_success_title', 'notif_payment_success_body',
          jsonb_build_object('amount', v_order.amount, 'currency', v_order.currency, 'reference', v_order.internal_reference),
          jsonb_build_object('order_id', v_order.id));
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
    return v_order;
  end if;
  perform public.payment_log(p_order, 'system', 'closed', v_order.status, p_status, jsonb_build_object('reason', p_reason));
  update public.payment_orders set status = p_status, failure_reason = p_reason where id = p_order returning * into v_order;
  update public.payment_transactions set status = p_status where order_id = p_order and status = 'pending';
  if v_order.property_id is not null then
    update public.properties set publication_status = 'payment_failed'
    where id = v_order.property_id and publication_status = 'payment_processing';
  end if;
  if v_order.ai_job_id is not null then
    update public.ai_jobs set status = 'payment_failed'
    where id = v_order.ai_job_id and status = 'payment_processing';
  end if;
  insert into public.notifications (user_id, type, title_key, body_key, params, data)
  values (v_order.user_id, 'payment_failed', 'notif_payment_failed_title', 'notif_payment_failed_body',
          jsonb_build_object('reference', v_order.internal_reference), jsonb_build_object('order_id', v_order.id));
  return v_order;
end;
$$;

-- ===== Admin & platform =======================================================
create table public.admin_audit_logs (
  id           bigint generated always as identity primary key,
  admin_id     uuid references auth.users (id),
  action       text not null,
  target_table text,
  target_id    text,
  before       jsonb,
  after        jsonb,
  ip           inet,
  created_at   timestamptz not null default now()
);
create index admin_audit_logs_created_idx on public.admin_audit_logs (created_at desc);
create trigger admin_audit_logs_append_only before update or delete on public.admin_audit_logs
  for each row execute function public.forbid_mutation();

create table public.application_settings (
  key        text primary key,
  value      jsonb not null,
  is_public  boolean not null default false,   -- readable by the app
  updated_by uuid references auth.users (id),
  updated_at timestamptz not null default now()
);
insert into public.application_settings (key, value, is_public) values
  ('listing_expiry_days',          '90',   true),
  ('max_images_per_property',      '20',   true),
  ('max_video_mb',                 '200',  true),
  ('ai_enhance_daily_free',        '10',   true),
  ('ai_video_free_regenerations',  '1',    true),
  ('ai_video_max_attempts',        '3',    false),
  ('min_app_version',              '"1.0.0"', true),
  ('support_whatsapp',             'null', true);

create table public.banners (
  id         uuid primary key default gen_random_uuid(),
  image_path text not null,
  link       text,
  locale     text check (locale in ('ckb', 'ar', 'en')),
  sort_order smallint not null default 0,
  starts_at  timestamptz not null default now(),
  ends_at    timestamptz,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

-- Generic background queue (push sends, search alerts, expiry, reconciliation).
create table public.jobs (
  id         bigint generated always as identity primary key,
  type       text not null,
  payload    jsonb not null default '{}',
  run_at     timestamptz not null default now(),
  attempts   smallint not null default 0,
  status     text not null default 'pending' check (status in ('pending', 'running', 'done', 'failed')),
  last_error text,
  locked_at  timestamptz,
  created_at timestamptz not null default now()
);
create index jobs_due_idx on public.jobs (run_at) where status = 'pending';

-- ===== RLS & grants ===========================================================
alter table public.ai_jobs              enable row level security;
alter table public.ai_generations       enable row level security;
alter table public.ai_usage             enable row level security;
alter table public.ai_provider_config   enable row level security;
alter table public.property_videos      enable row level security;
alter table public.admin_audit_logs     enable row level security;
alter table public.application_settings enable row level security;
alter table public.banners              enable row level security;
alter table public.jobs                 enable row level security;

create policy ai_jobs_own on public.ai_jobs
  for select to authenticated using (user_id = auth.uid() or public.is_staff());
create policy ai_usage_own on public.ai_usage
  for select to authenticated using (user_id = auth.uid());
create policy property_videos_read on public.property_videos
  for select to anon, authenticated
  using (public.property_is_public(property_id) or owner_id = auth.uid() or public.is_staff());
create policy admin_audit_read on public.admin_audit_logs
  for select to authenticated using (public.has_role('admin'));
create policy settings_public_read on public.application_settings
  for select to anon, authenticated using (is_public or public.is_staff());
create policy banners_read on public.banners
  for select to anon, authenticated
  using (is_active and starts_at <= now() and (ends_at is null or ends_at > now()));
-- ai_generations, ai_provider_config, jobs: backend only (no client policies).

grant select on public.ai_jobs to authenticated;   -- whole row: Realtime progress needs it
grant select on public.ai_usage to authenticated;
grant select on public.property_videos to anon, authenticated;
grant select on public.admin_audit_logs to authenticated;
grant select on public.application_settings, public.banners to anon, authenticated;
grant all on public.ai_jobs, public.ai_generations, public.ai_usage, public.ai_provider_config,
             public.property_videos, public.admin_audit_logs, public.application_settings,
             public.banners, public.jobs to service_role;

do $$
declare f text;
begin
  foreach f in array array[
    'public.ai_video_create(uuid, uuid, uuid[], jsonb)',
    'public.ai_job_claim(public.ai_job_kind)',
    'public.ai_job_progress(uuid, smallint)',
    'public.ai_job_complete(uuid, text, text, text, smallint)',
    'public.ai_job_fail(uuid, text)',
    'public.ai_job_regenerate(uuid, uuid)',
    'public.payment_request_refund(uuid, text, uuid)',
    'public.payment_create_order(uuid, public.service_type, uuid, uuid, public.payment_provider, text)',
    'public.payment_mark_paid(public.payment_provider, text, bigint, text, jsonb)',
    'public.payment_mark_failed(uuid, public.payment_status, text)'] loop
    execute format('revoke all on function %s from public, anon, authenticated', f);
    execute format('grant execute on function %s to service_role', f);
  end loop;
end $$;

-- Live progress for the user's own jobs.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.ai_jobs;
  end if;
end $$;
