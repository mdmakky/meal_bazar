-- 0014_bazar_duty: bazar duty roster ("বাজারের পালা"). REQUIREMENTS §3.4.
-- Members read, managers write; the assigned member may mark their own duty done
-- through mark_my_duty_done(). Rows are hard-deleted (a roster, not money).

create table public.bazar_duties (
  id         uuid primary key default gen_random_uuid(),
  mess_id    uuid not null references public.messes(id) on delete cascade,
  date       date not null,
  member_id  uuid not null,
  note       text check (char_length(note) <= 200),
  done       boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (mess_id, date, member_id),
  foreign key (member_id, mess_id) references public.mess_members(id, mess_id)
);
create index bazar_duties_mess_date_idx on public.bazar_duties(mess_id, date);

create trigger bazar_duties_updated_at before update on public.bazar_duties
  for each row execute function public.set_updated_at();
create trigger bazar_duties_audit after insert or update or delete on public.bazar_duties
  for each row execute function public.audit_row();

alter table public.bazar_duties enable row level security;
create policy bazar_duties_read on public.bazar_duties for select using (is_mess_member(mess_id));
create policy bazar_duties_write on public.bazar_duties for all
  using (has_mess_role(mess_id, 'manager')) with check (has_mess_role(mess_id, 'manager'));

-- The assigned member (or a manager, via RLS) toggles done on their own duty.
create or replace function public.mark_my_duty_done(p_id uuid, p_done boolean default true)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := require_user();
begin
  update bazar_duties d set done = p_done
  from mess_members m
  where d.id = p_id and m.id = d.member_id and m.user_id = v_uid
    and m.status in ('active', 'inactive');
  if not found then
    perform fail('NOT_YOUR_DUTY');
  end if;
end $$;

-- Round-robin: dates p_from, p_from + p_every, … within p_days days; each date
-- that already has a duty is skipped and the next member waits for the next free
-- date. Returns the number of duties created.
create or replace function public.generate_duty_rotation(
  p_mess uuid, p_from date, p_days int, p_member_ids uuid[], p_every int default 1
) returns int
language plpgsql security definer set search_path = public as $$
declare
  v_n     int := coalesce(array_length(p_member_ids, 1), 0);
  v_i     int := 0;
  v_date  date;
begin
  perform require_user();
  if not has_mess_role(p_mess, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  if v_n = 0 or p_days is null or p_days not between 1 and 366
     or p_every is null or p_every not between 1 and 31 or p_from is null then
    perform fail('INVALID_ROTATION');
  end if;
  if exists (
    select 1 from unnest(p_member_ids) u(id)
    where not exists (select 1 from mess_members m
                      where m.id = u.id and m.mess_id = p_mess and m.status = 'active')
  ) then
    perform fail('INVALID_ROTATION');
  end if;

  for v_date in select generate_series(p_from, p_from + (p_days - 1), make_interval(days => p_every))::date
  loop
    continue when exists (select 1 from bazar_duties where mess_id = p_mess and date = v_date);
    insert into bazar_duties (mess_id, date, member_id)
    values (p_mess, v_date, p_member_ids[v_i % v_n + 1]);
    v_i := v_i + 1;
  end loop;
  return v_i;
end $$;
