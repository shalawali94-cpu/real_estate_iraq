-- LOCAL DEVELOPMENT helper: grant a role to an existing user (log in once first).
-- Usage: psql ... -v phone=9647500000002 -v role=admin -f supabase/dev/make_admin.sql
-- Roles: moderator | admin | finance_admin | super_admin
-- Production: roles are granted only by a super admin (service role), never from the client.
insert into public.user_roles (user_id, role)
select id, :'role'::public.app_role from auth.users where phone = :'phone'
on conflict do nothing;
select u.phone, r.role from public.user_roles r join auth.users u on u.id = r.user_id order by u.phone;
