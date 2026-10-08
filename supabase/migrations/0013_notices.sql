-- 0013_notices: notice board (Plan §20). Managers post; members read and
-- mark read. Soft delete via deleted_at; expiry hides a notice from the feed.

create table public.announcements (
  id         uuid primary key default gen_random_uuid(),
  mess_id    uuid not null references public.messes(id) on delete cascade,
  title      text not null check (char_length(btrim(title)) between 1 and 80),
  body       text not null default '' check (char_length(body) <= 1000),
  pinned     boolean not null default false,
  expires_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index announcements_mess_idx on public.announcements(mess_id, created_at desc);

create table public.announcement_reads (
  announcement_id uuid not null references public.announcements(id) on delete cascade,
  member_id       uuid not null references public.mess_members(id) on delete cascade,
  read_at         timestamptz not null default now(),
  primary key (announcement_id, member_id)
);

create trigger announcements_updated_at before update on public.announcements
  for each row execute function public.set_updated_at();
create trigger announcements_audit after insert or update or delete on public.announcements
  for each row execute function public.audit_row();

alter table public.announcements      enable row level security;
alter table public.announcement_reads enable row level security;

create policy announcements_read on public.announcements for select
  using (is_mess_member(mess_id));
create policy announcements_write on public.announcements for all
  using (has_mess_role(mess_id, 'manager')) with check (has_mess_role(mess_id, 'manager'));

-- True when p_member is the caller's own row in the notice's mess.
create or replace function public.is_own_notice_read(p_announcement uuid, p_member uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from announcements a
    join mess_members m on m.mess_id = a.mess_id
    where a.id = p_announcement and m.id = p_member and m.user_id = auth.uid()
      and m.status in ('active', 'inactive')
  );
$$;

create policy announcement_reads_read on public.announcement_reads for select
  using (exists (select 1 from announcements a where a.id = announcement_id));
create policy announcement_reads_insert on public.announcement_reads for insert
  with check (is_own_notice_read(announcement_id, member_id));
create policy announcement_reads_update on public.announcement_reads for update
  using (is_own_notice_read(announcement_id, member_id))
  with check (is_own_notice_read(announcement_id, member_id));

-- The live feed: not deleted, not expired, with the caller's read flag.
-- is_mess_member() in the where clause keeps it safe even though a PG14
-- view runs with its owner's rights.
create view public.announcement_feed as
  select a.id, a.mess_id, a.title, a.body, a.pinned, a.expires_at,
         a.created_by, a.created_at, a.updated_at,
         exists (
           select 1 from announcement_reads r
           join mess_members m on m.id = r.member_id
           where r.announcement_id = a.id and m.user_id = auth.uid()
         ) as is_read
  from announcements a
  where a.deleted_at is null
    and (a.expires_at is null or a.expires_at > now())
    and is_mess_member(a.mess_id);
