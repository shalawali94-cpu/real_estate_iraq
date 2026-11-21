-- Email sign-ups carry full name + mobile number in user metadata.
-- The phone is stored UNVERIFIED (phone_verified stays false until real SMS OTP).
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  v_name  text := nullif(btrim(new.raw_user_meta_data ->> 'full_name'), '');
  v_phone text := nullif(btrim(new.raw_user_meta_data ->> 'phone'), '');
begin
  if v_name is not null and char_length(v_name) not between 2 and 80 then v_name := null; end if;
  if v_phone is not null and v_phone !~ '^\+9647[0-9]{9}$' then v_phone := null; end if;
  insert into public.profiles (id, full_name, phone, email, phone_verified)
  values (new.id, v_name, coalesce(new.phone, v_phone), new.email, new.phone_confirmed_at is not null)
  on conflict (id) do nothing;
  return new;
end;
$$;
