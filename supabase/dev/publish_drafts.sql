-- LOCAL DEVELOPMENT ONLY. Never run against cloud/production.
-- Publishes ALL local drafts so they appear in Home/Explore, skipping the 30,000 IQD
-- payment + moderation (which need real FIB/Qi credentials and an admin).
update public.properties
   set publication_status = 'published', published_at = now()
 where publication_status = 'draft' and deleted_at is null;
select string_agg(title || ' [' || publication_status || ']', ' | ') as properties
  from public.properties where deleted_at is null;
