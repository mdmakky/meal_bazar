-- 0038_leave_and_delete_mess:
--   • a member may leave a mess by themselves. If the mess owes them money (or
--     they owe nothing) they leave at once and the managers are told. If they owe
--     the mess, they cannot leave: they ask the managers (a push) who settle
--     up and mark them left.
--   • the owner-manager may delete the mess: 30 days of grace (everyone is told,
--     the owner can cancel), then the nightly cron erases it.

alter table public.messes
  add column if not exists delete_requested_at timestamptz,
  add column if not exists delete_requested_by uuid;

-- What leaving would mean for me right now: my balance this month (positive =
-- the mess owes me). One row, or none when I am not a member.
create or replace function public.leave_preview(p_mess uuid)
returns table (balance numeric, only_manager boolean)
language plpgsql stable security definer set search_path = public as $$
declare
  v_me mess_members%rowtype;
  v_from date;
  v_to date;
begin
  perform require_user();
  select * into v_me from mess_members
   where mess_id = p_mess and user_id = auth.uid() and status in ('active', 'inactive');
  if not found then
    return;
  end if;
  select start_date, end_date into v_from, v_to from month_period(p_mess, dhaka_today());
  return query
    select coalesce((select b.closing_balance from member_balances(p_mess, v_from, v_to) b
                      where b.member_id = v_me.id), 0),
           v_me.role = 'manager' and not exists (
             select 1 from mess_members o
              where o.mess_id = p_mess and o.id <> v_me.id and o.role = 'manager' and o.status = 'active');
end $$;

create or replace function public.leave_mess(p_mess uuid) returns numeric
language plpgsql security definer set search_path = public as $$
declare
  v_me mess_members%rowtype;
  v_bal numeric;
  v_mess text;
begin
  perform require_user();
  select * into v_me from mess_members
   where mess_id = p_mess and user_id = auth.uid() and status in ('active', 'inactive') for update;
  if not found then
    perform fail('NOT_MEMBER');
  end if;
  select balance into v_bal from leave_preview(p_mess);
  if (select only_manager from leave_preview(p_mess)) then
    perform fail('LAST_MANAGER');
  end if;
  if v_bal < 0 then
    perform fail('DUES_OUTSTANDING');
  end if;
  update mess_members set status = 'left', left_on = greatest(joined_on, dhaka_today()) where id = v_me.id;
  select name into v_mess from messes where id = p_mess;
  perform push_enqueue(push_mess_users(p_mess, 'manager', auth.uid()), 'member_left',
    'সদস্য মেস ছেড়েছেন',
    format('%s: %s মেস ছেড়েছেন%s', v_mess, v_me.display_name,
           case when v_bal > 0 then format(', মেস তাকে %s দেবে', push_money(v_bal, true)) else '' end),
    'A member left',
    format('%s: %s left the mess%s', v_mess, v_me.display_name,
           case when v_bal > 0 then format(', the mess owes them %s', push_money(v_bal, false)) else '' end),
    '/more/members');
  return v_bal;
end $$;

-- Someone who owes money asks the managers to settle up and let them go.
create or replace function public.request_leave(p_mess uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_me mess_members%rowtype;
  v_bal numeric;
  v_mess text;
begin
  perform require_user();
  select * into v_me from mess_members
   where mess_id = p_mess and user_id = auth.uid() and status in ('active', 'inactive');
  if not found then
    perform fail('NOT_MEMBER');
  end if;
  select balance into v_bal from leave_preview(p_mess);
  select name into v_mess from messes where id = p_mess;
  perform push_enqueue(push_mess_users(p_mess, 'manager', auth.uid()), 'member_left',
    'মেস ছাড়তে চান',
    format('%s: %s মেস ছাড়তে চান%s', v_mess, v_me.display_name,
           case when v_bal < 0 then format(', তার বাকি %s', push_money(-v_bal, true)) else '' end),
    'Wants to leave',
    format('%s: %s wants to leave%s', v_mess, v_me.display_name,
           case when v_bal < 0 then format(', they owe %s', push_money(-v_bal, false)) else '' end),
    '/more/members');
end $$;

-- ── delete the mess: 30 days of grace ────────────────────────────────────
create or replace function public.request_mess_deletion(p_mess uuid, p_name text) returns timestamptz
language plpgsql security definer set search_path = public as $$
declare
  v_mess messes%rowtype;
  v_on timestamptz;
begin
  perform require_user();
  select * into v_mess from messes where id = p_mess;
  if not found or not has_mess_role(p_mess, 'manager')
     or (v_mess.created_by is not null and v_mess.created_by <> auth.uid()) then
    perform fail('NOT_OWNER');
  end if;
  if btrim(p_name) is distinct from btrim(v_mess.name) then
    perform fail('NAME_MISMATCH');
  end if;
  update messes set delete_requested_at = coalesce(delete_requested_at, now()), delete_requested_by = auth.uid()
   where id = p_mess returning delete_requested_at + interval '30 days' into v_on;
  perform push_enqueue(push_mess_users(p_mess, null, auth.uid()), 'mess_deletion',
    'মেস মুছে যাচ্ছে',
    format('%s মেসটি %s তারিখে মুছে যাবে', v_mess.name,
           translate(to_char(v_on at time zone 'Asia/Dhaka', 'DD/MM/YYYY'), '0123456789', '০১২৩৪৫৬৭৮৯')),
    'Mess is being deleted',
    format('%s will be deleted on %s', v_mess.name, to_char(v_on at time zone 'Asia/Dhaka', 'DD Mon YYYY')),
    '/today');
  return v_on;
end $$;

create or replace function public.cancel_mess_deletion(p_mess uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_mess messes%rowtype;
begin
  perform require_user();
  select * into v_mess from messes where id = p_mess;
  if not found or not has_mess_role(p_mess, 'manager')
     or (v_mess.created_by is not null and v_mess.created_by <> auth.uid()) then
    perform fail('NOT_OWNER');
  end if;
  if v_mess.delete_requested_at is null then
    return;
  end if;
  update messes set delete_requested_at = null, delete_requested_by = null where id = p_mess;
  perform push_enqueue(push_mess_users(p_mess, null, auth.uid()), 'mess_deletion',
    'মেস মোছা বাতিল', format('%s মেসটি আর মুছে যাবে না', v_mess.name),
    'Deletion cancelled', format('%s will not be deleted', v_mess.name), '/today');
end $$;

-- The audit trail must not write rows for a mess that is being erased.
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
  if tg_op = 'DELETE' and coalesce(current_setting('meal_bazar.purging', true), '') = 'on' then
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

-- The nightly cron (service role): erase what has waited 30 days. Everything
-- hangs off messes with ON DELETE CASCADE.
create or replace function public.purge_deleted_messes() returns int
language plpgsql security definer set search_path = public as $$
declare
  n int;
begin
  perform set_config('meal_bazar.purging', 'on', true);
  delete from messes where delete_requested_at < now() - interval '30 days';
  get diagnostics n = row_count;
  return n;
end $$;
revoke execute on function public.purge_deleted_messes() from public, anon, authenticated;
grant execute on function public.purge_deleted_messes() to service_role;
