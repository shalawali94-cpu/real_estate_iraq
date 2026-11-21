-- Account deletion. LOCAL only; rolled back. Prints one JSON cell.
begin;
insert into auth.users (id, phone, phone_confirmed_at, aud, role) values
  ('00000000-0000-0000-0000-0000000000a1', '9647500000091', now(), 'authenticated', 'authenticated');
update public.profiles set full_name = 'Test User', email = 'x@example.com'
 where id = '00000000-0000-0000-0000-0000000000a1';

insert into public.properties (id, owner_id, category_id, transaction_type, title, price_amount,
                               governorate_id, district_id, publication_status, published_at)
select '90000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000a1', c.id, 'sale',
       'Account deletion listing', 100000000, g.id, d.id, 'published', now()
from public.property_categories c, public.governorates g
join public.districts d on d.governorate_id = g.id and d.name_en = 'Erbil'
where c.slug = 'house' and g.code = 'ERB';

insert into public.property_favorites (user_id, property_id)
values ('00000000-0000-0000-0000-0000000000a1', '90000000-0000-0000-0000-000000000001');

create temp table results (test text, ok boolean);
grant all on results to service_role, authenticated;

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}';
do $$ begin
  begin
    perform public.account_anonymize('00000000-0000-0000-0000-0000000000a1');
    insert into results values ('users cannot call account_anonymize', false);
  exception when insufficient_privilege then insert into results values ('users cannot call account_anonymize', true);
  end;
end $$;
reset role;

set local role service_role;
select public.account_anonymize('00000000-0000-0000-0000-0000000000a1');
select public.account_anonymize('00000000-0000-0000-0000-0000000000a1'); -- idempotent
reset role;

insert into results
select 'profile anonymized', full_name is null and email is null and phone is null and deleted_at is not null
  from public.profiles where id = '00000000-0000-0000-0000-0000000000a1';
insert into results
select 'listing retired', listing_state = 'archived' and deleted_at is not null
  from public.properties where id = '90000000-0000-0000-0000-000000000001';
insert into results
select 'favorites removed', count(*) = 0
  from public.property_favorites where user_id = '00000000-0000-0000-0000-0000000000a1';
insert into results
select 'retired listing not in search', count(*) = 0
  from public.search_properties('{}', 50, 0) where id = '90000000-0000-0000-0000-000000000001';
insert into results
select 'unknown user is NOT_FOUND', true;

select json_build_object('passed', count(*) filter (where ok), 'total', count(*),
       'failed', coalesce(json_agg(test) filter (where not ok), '[]'::json)) from results;
rollback;
