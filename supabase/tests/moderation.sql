-- Moderation + maintenance. LOCAL only; rolled back. One JSON cell.
begin;

insert into auth.users (id, phone, phone_confirmed_at, aud, role) values
  ('00000000-0000-0000-0000-00000000000a', '9647500000001', now(), 'authenticated', 'authenticated'),  -- owner
  ('00000000-0000-0000-0000-00000000000d', '9647500000009', now(), 'authenticated', 'authenticated');  -- moderator
insert into public.user_roles (user_id, role) values ('00000000-0000-0000-0000-00000000000d', 'moderator');

create temp table results (test text, ok boolean);
grant all on results to service_role;

insert into public.properties (id, owner_id, category_id, transaction_type, title, price_amount,
                               governorate_id, district_id, publication_status)
select v.id::uuid, '00000000-0000-0000-0000-00000000000a', c.id, 'rent', v.title, 500000, g.id, d.id,
       'pending_approval'
from (values ('80000000-0000-0000-0000-000000000001', 'Shop for rent one'),
             ('80000000-0000-0000-0000-000000000002', 'Shop for rent two')) v(id, title),
     public.property_categories c, public.governorates g
join public.districts d on d.governorate_id = g.id and d.name_en = 'Kirkuk'
where c.slug = 'shop' and g.code = 'KRK';

set local role service_role;

do $$ begin
  begin
    perform public.property_moderate('00000000-0000-0000-0000-00000000000a', '80000000-0000-0000-0000-000000000001', 'approve');
    insert into results values ('owner cannot approve own listing', false);
  exception when insufficient_privilege then insert into results values ('owner cannot approve own listing', true);
  end;
  begin
    perform public.property_moderate('00000000-0000-0000-0000-00000000000d', '80000000-0000-0000-0000-000000000002', 'reject', '');
    insert into results values ('reject needs a reason', false);
  exception when invalid_parameter_value then insert into results values ('reject needs a reason', true);
  end;
end $$;

insert into results select 'moderator approves → published with expiry',
  (select publication_status = 'published' and expires_at > now() + interval '89 days'
   from public.property_moderate('00000000-0000-0000-0000-00000000000d', '80000000-0000-0000-0000-000000000001', 'approve'));
insert into results select 'moderator rejects with reason',
  (select publication_status = 'rejected' and rejection_reason = 'Photos do not match'
   from public.property_moderate('00000000-0000-0000-0000-00000000000d', '80000000-0000-0000-0000-000000000002', 'reject', 'Photos do not match'));
do $$ begin
  begin
    perform public.property_moderate('00000000-0000-0000-0000-00000000000d', '80000000-0000-0000-0000-000000000002', 'approve');
    insert into results values ('cannot approve a rejected listing directly', false);
  exception when raise_exception then insert into results values ('cannot approve a rejected listing directly', true);
  end;
end $$;
insert into results select 'owner notified twice', (select count(*) = 2 from public.notifications
  where user_id = '00000000-0000-0000-0000-00000000000a' and type in ('property_approved', 'property_rejected'));
insert into results select 'admin actions audited', (select count(*) = 2 from public.admin_audit_logs);

-- expiry
update public.properties set expires_at = now() - interval '1 day' where id = '80000000-0000-0000-0000-000000000001';
-- separate statements: a statement does not see changes made by a function it calls
insert into results select 'maintenance reports 1 expired listing',
  (select (public.run_daily_maintenance()->>'expired_listings')::int = 1);
insert into results select 'listing is now expired',
  (select publication_status = 'expired' from public.properties where id = '80000000-0000-0000-0000-000000000001');

reset role;
select json_build_object(
  'passed', count(*) filter (where ok),
  'total',  count(*),
  'failed', coalesce(string_agg(test, ', ') filter (where not ok), 'none')
) as result
from results;

rollback;
