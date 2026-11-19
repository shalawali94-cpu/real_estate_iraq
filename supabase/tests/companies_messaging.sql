-- Companies, leads, messaging, notifications. LOCAL only; rolled back. One JSON cell.
begin;

insert into auth.users (id, phone, phone_confirmed_at, aud, role) values
  ('00000000-0000-0000-0000-00000000000a', '9647500000001', now(), 'authenticated', 'authenticated'),  -- buyer A
  ('00000000-0000-0000-0000-00000000000b', '9647500000002', now(), 'authenticated', 'authenticated'),  -- owner B
  ('00000000-0000-0000-0000-00000000000c', '9647500000003', now(), 'authenticated', 'authenticated');  -- stranger C
update public.profiles set full_name = 'Owner B' where id = '00000000-0000-0000-0000-00000000000b';

create temp table results (test text, ok boolean);
grant all on results to authenticated;
create temp table ids (k text primary key, v uuid);
grant all on ids to authenticated;

-- B's published listing
insert into public.properties (id, owner_id, category_id, transaction_type, title, price_amount,
                               governorate_id, district_id, publication_status, published_at)
select '40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b',
       c.id, 'sale', 'Villa in Duhok test', 250000000, g.id, d.id, 'published', now()
from public.property_categories c, public.governorates g
join public.districts d on d.governorate_id = g.id and d.name_en = 'Duhok'
where c.slug = 'villa' and g.code = 'DUH';

-- ===== B creates a company =====
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}';
insert into public.companies (id, owner_id, name, slug)
values ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', 'B Real Estate', 'b-real-estate');
insert into results select 'company owner auto-added as member',
  public.company_role_of('50000000-0000-0000-0000-000000000001') = 'owner';
do $$ begin
  begin
    update public.companies set verified = true where id = '50000000-0000-0000-0000-000000000001';
    insert into results values ('company cannot self-verify', false);
  exception when insufficient_privilege then insert into results values ('company cannot self-verify', true);
  end;
end $$;

-- ===== C (stranger) =====
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}';
do $$ begin
  begin
    insert into public.properties (owner_id, category_id, transaction_type, title, price_amount, governorate_id, district_id, company_id)
    select '00000000-0000-0000-0000-00000000000c', category_id, 'sale', 'Hijack company', 1000, governorate_id, district_id,
           '50000000-0000-0000-0000-000000000001'
    from public.properties where id = '40000000-0000-0000-0000-000000000001';
    insert into results values ('cannot list under a company you are not in', false);
  exception when insufficient_privilege then insert into results values ('cannot list under a company you are not in', true);
  end;
end $$;

-- ===== A (buyer) contacts B about the listing =====
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}';
insert into ids values ('conv', public.conversation_open('00000000-0000-0000-0000-00000000000b', '40000000-0000-0000-0000-000000000001'));
insert into results select 'opening twice returns same conversation',
  public.conversation_open('00000000-0000-0000-0000-00000000000b', '40000000-0000-0000-0000-000000000001') = (select v from ids where k = 'conv');
insert into public.messages (conversation_id, sender_id, body)
values ((select v from ids where k = 'conv'), '00000000-0000-0000-0000-00000000000a', 'Slaw, is the villa still available?');
insert into results select 'buyer sees own message', (select count(*) = 1 from public.messages);
select public.lead_record('40000000-0000-0000-0000-000000000001', 'whatsapp');

-- ===== B (owner) =====
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}';
insert into results select 'owner receives message', (select count(*) = 1 from public.messages);
insert into results select 'owner unread = 1',
  (select unread_count = 1 from public.conversation_members where user_id = '00000000-0000-0000-0000-00000000000b');
insert into results select 'owner got notification',
  (select count(*) = 1 from public.notifications where type = 'new_message');
insert into results select 'owner sees 2 leads (message + whatsapp)', (select count(*) = 2 from public.leads);
select public.conversation_mark_read((select v from ids where k = 'conv'));
insert into results select 'mark read resets unread',
  (select unread_count = 0 from public.conversation_members where user_id = '00000000-0000-0000-0000-00000000000b');
-- B blocks A
insert into public.user_blocks (blocker_id, blocked_id) values ('00000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000a');

-- ===== C cannot read or write into A–B chat =====
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}';
insert into results select 'stranger sees no messages', (select count(*) = 0 from public.messages);
insert into results select 'stranger sees no notifications of others', (select count(*) = 0 from public.notifications);
insert into results select 'stranger sees no leads', (select count(*) = 0 from public.leads);
do $$ begin
  begin
    insert into public.messages (conversation_id, sender_id, body)
    values ((select v from ids where k = 'conv'), '00000000-0000-0000-0000-00000000000c', 'spam');
    insert into results values ('stranger cannot post into chat', false);
  exception when insufficient_privilege then insert into results values ('stranger cannot post into chat', true);
  end;
end $$;

-- ===== A is blocked now =====
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}';
do $$ begin
  begin
    insert into public.messages (conversation_id, sender_id, body)
    values ((select v from ids where k = 'conv'), '00000000-0000-0000-0000-00000000000a', 'hello?');
    insert into results values ('blocked user cannot send', false);
  exception when insufficient_privilege then insert into results values ('blocked user cannot send', true);
  end;
end $$;
do $$ begin
  begin
    perform public.conversation_open('00000000-0000-0000-0000-00000000000b', null);
    insert into results values ('blocked user cannot open new chat', false);
  exception when insufficient_privilege then insert into results values ('blocked user cannot open new chat', true);
  end;
end $$;
do $$ begin
  begin
    update public.notifications set user_id = '00000000-0000-0000-0000-00000000000a';
    insert into results values ('cannot reassign notifications', false);
  exception when insufficient_privilege then insert into results values ('cannot reassign notifications', true);
  end;
end $$;

reset role;
select json_build_object(
  'passed', count(*) filter (where ok),
  'total',  count(*),
  'failed', coalesce(string_agg(test, ', ') filter (where not ok), 'none')
) as result
from results;

rollback;
