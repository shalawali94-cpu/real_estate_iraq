-- Search, views, saved searches, reports, verification. LOCAL only; rolled back. One JSON cell.
begin;

insert into auth.users (id, phone, phone_confirmed_at, aud, role) values
  ('00000000-0000-0000-0000-00000000000a', '9647500000001', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000000b', '9647500000002', now(), 'authenticated', 'authenticated');
update public.profiles set identity_verified = true where id = '00000000-0000-0000-0000-00000000000b';

create temp table results (test text, ok boolean);
grant all on results to authenticated, anon;

-- Listings: two published (Erbil by B verified, Sulaymaniyah by A), one draft.
insert into public.properties (id, owner_id, category_id, transaction_type, title, description, price_amount,
                               governorate_id, district_id, location, area_sqm, bedrooms,
                               publication_status, published_at)
select v.id::uuid, v.owner::uuid, c.id, 'sale', v.title, v.descr, v.price, g.id, d.id,
       extensions.st_setsrid(extensions.st_makepoint(v.lng, v.lat), 4326)::extensions.geography,
       v.area, v.beds, v.status::public.publication_status,
       case when v.status = 'published' then now() end
from (values
  ('60000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'ERB', 'Erbil',
   'Modern house in Ankawa', 'garden and garage', 200000000::bigint, 44.0090::float8, 36.2370::float8, 300, 4::smallint, 'published'),
  ('60000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000a', 'SUL', 'Sulaymaniyah',
   'Family house Sarchnar', 'close to park', 120000000, 45.4000, 35.5600, 200, 3, 'published'),
  ('60000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-00000000000a', 'SUL', 'Sulaymaniyah',
   'Draft house hidden', null, 90000000, 45.4300, 35.5500, 150, 2, 'draft')
) v(id, owner, gov, dist, title, descr, price, lng, lat, area, beds, status)
join public.governorates g on g.code = v.gov
join public.districts d on d.governorate_id = g.id and d.name_en = v.dist
cross join public.property_categories c where c.slug = 'house';

-- ===== anonymous search =====
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
insert into results select 'anon search: only published', (select count(*) = 2 from public.search_properties('{}'));
insert into results select 'filter governorate',
  (select count(*) = 1 from public.search_properties(jsonb_build_object('governorate_id',
     (select id from public.governorates where code = 'ERB'))));
insert into results select 'filter max_price', (select count(*) = 1 from public.search_properties('{"max_price":150000000}'));
insert into results select 'sort price_asc', (select title from public.search_properties('{"sort":"price_asc"}') limit 1) = 'Family house Sarchnar';
insert into results select 'near Ankawa 5km', (select count(*) = 1 from public.search_properties('{"near":{"lat":36.24,"lng":44.01,"radius_m":5000}}'));
insert into results select 'map bbox Sulaymaniyah', (select count(*) = 1 from public.search_properties('{"bbox":{"west":45.3,"south":35.5,"east":45.5,"north":35.6}}'));
insert into results select 'keyword search', (select count(*) = 1 from public.search_properties('{"q":"garden"}'));
insert into results select 'verified owner filter',
  (select bool_and(owner_identity_verified) and count(*) = 1 from public.search_properties('{"verified_owner":true}'));
insert into results select 'limit capped at 50', (select count(*) = 2 from public.search_properties('{}', 9999, 0));

-- ===== user A =====
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}';
select public.record_property_view('60000000-0000-0000-0000-000000000001');
select public.record_property_view('60000000-0000-0000-0000-000000000001');
select public.record_property_view('60000000-0000-0000-0000-000000000002');   -- own listing
insert into results select 'recently viewed recorded', (select count(*) = 2 from public.recently_viewed);

do $$ begin
  for i in 1..20 loop
    insert into public.saved_searches (user_id, name, filters) values ('00000000-0000-0000-0000-00000000000a', 'S' || i, '{}');
  end loop;
  begin
    insert into public.saved_searches (user_id, name, filters) values ('00000000-0000-0000-0000-00000000000a', 'S21', '{}');
    insert into results values ('max 20 saved searches', false);
  exception when invalid_parameter_value then insert into results values ('max 20 saved searches', true);
  end;
end $$;

insert into public.property_reports (property_id, reporter_id, reason) values ('60000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'wrong_price');
insert into results select 'can report public listing', (select count(*) = 1 from public.property_reports);
do $$ begin
  begin
    insert into public.property_reports (property_id, reporter_id, reason) values ('60000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', 'fake');
    insert into results values ('one report per user per listing', false);
  exception when unique_violation then insert into results values ('one report per user per listing', true);
  end;
end $$;

do $$ begin
  begin
    insert into public.verification_requests (user_id, kind, documents)
    values ('00000000-0000-0000-0000-00000000000a', 'identity', array['00000000-0000-0000-0000-00000000000b/id.jpg']);
    insert into results values ('cannot use another user''s documents', false);
  exception when insufficient_privilege then insert into results values ('cannot use another user''s documents', true);
  end;
end $$;
insert into public.verification_requests (user_id, kind, documents)
values ('00000000-0000-0000-0000-00000000000a', 'identity', array['00000000-0000-0000-0000-00000000000a/id-front.jpg']);
insert into results select 'identity request submitted', (select count(*) = 1 from public.verification_requests where state = 'pending');
do $$ begin
  begin
    update public.verification_requests set state = 'approved';
    insert into results values ('cannot self-approve verification', false);
  exception when insufficient_privilege then insert into results values ('cannot self-approve verification', true);
  end;
end $$;

-- ===== user B sees nothing of A's private data =====
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}';
insert into results select 'others cannot see my saved searches / requests',
  (select count(*) = 0 from public.saved_searches) and (select count(*) = 0 from public.verification_requests);

reset role;
insert into results select 'view counted once, owner view not counted',
  (select views_count = 1 from public.properties where id = '60000000-0000-0000-0000-000000000001')
  and (select views_count = 0 from public.properties where id = '60000000-0000-0000-0000-000000000002');

select json_build_object(
  'passed', count(*) filter (where ok),
  'total',  count(*),
  'failed', coalesce(string_agg(test, ', ') filter (where not ok), 'none')
) as result
from results;

rollback;
