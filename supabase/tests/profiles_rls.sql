-- Manual RLS check for profiles. Run in the LOCAL Studio SQL editor only.
-- Everything is rolled back at the end; returns one JSON cell.
begin;

insert into auth.users (id, phone, phone_confirmed_at, aud, role)
values ('00000000-0000-0000-0000-00000000000a', '9647500000001', now(), 'authenticated', 'authenticated'),
       ('00000000-0000-0000-0000-00000000000b', '9647500000002', now(), 'authenticated', 'authenticated');

create temp table results (test text, ok boolean) on commit drop;
grant all on results to authenticated;

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}';

-- 1 own profile visible, created by trigger with phone_verified
insert into results select 'own profile auto-created & verified',
  exists (select 1 from public.profiles where id = '00000000-0000-0000-0000-00000000000a' and phone_verified);
-- 2 other user's private row hidden
insert into results select 'other profile hidden',
  not exists (select 1 from public.profiles where id = '00000000-0000-0000-0000-00000000000b');
-- 3 other user visible through public view
insert into results select 'other visible via get_public_profiles',
  exists (select 1 from public.get_public_profiles(array['00000000-0000-0000-0000-00000000000b'::uuid]));
-- 4 can edit own name
update public.profiles set full_name = 'Shalaw Test' where id = '00000000-0000-0000-0000-00000000000a';
insert into results select 'can edit own name',
  (select full_name = 'Shalaw Test' from public.profiles where id = '00000000-0000-0000-0000-00000000000a');
-- 5 cannot edit other user (0 rows affected)
update public.profiles set full_name = 'Hacked' where id = '00000000-0000-0000-0000-00000000000b';
-- 6 cannot set protected column (column privilege denies it)
do $$ begin
  begin
    update public.profiles set identity_verified = true where id = '00000000-0000-0000-0000-00000000000a';
    insert into results values ('cannot self-verify identity', false);
  exception when insufficient_privilege then
    insert into results values ('cannot self-verify identity', true);
  end;
end $$;
-- 7 cannot read roles of others / grant self a role
do $$ begin
  begin
    insert into public.user_roles (user_id, role) values ('00000000-0000-0000-0000-00000000000a', 'super_admin');
    insert into results values ('cannot grant self admin', false);
  exception when insufficient_privilege then
    insert into results values ('cannot grant self admin', true);
  end;
end $$;

reset role;
insert into results select 'other user name unchanged',
  (select full_name is null from public.profiles where id = '00000000-0000-0000-0000-00000000000b');

select json_build_object(
  'passed', count(*) filter (where ok),
  'total',  count(*),
  'failed', coalesce(string_agg(test, ', ') filter (where not ok), 'none')
) as result
from results;

rollback;
