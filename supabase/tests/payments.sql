-- Payment engine checks. LOCAL only; everything is rolled back. Returns one JSON cell.
begin;

insert into auth.users (id, phone, phone_confirmed_at, aud, role) values
  ('00000000-0000-0000-0000-00000000000a', '9647500000001', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000000b', '9647500000002', now(), 'authenticated', 'authenticated');

create temp table results (test text, ok boolean);
grant all on results to authenticated, service_role;

-- A sale draft and a rent draft owned by A.
insert into public.properties (id, owner_id, category_id, transaction_type, title, price_amount, governorate_id, district_id)
select v.id::uuid, '00000000-0000-0000-0000-00000000000a', c.id, v.tt::public.transaction_type, v.title, 100000000, g.id, d.id
from (values ('30000000-0000-0000-0000-000000000001', 'sale', 'House for sale test'),
             ('30000000-0000-0000-0000-000000000002', 'rent', 'House for rent test')) v(id, tt, title),
     public.property_categories c, public.governorates g
join public.districts d on d.governorate_id = g.id and d.name_en = 'Sulaymaniyah'
where c.slug = 'house' and g.code = 'SUL';

-- ===== a normal user cannot touch the engine =====
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}';
do $$ begin
  begin
    perform public.payment_create_order('00000000-0000-0000-0000-00000000000a', 'PROPERTY_PUBLISHING',
      '30000000-0000-0000-0000-000000000001', null, 'FIB', 'user-attempt-001');
    insert into results values ('user cannot create orders directly', false);
  exception when insufficient_privilege then insert into results values ('user cannot create orders directly', true);
  end;
end $$;
insert into results select 'user sees price 30000', (select price_amount = 30000 from public.payment_settings where service_type = 'PROPERTY_PUBLISHING');

-- ===== backend (service_role) =====
reset role;
set local role service_role;

-- rent: no fee → straight to moderation
insert into results select 'rent submit skips payment',
  public.property_submit('00000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-000000000002') = 'pending_approval';
do $$ begin
  begin
    perform public.payment_create_order('00000000-0000-0000-0000-00000000000a', 'PROPERTY_PUBLISHING',
      '30000000-0000-0000-0000-000000000002', null, 'FIB', 'rent-order-0001');
    insert into results values ('rent cannot be charged', false);
  exception when raise_exception then insert into results values ('rent cannot be charged', sqlerrm = 'PAYMENT_NOT_REQUIRED');
  end;
end $$;

-- sale: fee required
insert into results select 'sale submit needs payment',
  public.property_submit('00000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-000000000001') = 'pending_payment';

-- B cannot pay for / create an order on A's property
do $$ begin
  begin
    perform public.payment_create_order('00000000-0000-0000-0000-00000000000b', 'PROPERTY_PUBLISHING',
      '30000000-0000-0000-0000-000000000001', null, 'FIB', 'b-steals-0001');
    insert into results values ('other user cannot order for my property', false);
  exception when no_data_found then insert into results values ('other user cannot order for my property', true);
  end;
end $$;

create temp table o (id uuid, ref text);
grant all on o to service_role;
insert into o select id, internal_reference from public.payment_create_order('00000000-0000-0000-0000-00000000000a',
  'PROPERTY_PUBLISHING', '30000000-0000-0000-0000-000000000001', null, 'FIB', 'checkout-key-0001');

insert into results select 'order amount is server price 30000', (select amount = 30000 from public.payment_orders where id = (select id from o));
insert into results select 'same idempotency key → same order',
  (select id from public.payment_create_order('00000000-0000-0000-0000-00000000000a', 'PROPERTY_PUBLISHING',
     '30000000-0000-0000-0000-000000000001', null, 'FIB', 'checkout-key-0001')) = (select id from o);
insert into results select 'new key, same property → same live order',
  (select id from public.payment_create_order('00000000-0000-0000-0000-00000000000a', 'PROPERTY_PUBLISHING',
     '30000000-0000-0000-0000-000000000001', null, 'FIB', 'checkout-key-0002')) = (select id from o);
insert into results select 'reference format REI-YYMMDD-XXXXXXXX', (select ref ~ '^REI-[0-9]{6}-[0-9A-F]{8}$' from o);

select public.payment_attach_transaction((select id from o), 'FIB-PAY-123', '{"readableCode":"1234"}', now() + interval '15 minutes');

-- wrong amount → failed, property back to payment_failed
insert into results select 'wrong amount is rejected',
  (select status = 'failed' from public.payment_mark_paid('FIB', 'FIB-PAY-123', 3000, 'IQD', '{}'));
insert into results select 'property marked payment_failed',
  (select publication_status = 'payment_failed' from public.properties where id = '30000000-0000-0000-0000-000000000001');

-- retry with a new order, correct amount
delete from o;
insert into o select id, internal_reference from public.payment_create_order('00000000-0000-0000-0000-00000000000a',
  'PROPERTY_PUBLISHING', '30000000-0000-0000-0000-000000000001', null, 'QI_CARD', 'checkout-key-0003');
select public.payment_attach_transaction((select id from o), 'QI-PAY-456', '{}', null);
insert into results select 'correct payment → paid',
  (select status = 'paid' from public.payment_mark_paid('QI_CARD', 'QI-PAY-456', 30000, 'iqd', '{}'));
insert into results select 'paid ≠ published: goes to moderation',
  (select publication_status = 'pending_approval' from public.properties where id = '30000000-0000-0000-0000-000000000001');
insert into results select 'duplicate webhook is idempotent',
  (select status = 'paid' from public.payment_mark_paid('QI_CARD', 'QI-PAY-456', 30000, 'IQD', '{}'))
  and (select count(*) = 1 from public.payment_audit_logs where order_id = (select id from o) and action = 'paid');
insert into results select 'paid order cannot be failed later',
  (select status = 'paid' from public.payment_mark_failed((select id from o), 'failed', 'late'));
do $$ begin
  begin
    perform public.payment_create_order('00000000-0000-0000-0000-00000000000a', 'PROPERTY_PUBLISHING',
      '30000000-0000-0000-0000-000000000001', null, 'FIB', 'checkout-key-0004');
    insert into results values ('cannot pay twice for one listing', false);
  exception when raise_exception then insert into results values ('cannot pay twice for one listing', true);
  end;
end $$;
do $$ begin
  begin
    update public.payment_audit_logs set action = 'tampered';
    insert into results values ('audit log is append-only', false);
  exception when insufficient_privilege then insert into results values ('audit log is append-only', true);
  end;
end $$;

-- ===== visibility =====
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}';
insert into results select 'owner sees own orders', (select count(*) = 2 from public.payment_orders);
do $$ begin
  begin
    update public.payment_orders set status = 'paid';
    insert into results values ('owner cannot change order status', false);
  exception when insufficient_privilege then insert into results values ('owner cannot change order status', true);
  end;
end $$;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}';
insert into results select 'other user sees no orders', (select count(*) = 0 from public.payment_orders);

reset role;
select json_build_object(
  'passed', count(*) filter (where ok),
  'total',  count(*),
  'failed', coalesce(string_agg(test, ', ') filter (where not ok), 'none')
) as result
from results;

rollback;
