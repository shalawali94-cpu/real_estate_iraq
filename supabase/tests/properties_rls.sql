-- RLS / rule checks for properties. LOCAL only; everything is rolled back.
begin;

insert into auth.users (id, phone, phone_confirmed_at, aud, role) values
  ('00000000-0000-0000-0000-00000000000a', '9647500000001', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000000b', '9647500000002', now(), 'authenticated', 'authenticated');

create temp table results (test text, ok boolean);
grant all on results to authenticated, anon;

-- A published listing owned by B (set up as service role / postgres).
insert into public.properties (id, owner_id, category_id, transaction_type, title, price_amount,
                               governorate_id, district_id, publication_status, published_at)
select '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b',
       c.id, 'sale', 'Published house of B', 150000000, g.id, d.id, 'published', now()
from public.property_categories c, public.governorates g
join public.districts d on d.governorate_id = g.id and d.name_en = 'Erbil'
where c.slug = 'house' and g.code = 'ERB';

-- A pending listing owned by B (must stay hidden).
insert into public.properties (id, owner_id, category_id, transaction_type, title, price_amount,
                               governorate_id, district_id, publication_status)
select '10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000000b',
       category_id, transaction_type, 'Pending house of B', price_amount, governorate_id, district_id, 'pending_approval'
from public.properties where id = '10000000-0000-0000-0000-000000000001';

-- ===== as user A =====
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}';

insert into results select 'sees published listing', exists (select 1 from public.properties where id = '10000000-0000-0000-0000-000000000001');
insert into results select 'pending listing of others hidden', not exists (select 1 from public.properties where id = '10000000-0000-0000-0000-000000000002');

-- create own draft
insert into public.properties (id, owner_id, category_id, transaction_type, title, price_amount, governorate_id, district_id)
select '20000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000a',
       category_id, 'sale', 'My draft apartment', 90000000, governorate_id, district_id
from public.properties where id = '10000000-0000-0000-0000-000000000001';
insert into results select 'can create own draft', exists (select 1 from public.properties where id = '20000000-0000-0000-0000-00000000000a');

-- try to self-publish
do $$ begin
  begin
    update public.properties set publication_status = 'published' where id = '20000000-0000-0000-0000-00000000000a';
    insert into results values ('cannot self-publish', false);
  exception when insufficient_privilege then insert into results values ('cannot self-publish', true);
  end;
end $$;

-- try to insert directly as published
do $$ begin
  begin
    insert into public.properties (owner_id, category_id, transaction_type, title, price_amount, governorate_id, district_id, publication_status)
    select '00000000-0000-0000-0000-00000000000a', category_id, 'sale', 'Sneaky published', 1000, governorate_id, district_id, 'published'
    from public.properties where id = '20000000-0000-0000-0000-00000000000a';
    insert into results values ('cannot insert as published', false);
  exception when insufficient_privilege then insert into results values ('cannot insert as published', true);
  end;
end $$;

-- try to create a listing for someone else
do $$ begin
  begin
    insert into public.properties (owner_id, category_id, transaction_type, title, price_amount, governorate_id, district_id)
    select '00000000-0000-0000-0000-00000000000b', category_id, 'sale', 'Fake for B', 1000, governorate_id, district_id
    from public.properties where id = '20000000-0000-0000-0000-00000000000a';
    insert into results values ('cannot create for others', false);
  exception when insufficient_privilege then insert into results values ('cannot create for others', true);
  end;
end $$;

-- edit own draft
update public.properties set title = 'My edited apartment' where id = '20000000-0000-0000-0000-00000000000a';
insert into results select 'can edit own draft', (select title = 'My edited apartment' from public.properties where id = '20000000-0000-0000-0000-00000000000a');

-- edit someone else's listing → 0 rows
update public.properties set title = 'Hacked title!' where id = '10000000-0000-0000-0000-000000000001';

-- wrong district for governorate
do $$ begin
  begin
    update public.properties
       set district_id = (select d.id from public.districts d join public.governorates g on g.id = d.governorate_id where g.code = 'BAS' limit 1)
     where id = '20000000-0000-0000-0000-00000000000a';
    insert into results values ('rejects district outside governorate', false);
  exception when invalid_parameter_value then insert into results values ('rejects district outside governorate', true);
  end;
end $$;

-- favorites: only public listings
insert into public.property_favorites (user_id, property_id) values ('00000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-000000000001');
insert into results select 'can favorite published listing', exists (select 1 from public.property_favorites where property_id = '10000000-0000-0000-0000-000000000001');
do $$ begin
  begin
    insert into public.property_favorites (user_id, property_id) values ('00000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-000000000002');
    insert into results values ('cannot favorite hidden listing', false);
  exception when insufficient_privilege then insert into results values ('cannot favorite hidden listing', true);
  end;
end $$;

-- ===== as anonymous visitor =====
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
insert into results select 'anon sees only published', (select count(*) = 1 from public.properties);
insert into results select 'anon sees 17 categories', (select count(*) = 17 from public.property_categories);

reset role;
insert into results select 'other listing title unchanged', (select title = 'Published house of B' from public.properties where id = '10000000-0000-0000-0000-000000000001');
insert into results select 'favorites_count updated', (select favorites_count = 1 from public.properties where id = '10000000-0000-0000-0000-000000000001');
insert into results select 'status history recorded', (select count(*) >= 3 from public.property_status_history);

select json_build_object(
  'passed', count(*) filter (where ok),
  'total',  count(*),
  'failed', coalesce(string_agg(test, ', ') filter (where not ok), 'none')
) as result
from results;

rollback;
