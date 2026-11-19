-- Make every environment match production: the cloud project has "auto-grant" OFF, but the
-- local stack grants ALL on new tables to anon/authenticated by default. Revoke those
-- defaults and re-state the exact grants from migrations 001–008, so column-level
-- restrictions are real everywhere (not only RLS / triggers).

alter default privileges for role postgres in schema public revoke all on tables    from anon, authenticated;
alter default privileges for role postgres in schema public revoke all on sequences from anon, authenticated;

revoke all on all tables    in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;

-- 001
grant select on public.user_roles to authenticated;
-- 002
grant select on public.governorates, public.districts, public.neighborhoods to anon, authenticated;
-- 003
grant select on public.profiles to authenticated;
grant update (full_name, avatar_path, email, governorate_id, district_id, account_type,
              preferred_locale, show_phone, onboarded_at) on public.profiles to authenticated;
grant select, insert, update, delete on public.user_devices to authenticated;
grant select, insert, delete on public.user_blocks to authenticated;
-- 004
grant select on public.property_categories, public.property_features to anon, authenticated;
grant select on public.properties to anon, authenticated;
grant insert, update on public.properties to authenticated;
grant select on public.property_status_history to authenticated;
grant select on public.property_images to anon, authenticated;
grant insert, delete on public.property_images to authenticated;
grant update (sort_order, is_cover) on public.property_images to authenticated;
grant select, insert, update, delete on public.property_favorites to authenticated;
-- 005
grant select (service_type, price_amount, currency, is_enabled, applies_to_transaction_types)
  on public.payment_settings to anon, authenticated;
grant select on public.payment_orders, public.payment_refunds,
                public.payment_provider_events, public.payment_audit_logs to authenticated;
grant select (id, order_id, provider, provider_payment_id, amount, currency, status, valid_until, created_at)
  on public.payment_transactions to authenticated;
-- 007
grant select on public.companies to anon, authenticated;
grant insert on public.companies to authenticated;
grant update (name, slug, logo_path, description_ckb, description_ar, description_en, governorate_id,
              district_id, office_address, office_location, phones, socials, is_developer, deleted_at)
  on public.companies to authenticated;
grant select on public.company_members to authenticated;
grant select on public.leads to authenticated;
grant update (status, assigned_to, note) on public.leads to authenticated;
-- 008
grant select on public.conversations, public.conversation_members, public.messages,
                public.message_reports, public.notifications to authenticated;
grant update (muted) on public.conversation_members to authenticated;
grant insert (conversation_id, sender_id, body, attachment_path) on public.messages to authenticated;
grant update (deleted_at) on public.messages to authenticated;
grant insert (message_id, reporter_id, reason, details) on public.message_reports to authenticated;
grant update (read_at) on public.notifications to authenticated;
