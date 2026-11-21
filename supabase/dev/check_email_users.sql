-- LOCAL DEVELOPMENT ONLY. Lists email users (no passwords) as one copyable cell.
select coalesce(string_agg(
  email || ' | confirmed=' || (email_confirmed_at is not null)::text
        || ' | has_password=' || (encrypted_password is not null and encrypted_password <> '')::text
        || ' | banned=' || (banned_until is not null)::text
        || ' | deleted=' || (deleted_at is not null)::text
        || ' | provider=' || coalesce(raw_app_meta_data->>'provider', '?'),
  E'\n'), 'no email users') as email_users
from auth.users where email is not null;
