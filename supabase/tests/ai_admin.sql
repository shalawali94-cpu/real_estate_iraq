-- AI video order lifecycle, refunds, settings. LOCAL only; rolled back. One JSON cell.
begin;

insert into auth.users (id, phone, phone_confirmed_at, aud, role) values
  ('00000000-0000-0000-0000-00000000000a', '9647500000001', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-00000000000b', '9647500000002', now(), 'authenticated', 'authenticated');

create temp table results (test text, ok boolean);
grant all on results to authenticated, anon, service_role;
create temp table ids (k text primary key, v uuid);
grant all on ids to authenticated, service_role;

insert into public.properties (id, owner_id, category_id, transaction_type, title, price_amount, governorate_id, district_id)
select '70000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a', c.id, 'sale', 'Apartment for AI video',
       80000000, g.id, d.id
from public.property_categories c, public.governorates g
join public.districts d on d.governorate_id = g.id and d.name_en = 'Erbil'
where c.slug = 'apartment' and g.code = 'ERB';
insert into public.property_images (id, property_id, owner_id, storage_path, sort_order)
select gen_random_uuid(), '70000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a',
       '00000000-0000-0000-0000-00000000000a/70000000-0000-0000-0000-000000000001/' || i || '.jpg', i
from generate_series(1, 4) i;

-- ===== user cannot create jobs or run the worker =====
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}';
do $$ begin
  begin
    insert into public.ai_jobs (user_id, kind, status) values ('00000000-0000-0000-0000-00000000000a', 'video', 'queued');
    insert into results values ('user cannot insert a queued job', false);
  exception when insufficient_privilege then insert into results values ('user cannot insert a queued job', true);
  end;
  begin
    perform public.ai_job_claim('video');
    insert into results values ('user cannot run worker functions', false);
  exception when insufficient_privilege then insert into results values ('user cannot run worker functions', true);
  end;
end $$;

-- ===== backend =====
reset role;
set local role service_role;

do $$ begin
  begin
    perform public.ai_video_create('00000000-0000-0000-0000-00000000000a', '70000000-0000-0000-0000-000000000001',
      array(select id from public.property_images limit 4), '{"duration":45,"aspect":"9:16"}');
    insert into results values ('rejects invalid duration', false);
  exception when check_violation then insert into results values ('rejects invalid duration', true);
  end;
  begin
    perform public.ai_video_create('00000000-0000-0000-0000-00000000000b', '70000000-0000-0000-0000-000000000001',
      array(select id from public.property_images limit 4), '{"duration":30,"aspect":"9:16"}');
    insert into results values ('cannot make video of someone else''s listing', false);
  exception when no_data_found then insert into results values ('cannot make video of someone else''s listing', true);
  end;
end $$;

insert into ids select 'job', id from public.ai_video_create('00000000-0000-0000-0000-00000000000a',
  '70000000-0000-0000-0000-000000000001', array(select id from public.property_images limit 4),
  '{"duration":30,"aspect":"9:16","style":"modern"}');
insert into results select 'job waits for payment', (select status = 'pending_payment' from public.ai_jobs where id = (select v from ids where k = 'job'));
insert into results select 'worker finds nothing before payment', (select (public.ai_job_claim('video')).id is null);

insert into ids select 'order', id from public.payment_create_order('00000000-0000-0000-0000-00000000000a', 'AI_VIDEO_GENERATION',
  null, (select v from ids where k = 'job'), 'QI_CARD', 'video-checkout-0001');
insert into results select 'video order is 30000 IQD', (select amount = 30000 and service_type = 'AI_VIDEO_GENERATION'
  from public.payment_orders where id = (select v from ids where k = 'order'));
select public.payment_attach_transaction((select v from ids where k = 'order'), 'QI-VID-1', '{}', null);
select public.payment_mark_paid('QI_CARD', 'QI-VID-1', 30000, 'IQD', '{}');
insert into results select 'paid → job queued', (select status = 'queued' from public.ai_jobs where id = (select v from ids where k = 'job'));
do $$ begin
  begin
    perform public.payment_create_order('00000000-0000-0000-0000-00000000000a', 'AI_VIDEO_GENERATION',
      null, (select v from ids where k = 'job'), 'FIB', 'video-checkout-0002');
    insert into results values ('cannot pay twice for one video', false);
  exception when raise_exception then insert into results values ('cannot pay twice for one video', true);
  end;
end $$;

-- provider fails 3 times → failed; then one free regeneration; then success
do $$ declare j public.ai_jobs; begin
  for i in 1..3 loop
    j := public.ai_job_claim('video');
    perform public.ai_job_fail(j.id, 'provider timeout');
  end loop;
end $$;
insert into results select 'fails after 3 attempts', (select status = 'failed' and attempts = 3 from public.ai_jobs where id = (select v from ids where k = 'job'));
insert into results select 'regenerate is free (no new order)',
  (select (public.ai_job_regenerate('00000000-0000-0000-0000-00000000000a', (select v from ids where k = 'job'))).status = 'queued')
  and (select count(*) = 1 from public.payment_orders where ai_job_id = (select v from ids where k = 'job'));
do $$ declare j public.ai_jobs; begin
  j := public.ai_job_claim('video');
  perform public.ai_job_progress(j.id, 60::smallint);
  perform public.ai_job_complete(j.id, 'ai-outputs/x/video.mp4', 'template', 'ffmpeg', 30::smallint);
end $$;
insert into results select 'completed and labeled as template',
  (select status = 'completed' and render_mode = 'template' and progress = 100 from public.ai_jobs where id = (select v from ids where k = 'job'));

-- second job, refund path
insert into ids select 'job2', id from public.ai_video_create('00000000-0000-0000-0000-00000000000a',
  '70000000-0000-0000-0000-000000000001', array(select id from public.property_images limit 3), '{"duration":15,"aspect":"1:1"}');
insert into ids select 'order2', id from public.payment_create_order('00000000-0000-0000-0000-00000000000a', 'AI_VIDEO_GENERATION',
  null, (select v from ids where k = 'job2'), 'FIB', 'video-checkout-0003');
select public.payment_attach_transaction((select v from ids where k = 'order2'), 'FIB-VID-2', '{}', null);
select public.payment_mark_paid('FIB', 'FIB-VID-2', 30000, 'IQD', '{}');
select public.payment_request_refund((select v from ids where k = 'order2'), 'service could not be delivered', null);
insert into results select 'refund requested → job refund_pending',
  (select status = 'refund_pending' from public.ai_jobs where id = (select v from ids where k = 'job2'))
  and (select refund_status = 'requested' from public.payment_orders where id = (select v from ids where k = 'order2'));

-- ===== visibility =====
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a","role":"authenticated"}';
insert into results select 'owner sees jobs + notifications',
  (select count(*) = 2 from public.ai_jobs)
  and (select count(*) >= 3 from public.notifications where type in ('payment_success', 'ai_video_failed', 'ai_video_completed'));
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}';
insert into results select 'others see no jobs', (select count(*) = 0 from public.ai_jobs);
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
insert into results select 'anon reads only public settings',
  (select count(*) = 0 from public.application_settings where key = 'ai_video_max_attempts')
  and (select count(*) > 0 from public.application_settings);

reset role;
select json_build_object(
  'passed', count(*) filter (where ok),
  'total',  count(*),
  'failed', coalesce(string_agg(test, ', ') filter (where not ok), 'none')
) as result
from results;

rollback;
