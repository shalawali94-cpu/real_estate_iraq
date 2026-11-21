-- LOCAL DEVELOPMENT ONLY. Never run against cloud/production.
-- Creates three clearly-labelled [TEST] listings owned by test user +9647500000001
-- (log in once in the app first so the user exists). Safe to re-run.
do $$
declare v_owner uuid;
begin
  select id into v_owner from auth.users where phone = '9647500000001';
  if v_owner is null then
    raise exception 'Log in once with +964 7500000001 first';
  end if;

  delete from public.properties where title like '[TEST]%' and owner_id = v_owner;

  insert into public.properties (owner_id, category_id, transaction_type, title, description,
      price_amount, price_currency, price_negotiable, governorate_id, district_id,
      area_sqm, bedrooms, bathrooms, location, publication_status, published_at, is_featured)
  select v_owner, c.id, x.tx::public.transaction_type, x.title, x.descr, x.price, x.cur, x.neg,
         g.id, d.id, x.area, x.beds, x.baths,
         extensions.st_setsrid(extensions.st_makepoint(x.lng, x.lat), 4326)::extensions.geography,
         'published', now(), x.feat
  from (values
    ('house',     'sale', '[TEST] House in Erbil',        'Test listing',  25000000000::bigint, 'IQD', true,  'ERB', 'Erbil',        250, 4, 3, 44.01, 36.19, true),
    ('apartment', 'rent', '[TEST] Apartment in Sulaymaniyah', 'Test listing', 80000000::bigint,  'IQD', false, 'SUL', 'Sulaymaniyah', 120, 3, 2, 45.43, 35.56, false),
    ('villa',     'sale', '[TEST] Villa in Baghdad',      'Test listing',  25000000::bigint,    'USD', true,  'BGD', null,           400, 5, 4, 44.36, 33.31, false)
  ) as x(slug, tx, title, descr, price, cur, neg, gcode, dname, area, beds, baths, lng, lat, feat)
  join public.property_categories c on c.slug = x.slug
  join public.governorates g on g.code = x.gcode
  join lateral (select d2.id from public.districts d2
                where d2.governorate_id = g.id and (x.dname is null or d2.name_en = x.dname)
                order by d2.id limit 1) d on true;
end $$;
select title, price_amount, price_currency, publication_status from public.properties where title like '[TEST]%';
