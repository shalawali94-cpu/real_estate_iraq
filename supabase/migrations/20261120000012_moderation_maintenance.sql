-- Moderation (approve / reject / suspend) and daily maintenance (expiry).

-- Is this user staff with one of the given roles? (super_admin always passes)
create or replace function public.user_has_any_role(p_user uuid, p_roles public.app_role[])
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.user_roles
                 where user_id = p_user and (role = any (p_roles) or role = 'super_admin'));
$$;

create or replace function public.property_moderate(
  p_admin uuid, p_property uuid, p_decision text, p_reason text default null)
returns public.properties
language plpgsql security definer set search_path = ''
as $$
declare
  v_prop   public.properties;
  v_days   integer;
  v_before jsonb;
begin
  if not public.user_has_any_role(p_admin, array['moderator', 'admin']::public.app_role[]) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;
  if p_decision not in ('approve', 'reject', 'suspend', 'unsuspend') then
    raise exception 'VALIDATION_FAILED: decision' using errcode = '22023';
  end if;
  if p_decision in ('reject', 'suspend') and coalesce(trim(p_reason), '') = '' then
    raise exception 'VALIDATION_FAILED: reason required' using errcode = '22023';
  end if;

  select * into v_prop from public.properties where id = p_property for update;
  if not found or v_prop.deleted_at is not null then
    raise exception 'NOT_FOUND' using errcode = 'P0002';
  end if;
  v_before := jsonb_build_object('publication_status', v_prop.publication_status);

  select coalesce((value #>> '{}')::integer, 90) into v_days
  from public.application_settings where key = 'listing_expiry_days';
  v_days := coalesce(v_days, 90);

  if p_decision = 'approve' then
    if v_prop.publication_status <> 'pending_approval' then
      raise exception 'PROPERTY_NOT_SUBMITTABLE' using errcode = 'P0001';
    end if;
    update public.properties
       set publication_status = 'published', rejection_reason = null,
           published_at = now(), expires_at = now() + make_interval(days => v_days)
     where id = p_property returning * into v_prop;
  elsif p_decision = 'reject' then
    if v_prop.publication_status <> 'pending_approval' then
      raise exception 'PROPERTY_NOT_SUBMITTABLE' using errcode = 'P0001';
    end if;
    update public.properties set publication_status = 'rejected', rejection_reason = left(p_reason, 500)
     where id = p_property returning * into v_prop;
  elsif p_decision = 'suspend' then
    if v_prop.publication_status <> 'published' then
      raise exception 'PROPERTY_NOT_SUBMITTABLE' using errcode = 'P0001';
    end if;
    update public.properties set publication_status = 'suspended', rejection_reason = left(p_reason, 500)
     where id = p_property returning * into v_prop;
  else -- unsuspend
    if v_prop.publication_status <> 'suspended' then
      raise exception 'PROPERTY_NOT_SUBMITTABLE' using errcode = 'P0001';
    end if;
    update public.properties set publication_status = 'published', rejection_reason = null
     where id = p_property returning * into v_prop;
  end if;

  insert into public.admin_audit_logs (admin_id, action, target_table, target_id, before, after)
  values (p_admin, 'property_' || p_decision, 'properties', p_property::text, v_before,
          jsonb_build_object('publication_status', v_prop.publication_status, 'reason', p_reason));

  insert into public.notifications (user_id, type, title_key, body_key, params, data)
  values (v_prop.owner_id,
          case p_decision when 'approve' then 'property_approved' when 'reject' then 'property_rejected'
                          when 'suspend' then 'property_suspended' else 'property_restored' end,
          'notif_property_' || p_decision || '_title', 'notif_property_' || p_decision || '_body',
          jsonb_build_object('title', v_prop.title, 'reason', coalesce(p_reason, '')),
          jsonb_build_object('property_id', v_prop.id));
  return v_prop;
end;
$$;

-- Daily maintenance. Returns a small JSON report.
create or replace function public.run_daily_maintenance()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_listings int;
  v_orders   int;
  v_order    record;
begin
  -- 1. Expire published listings past expires_at (owner can renew).
  with expired as (
    update public.properties set publication_status = 'expired'
     where publication_status = 'published' and expires_at is not null and expires_at < now()
    returning id, owner_id, title)
  insert into public.notifications (user_id, type, title_key, body_key, params, data)
  select owner_id, 'property_expired', 'notif_property_expired_title', 'notif_property_expired_body',
         jsonb_build_object('title', title), jsonb_build_object('property_id', id)
  from expired;
  get diagnostics v_listings = row_count;

  -- 2. Close unpaid orders whose payment window is over (the reconciler checks the
  --    provider first; this is the final cleanup for orders that never got a payment).
  v_orders := 0;
  for v_order in
    select id from public.payment_orders
    where status in ('created', 'pending') and expires_at < now() - interval '1 hour'
  loop
    perform public.payment_mark_failed(v_order.id, 'expired', 'ORDER_EXPIRED');
    v_orders := v_orders + 1;
  end loop;

  -- 3. Old finished background jobs.
  delete from public.jobs where status = 'done' and created_at < now() - interval '30 days';

  return jsonb_build_object('expired_listings', v_listings, 'expired_orders', v_orders, 'ran_at', now());
end;
$$;

do $$
declare f text;
begin
  foreach f in array array[
    'public.user_has_any_role(uuid, public.app_role[])',
    'public.property_moderate(uuid, uuid, text, text)',
    'public.run_daily_maintenance()'] loop
    execute format('revoke all on function %s from public, anon, authenticated', f);
    execute format('grant execute on function %s to service_role', f);
  end loop;
end $$;
