-- LOCAL DEVELOPMENT helper: grant a role to an existing user, found by email OR phone.
-- Usage (email):  psql ... -v who=admin@example.com -v role=admin -f supabase/dev/make_admin.sql
-- Usage (phone):  psql ... -v who=9647500000002     -v role=admin -f supabase/dev/make_admin.sql
-- Roles: moderator | admin | finance_admin | super_admin
-- Production: roles are granted only by a super admin (service role), never from the client.
insert into public.user_roles (user_id, role)
select id, :'role'::public.app_role from auth.users
 where lower(email) = lower(:'who') or phone = :'who'
on conflict do nothing;
select coalesce(u.email, u.phone) as who, r.role
  from public.user_roles r join auth.users u on u.id = r.user_id order by 1;
