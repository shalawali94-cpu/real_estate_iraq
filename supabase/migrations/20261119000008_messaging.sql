-- Conversations, messages (Supabase Realtime), reports, notifications.

create table public.conversations (
  id                   uuid primary key default gen_random_uuid(),
  property_id          uuid references public.properties (id) on delete set null,
  pair_key             text not null,                 -- 'smaller-uuid:larger-uuid'
  created_by           uuid not null references auth.users (id) on delete cascade,
  last_message_at      timestamptz,
  last_message_preview text,
  created_at           timestamptz not null default now()
);
create unique index conversations_unique_pair
  on public.conversations (coalesce(property_id, '00000000-0000-0000-0000-000000000000'::uuid), pair_key);

create table public.conversation_members (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id         uuid not null references auth.users (id) on delete cascade,
  last_read_at    timestamptz,
  unread_count    integer not null default 0,
  muted           boolean not null default false,
  primary key (conversation_id, user_id)
);
create index conversation_members_user_idx on public.conversation_members (user_id);

create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id       uuid not null references auth.users (id) on delete cascade,
  body            text check (char_length(body) between 1 and 4000),
  attachment_path text,
  created_at      timestamptz not null default now(),
  deleted_at      timestamptz,
  check (body is not null or attachment_path is not null)
);
create index messages_conversation_idx on public.messages (conversation_id, created_at desc);

create table public.message_reports (
  id          uuid primary key default gen_random_uuid(),
  message_id  uuid not null references public.messages (id) on delete cascade,
  reporter_id uuid not null references auth.users (id) on delete cascade,
  reason      text not null check (reason in ('spam', 'fraud', 'abuse', 'other')),
  details     text check (char_length(details) <= 1000),
  status      text not null default 'open' check (status in ('open', 'resolved', 'dismissed')),
  created_at  timestamptz not null default now(),
  unique (message_id, reporter_id)
);

create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  type       text not null,             -- new_message, property_approved, payment_success, ...
  title_key  text not null,             -- localized in the app
  body_key   text,
  params     jsonb not null default '{}',
  data       jsonb not null default '{}',
  read_at    timestamptz,
  pushed_at  timestamptz,               -- set by the backend after FCM send
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);
create index notifications_unpushed_idx on public.notifications (created_at) where pushed_at is null;

-- Helpers (SECURITY DEFINER to avoid RLS recursion) -------------------------
create or replace function public.conversation_is_member(p_conv uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.conversation_members
                 where conversation_id = p_conv and user_id = auth.uid());
$$;

create or replace function public.users_blocked(p_a uuid, p_b uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.user_blocks
                 where (blocker_id = p_a and blocked_id = p_b) or (blocker_id = p_b and blocked_id = p_a));
$$;

create or replace function public.conversation_can_send(p_conv uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select public.conversation_is_member(p_conv)
     and not exists (select 1 from public.conversation_members m
                     where m.conversation_id = p_conv and m.user_id <> auth.uid()
                       and public.users_blocked(auth.uid(), m.user_id));
$$;

-- Open (or reuse) a conversation with another user, optionally about a listing.
create or replace function public.conversation_open(p_other uuid, p_property uuid default null)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  v_me   uuid := auth.uid();
  v_key  text;
  v_id   uuid;
  v_prop public.properties;
begin
  if v_me is null then
    raise exception 'UNAUTHENTICATED' using errcode = '28000';
  end if;
  if p_other is null or p_other = v_me
     or not exists (select 1 from public.profiles where id = p_other and deleted_at is null and not is_suspended) then
    raise exception 'NOT_FOUND' using errcode = 'P0002';
  end if;
  if public.users_blocked(v_me, p_other) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;
  if p_property is not null then
    select * into v_prop from public.properties where id = p_property;
    if not found or not public.property_is_public(p_property)
       or not (v_prop.owner_id = p_other or v_prop.assigned_agent_id = p_other) then
      raise exception 'NOT_FOUND' using errcode = 'P0002';
    end if;
  end if;

  v_key := least(v_me, p_other)::text || ':' || greatest(v_me, p_other)::text;
  select id into v_id from public.conversations
  where pair_key = v_key
    and coalesce(property_id, '00000000-0000-0000-0000-000000000000'::uuid)
      = coalesce(p_property, '00000000-0000-0000-0000-000000000000'::uuid);
  if found then
    return v_id;
  end if;

  insert into public.conversations (property_id, pair_key, created_by)
  values (p_property, v_key, v_me) returning id into v_id;
  insert into public.conversation_members (conversation_id, user_id)
  values (v_id, v_me), (v_id, p_other);

  if p_property is not null then
    insert into public.leads (property_id, company_id, owner_id, customer_id, source, assigned_to)
    values (p_property, v_prop.company_id, v_prop.owner_id, v_me, 'message', v_prop.assigned_agent_id)
    on conflict (property_id, customer_id, source) do nothing;
  end if;
  return v_id;
end;
$$;

create or replace function public.conversation_mark_read(p_conv uuid)
returns void language sql security definer set search_path = ''
as $$
  update public.conversation_members
     set last_read_at = now(), unread_count = 0
   where conversation_id = p_conv and user_id = auth.uid();
$$;

-- After a message: update the conversation, unread counters, and notify recipients.
create or replace function public.messages_after_insert()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  update public.conversations
     set last_message_at = new.created_at,
         last_message_preview = left(coalesce(new.body, '📷'), 120)
   where id = new.conversation_id;

  update public.conversation_members
     set unread_count = unread_count + 1
   where conversation_id = new.conversation_id and user_id <> new.sender_id;

  insert into public.notifications (user_id, type, title_key, body_key, params, data)
  select m.user_id, 'new_message', 'notif_new_message_title', 'notif_new_message_body',
         jsonb_build_object('sender', coalesce(p.full_name, ''), 'preview', left(coalesce(new.body, ''), 80)),
         jsonb_build_object('conversation_id', new.conversation_id, 'message_id', new.id)
  from public.conversation_members m
  left join public.profiles p on p.id = new.sender_id
  where m.conversation_id = new.conversation_id and m.user_id <> new.sender_id and not m.muted;
  return null;
end;
$$;
create trigger messages_after_insert after insert on public.messages
  for each row execute function public.messages_after_insert();

-- RLS ----------------------------------------------------------------------
alter table public.conversations        enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages             enable row level security;
alter table public.message_reports      enable row level security;
alter table public.notifications        enable row level security;

create policy conversations_read on public.conversations
  for select to authenticated using (public.conversation_is_member(id) or public.is_staff());

create policy conversation_members_read on public.conversation_members
  for select to authenticated using (public.conversation_is_member(conversation_id));
create policy conversation_members_update_own on public.conversation_members
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy messages_read on public.messages
  for select to authenticated using (public.conversation_is_member(conversation_id) or public.is_staff());
create policy messages_insert on public.messages
  for insert to authenticated
  with check (sender_id = auth.uid() and public.conversation_can_send(conversation_id));
create policy messages_soft_delete_own on public.messages
  for update to authenticated using (sender_id = auth.uid()) with check (sender_id = auth.uid());

create policy message_reports_insert on public.message_reports
  for insert to authenticated
  with check (reporter_id = auth.uid()
              and exists (select 1 from public.messages m
                          where m.id = message_id and public.conversation_is_member(m.conversation_id)
                            and m.sender_id <> auth.uid()));
create policy message_reports_read on public.message_reports
  for select to authenticated using (reporter_id = auth.uid() or public.is_staff());

create policy notifications_read_own on public.notifications
  for select to authenticated using (user_id = auth.uid());
create policy notifications_update_own on public.notifications
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

grant select on public.conversations, public.conversation_members, public.messages,
                public.message_reports, public.notifications to authenticated;
grant update (muted) on public.conversation_members to authenticated;
grant insert (conversation_id, sender_id, body, attachment_path) on public.messages to authenticated;
grant update (deleted_at) on public.messages to authenticated;
grant insert (message_id, reporter_id, reason, details) on public.message_reports to authenticated;
grant update (read_at) on public.notifications to authenticated;

do $$
declare f text;
begin
  foreach f in array array['public.conversation_is_member(uuid)', 'public.users_blocked(uuid, uuid)',
                           'public.conversation_can_send(uuid)', 'public.conversation_open(uuid, uuid)',
                           'public.conversation_mark_read(uuid)'] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated, service_role', f);
  end loop;
end $$;

-- Realtime (respects RLS): chat, unread counters, notifications.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.messages, public.conversation_members, public.notifications;
  end if;
end $$;
