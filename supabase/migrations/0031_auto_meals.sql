-- 0031_auto_meals: missing meals are filled in automatically after midnight
-- (Asia/Dhaka). Pattern = meal_defaults (else 1). Never overwrites an existing
-- entry (so meal-off always wins), never touches closed months, tagged
-- source = 'auto' so a manager can see and correct them.
-- Contract: DATABASE.md "Auto meals (0031)".

alter table public.messes
  add column auto_meals            boolean not null default false,
  add column auto_meals_last_date  date,
  add column auto_meals_last_count int,
  add column auto_meals_since      date;   -- the day the switch was last turned on (Dhaka)

-- When the switch turns on, remember the day: month close only insists on a
-- finished run for days the job was meant to cover.
create or replace function public.set_auto_meals_since() returns trigger
language plpgsql as $$
begin
  if new.auto_meals and not old.auto_meals then
    new.auto_meals_since := (now() at time zone 'Asia/Dhaka')::date;
  elsif not new.auto_meals then
    new.auto_meals_since := null;
  end if;
  return new;
end $$;
create trigger messes_auto_meals_since before update of auto_meals on public.messes
  for each row execute function public.set_auto_meals_since();

-- One row per (mess, day) the job handled, with how it ended:
--   ok          every eligible (member × meal type) cell has an entry now
--   incomplete  the insert ran but some eligible cells still have none
--   failed      an error rolled that day back (sqlstate in `error`)
-- Month close accepts only 'ok' for the month's last day.
create table public.auto_meal_runs (
  mess_id  uuid not null references public.messes(id) on delete cascade,
  date     date not null,
  status   text not null check (status in ('ok', 'incomplete', 'failed')),
  eligible int  not null default 0,
  created  int  not null default 0,
  error    text,
  attempts int  not null default 1,
  run_at   timestamptz not null default now(),
  primary key (mess_id, date)
);
alter table public.auto_meal_runs enable row level security;
create policy auto_meal_runs_read on public.auto_meal_runs for select using (is_mess_member(mess_id));

alter table public.meal_entries drop constraint if exists meal_entries_source_check;
alter table public.meal_entries
  add constraint meal_entries_source_check check (source in ('app', 'ai', 'system', 'auto'));

-- Auto rows are not audited (hundreds a day, nobody reviews them); an edit
-- sends source 'app', which is audited as usual.
create or replace function public.audit_row() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_old jsonb := case when tg_op <> 'INSERT' then to_jsonb(old) end;
  v_new jsonb := case when tg_op <> 'DELETE' then to_jsonb(new) end;
  v_row jsonb := coalesce(v_new, v_old);
begin
  if tg_op = 'UPDATE' and (v_old - 'updated_at') = (v_new - 'updated_at') then
    return null;
  end if;
  if tg_op = 'INSERT' and tg_table_name = 'meal_entries' and v_new ->> 'source' in ('system', 'auto') then
    return null;
  end if;
  insert into audit_log (mess_id, actor_id, action, entity, entity_id, old, new, source)
  values (
    coalesce((v_row ->> 'mess_id')::uuid, (v_row ->> 'id')::uuid),
    auth.uid(), lower(tg_op), tg_table_name, (v_row ->> 'id')::uuid, v_old, v_new,
    coalesce(v_row ->> 'source', 'app')
  );
  return null;
end $$;

-- The cells that should hold an entry for a day: eligible member × enabled
-- meal type, with the member's default (else 1). One definition, used both to
-- insert and to verify.
create or replace function public.auto_meal_eligible(p_mess uuid, p_day date)
returns table (member_id uuid, meal_type_id uuid, count numeric)
language sql stable set search_path = public as $$
  select m.id, t.id,
         coalesce((select x.count from meal_defaults x
                   where x.member_id = m.id and x.meal_type_id = t.id), 1)
  from mess_members m
  cross join meal_types t
  where m.mess_id = p_mess and t.mess_id = p_mess and t.enabled
    and m.joined_on <= p_day
    and (m.status = 'active' or (m.status = 'left' and m.left_on > p_day));
$$;

-- Fills the last p_days days before p_today (Dhaka today by default): at
-- 00:00 on the 10th the 9th is filled; the extra days catch up after a missed
-- run. Service role only (the daily cron). Returns the rows created.
-- Each (mess, day) is its own sub-transaction: an error rolls only that day
-- back and is recorded as 'failed'. After inserting, the day is verified
-- against auto_meal_eligible, so 'ok' means every cell really has an entry.
-- Safe to repeat or run concurrently: inserts are on-conflict-do-nothing and
-- each (mess, day) is guarded by a transaction advisory lock.
create or replace function public.auto_fill_meals(
  p_days int default 3,
  p_today date default (now() at time zone 'Asia/Dhaka')::date
) returns int
language plpgsql security definer set search_path = public as $$
declare
  ms       record;
  d        date;
  n        int;
  v_elig   int;
  v_left   int;
  v_status text;
  v_err    text;
  tot      int := 0;
begin
  for ms in
    select id from messes where auto_meals and suspended_at is null
  loop
    for d in select g::date from generate_series(p_today - least(greatest(p_days, 1), 7),
                                                 p_today - 1, interval '1 day') g
    loop
      if month_is_closed(ms.id, d)
         or not pg_try_advisory_xact_lock(hashtextextended(ms.id::text || d::text, 31)) then
        continue;
      end if;
      begin
        insert into meal_entries (mess_id, member_id, meal_type_id, date, count, source)
        select ms.id, e.member_id, e.meal_type_id, d, e.count, 'auto'
        from auto_meal_eligible(ms.id, d) e
        on conflict (member_id, date, meal_type_id) do nothing;
        get diagnostics n = row_count;
        select count(*) into v_elig from auto_meal_eligible(ms.id, d);
        select count(*) into v_left from auto_meal_eligible(ms.id, d) e
        where not exists (select 1 from meal_entries x
                          where x.member_id = e.member_id and x.meal_type_id = e.meal_type_id and x.date = d);
        v_status := case when v_left = 0 then 'ok' else 'incomplete' end;
        v_err := null;
      exception when others then
        n := 0; v_elig := 0; v_status := 'failed'; v_err := sqlstate;
      end;
      insert into auto_meal_runs (mess_id, date, status, eligible, created, error)
      values (ms.id, d, v_status, v_elig, n, v_err)
      on conflict (mess_id, date) do update
        set status = excluded.status, eligible = excluded.eligible, error = excluded.error,
            created = auto_meal_runs.created + excluded.created,
            attempts = auto_meal_runs.attempts + 1, run_at = now();
      if n > 0 then
        update messes set auto_meals_last_date = d, auto_meals_last_count = n where id = ms.id;
        tot := tot + n;
      end if;
    end loop;
  end loop;
  return tot;
end $$;
revoke execute on function public.auto_fill_meals(int, date) from public, anon, authenticated;
grant execute on function public.auto_fill_meals(int, date) to service_role;
