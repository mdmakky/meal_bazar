-- 0031_auto_meals: missing meals are filled in automatically after midnight
-- (Asia/Dhaka). Pattern = meal_defaults (else 1). Never overwrites an existing
-- entry (so meal-off always wins), never touches closed months, tagged
-- source = 'auto' so a manager can see and correct them.
-- Contract: DATABASE.md "Auto meals (0031)".

alter table public.messes
  add column auto_meals            boolean not null default false,
  add column auto_meals_last_date  date,
  add column auto_meals_last_count int;

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

-- Fills the last p_days days before p_today (Dhaka today by default): at
-- 00:00 on the 10th the 9th is filled; the extra days catch up after a missed
-- run. Service role only (the daily cron). Returns the rows created.
-- Safe to repeat or run concurrently: inserts are on-conflict-do-nothing and
-- each (mess, day) is guarded by a transaction advisory lock.
create or replace function public.auto_fill_meals(
  p_days int default 3,
  p_today date default (now() at time zone 'Asia/Dhaka')::date
) returns int
language plpgsql security definer set search_path = public as $$
declare
  ms  record;
  d   date;
  n   int;
  tot int := 0;
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
      insert into meal_entries (mess_id, member_id, meal_type_id, date, count, source)
      select ms.id, m.id, t.id, d,
             coalesce((select x.count from meal_defaults x
                       where x.member_id = m.id and x.meal_type_id = t.id), 1),
             'auto'
      from mess_members m
      cross join meal_types t
      where m.mess_id = ms.id and t.mess_id = ms.id and t.enabled
        and m.joined_on <= d
        and (m.status = 'active' or (m.status = 'left' and m.left_on > d))
      on conflict (member_id, date, meal_type_id) do nothing;
      get diagnostics n = row_count;
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
