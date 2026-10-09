-- 0022_messages: member ↔ manager messages (not real-time chat) and
-- "report a problem" about an entry. A thread is between ONE member and all
-- of the mess's managers. Writes go through the RPCs below (client UUIDs, so
-- a retry is idempotent); messages are append-only. A new message pushes the
-- other side (type `message`). Contract: DATABASE.md "Messages (0022)".

create table public.message_threads (
  id              uuid primary key default gen_random_uuid(),
  mess_id         uuid not null references public.messes(id) on delete cascade,
  member_id       uuid not null references public.mess_members(id) on delete cascade,
  subject         text not null check (char_length(btrim(subject)) between 1 and 80),
  ref_type        text check (ref_type in ('deposit', 'bazar', 'expense', 'meal', 'other')),
  ref_id          uuid,
  ref_label       text check (char_length(ref_label) <= 120),
  status          text not null default 'open' check (status in ('open', 'resolved')),
  created_by      uuid references auth.users(id) on delete set null default auth.uid(),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);
create index message_threads_mess_idx on public.message_threads(mess_id, last_message_at desc);
create index message_threads_member_idx on public.message_threads(member_id);

create table public.messages (
  id         uuid primary key default gen_random_uuid(),
  thread_id  uuid not null references public.message_threads(id) on delete cascade,
  mess_id    uuid not null references public.messes(id) on delete cascade,
  -- Null once the sender's account is deleted; the message stays.
  sender_id  uuid references auth.users(id) on delete set null,
  body       text not null check (char_length(btrim(body)) between 1 and 1000),
  created_at timestamptz not null default clock_timestamp()
);
create index messages_thread_idx on public.messages(thread_id, created_at);
create index messages_mess_idx on public.messages(mess_id);

create table public.message_reads (
  thread_id uuid not null references public.message_threads(id) on delete cascade,
  user_id   uuid not null references auth.users(id) on delete cascade,
  read_at   timestamptz not null default now(),
  primary key (thread_id, user_id)
);

create trigger message_threads_updated_at before update on public.message_threads
  for each row execute function public.set_updated_at();
create trigger message_threads_suspension before insert or update or delete on public.message_threads
  for each row execute function public.guard_suspension();
create trigger messages_suspension before insert or update or delete on public.messages
  for each row execute function public.guard_suspension();

-- ── RLS: the thread's member and the mess's managers; nobody else ────────
-- Writes only through the security definer RPCs (no write policies), so
-- messages are append-only for clients.
create or replace function public.can_see_thread(p_mess uuid, p_member uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select has_mess_role(p_mess, 'manager') or exists (
    select 1 from mess_members
    where id = p_member and mess_id = p_mess and user_id = auth.uid() and status in ('active', 'inactive')
  );
$$;

alter table public.message_threads enable row level security;
alter table public.messages        enable row level security;
alter table public.message_reads   enable row level security;

create policy message_threads_read on public.message_threads for select
  using (can_see_thread(mess_id, member_id));
create policy messages_read on public.messages for select
  using (exists (select 1 from message_threads t where t.id = thread_id));
create policy message_reads_read on public.message_reads for select
  using (user_id = auth.uid());

-- ── inbox ────────────────────────────────────────────────────────────────
-- Threads I can see, with the member's name, the last message and my unread
-- flag (a message from someone else after my last read). can_see_thread() in
-- the where clause keeps it safe while a PG14 view runs with owner rights.
create view public.message_thread_feed as
  select t.id, t.mess_id, t.member_id, t.subject, t.ref_type, t.ref_id, t.ref_label,
         t.status, t.created_by, t.created_at, t.updated_at, t.last_message_at,
         m.display_name as member_name,
         lm.body as last_body, lm.sender_id as last_sender_id,
         exists (
           select 1 from messages x
           where x.thread_id = t.id and x.sender_id is distinct from auth.uid()
             and x.created_at > coalesce((select r.read_at from message_reads r
                                          where r.thread_id = t.id and r.user_id = auth.uid()),
                                         '-infinity')
         ) as is_unread
  from message_threads t
  join mess_members m on m.id = t.member_id
  left join lateral (
    select x.body, x.sender_id from messages x
    where x.thread_id = t.id order by x.created_at desc, x.id desc limit 1
  ) lm on true
  where can_see_thread(t.mess_id, t.member_id);

create or replace function public.unread_thread_count(p_mess uuid) returns int
language sql stable set search_path = public as $$
  select count(*)::int from message_thread_feed where mess_id = p_mess and is_unread;
$$;

-- ── RPCs ─────────────────────────────────────────────────────────────────
-- The caller's visible thread, or NOT_MEMBER.
create or replace function public.thread_for_caller(p_thread uuid) returns public.message_threads
language plpgsql stable security definer set search_path = public as $$
declare
  t message_threads;
begin
  select * into t from message_threads where id = p_thread;
  if not found or not can_see_thread(t.mess_id, t.member_id) then
    perform fail('NOT_MEMBER');
  end if;
  return t;
end $$;

-- Appends a message (idempotent on p_id). The member writing into a resolved
-- thread reopens it.
create or replace function public.post_message(p_id uuid, p_thread uuid, p_body text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := require_user();
  t     message_threads := thread_for_caller(p_thread);
  v_own boolean := exists (select 1 from mess_members where id = t.member_id and user_id = v_uid);
begin
  if exists (select 1 from messages where id = p_id) then
    return;   -- an offline retry of a message already saved
  end if;
  insert into messages (id, thread_id, mess_id, sender_id, body)
  values (p_id, t.id, t.mess_id, v_uid, btrim(p_body));
  update message_threads
  set last_message_at = now(), status = case when v_own then 'open' else status end
  where id = t.id;
end $$;

-- Opens a thread with its first message (idempotent on p_id). A member
-- writes as themselves; a manager may pass p_member to write to a member.
create or replace function public.start_thread(
  p_id uuid, p_mess uuid, p_subject text, p_body text,
  p_ref_type text default null, p_ref_id uuid default null, p_ref_label text default null,
  p_member uuid default null, p_message_id uuid default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := require_user();
  v_member uuid;
begin
  if exists (select 1 from message_threads where id = p_id) then
    perform thread_for_caller(p_id);
    return p_id;   -- retry
  end if;
  if p_member is null then
    select id into v_member from mess_members
    where mess_id = p_mess and user_id = v_uid and status = 'active';
  else
    if not has_mess_role(p_mess, 'manager') then
      perform fail('NOT_MANAGER');
    end if;
    select id into v_member from mess_members
    where id = p_member and mess_id = p_mess and status in ('active', 'inactive');
  end if;
  if v_member is null then
    perform fail('NOT_MEMBER');
  end if;
  insert into message_threads (id, mess_id, member_id, subject, ref_type, ref_id, ref_label, created_by)
  values (p_id, p_mess, v_member, btrim(p_subject), p_ref_type, p_ref_id,
          nullif(btrim(p_ref_label), ''), v_uid);
  perform post_message(coalesce(p_message_id, gen_random_uuid()), p_id, p_body);
  return p_id;
end $$;

-- Managers resolve or reopen; the thread's member may reopen their own.
create or replace function public.set_thread_status(p_thread uuid, p_status text) returns void
language plpgsql security definer set search_path = public as $$
declare
  t message_threads := thread_for_caller(p_thread);
begin
  if not has_mess_role(t.mess_id, 'manager') and p_status <> 'open' then
    perform fail('NOT_MANAGER');
  end if;
  update message_threads set status = p_status where id = t.id and status <> p_status;
end $$;

create or replace function public.mark_thread_read(p_thread uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  t message_threads := thread_for_caller(p_thread);
begin
  insert into message_reads (thread_id, user_id) values (t.id, require_user())
  on conflict (thread_id, user_id) do update set read_at = now();
end $$;

-- ── platform flag `messages` (missing = on) ──────────────────────────────
alter function public.platform_config_defaults() rename to platform_config_defaults_pre_messages;
create function public.platform_config_defaults() returns jsonb
language sql immutable as $$
  select jsonb_set(platform_config_defaults_pre_messages(), '{features,messages}', 'true');
$$;
update public.platform_config set value = value || '{"messages":true}'
where key = 'features' and not value ? 'messages';

-- ── push: a new message → the other side ─────────────────────────────────
-- The member writes → every active manager; a manager writes → the member.
create or replace function public.push_on_message() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  t      message_threads;
  m      mess_members;
  v_name text;
  v_to   uuid[];
begin
  if coalesce(platform_default('features', 'messages'), 'true') = 'false'::jsonb then
    return null;
  end if;
  select * into t from message_threads where id = new.thread_id;
  select * into m from mess_members where id = t.member_id;
  if m.user_id is not distinct from new.sender_id then
    v_to := push_mess_users(t.mess_id, 'manager', new.sender_id);
  elsif m.status = 'active' and m.user_id is not null then
    v_to := array[m.user_id];
  end if;
  select display_name into v_name from mess_members
  where mess_id = t.mess_id and user_id = new.sender_id;
  perform push_enqueue(v_to, 'message',
    'বার্তা: ' || t.subject, coalesce(v_name || ': ', '') || new.body,
    'Message: ' || t.subject, coalesce(v_name || ': ', '') || new.body,
    '/more/messages/' || t.id);
  return null;
end $$;
create trigger messages_push after insert on public.messages
  for each row execute function public.push_on_message();

revoke execute on function public.push_on_message() from public, anon, authenticated;
