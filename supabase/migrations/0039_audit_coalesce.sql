-- 0039_audit_coalesce: one correction, one log line.
-- The same person changing the same row again within 10 minutes (tapping + twice
-- on a meal: 0 → ½ → 1) updates their previous log line instead of adding one:
--   added ½  then  ½ → 1   =>  added 1
--   ½ → 1    then  1 → ½   =>  nothing happened, the line disappears
-- Deletes (including soft deletes) are never merged.

create or replace function public.audit_row() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_old jsonb := case when tg_op <> 'INSERT' then to_jsonb(old) end;
  v_new jsonb := case when tg_op <> 'DELETE' then to_jsonb(new) end;
  v_row jsonb := coalesce(v_new, v_old);
  v_noise text[] := array['updated_at', 'updated_by'];
  p audit_log%rowtype;
begin
  if tg_op = 'UPDATE' and (v_old - v_noise) = (v_new - v_noise) then
    return null;
  end if;
  if tg_op = 'INSERT' and tg_table_name = 'meal_entries' and v_new ->> 'source' in ('system', 'auto') then
    return null;
  end if;
  if tg_op = 'DELETE' and coalesce(current_setting('meal_bazar.purging', true), '') = 'on' then
    return null;
  end if;

  if tg_op = 'UPDATE' and auth.uid() is not null and v_new ->> 'deleted_at' is null then
    select a.* into p from audit_log a
     where a.entity = tg_table_name and a.entity_id = (v_row ->> 'id')::uuid
       and a.actor_id = auth.uid() and a.action in ('insert', 'update')
       and a.at > now() - interval '10 minutes'
       and (a."new" ->> 'deleted_at') is null
     order by a.id desc limit 1;
    if found then
      if p.action = 'update' and (p.old - v_noise) = (v_new - v_noise) then
        delete from audit_log where id = p.id;       -- back where it started
      else
        update audit_log set "new" = v_new, at = now() where id = p.id;
      end if;
      return null;
    end if;
  end if;

  insert into audit_log (mess_id, actor_id, action, entity, entity_id, old, new, source)
  values (
    coalesce((v_row ->> 'mess_id')::uuid, (v_row ->> 'id')::uuid),
    auth.uid(), lower(tg_op), tg_table_name, (v_row ->> 'id')::uuid, v_old, v_new,
    coalesce(v_row ->> 'source', 'app')
  );
  return null;
end $$;

-- A plain fill (count 1) stays out of a member's activity; once it was
-- corrected inside the merge window it is an insert with another count: show it.
create or replace function public.my_activity(p_mess uuid, p_limit int default 30)
returns table (id bigint, at timestamptz, action text, entity text, ref_type text,
               ref_id uuid, actor_id uuid, actor_name text, old jsonb, new jsonb)
language sql stable set search_path = public as $$
  with me as (
    select m.id from mess_members m
    where m.mess_id = p_mess and m.user_id = auth.uid() and m.status in ('active', 'inactive')
  ),
  rows as (
    select a.*, coalesce(a.new, a.old) as r from audit_log a
    where a.mess_id = p_mess
      and a.entity in ('meal_entries', 'deposits', 'bazars', 'expenses')
      and a.actor_id is distinct from auth.uid()
  )
  select a.id, a.at, a.action, a.entity,
         case a.entity when 'meal_entries' then 'meal' when 'deposits' then 'deposit'
                       when 'bazars' then 'bazar' else 'expense' end,
         a.entity_id,
         a.actor_id,
         (select am.display_name from mess_members am
          where am.mess_id = p_mess and am.user_id = a.actor_id limit 1),
         a.old, a.new
  from rows a, me
  where case a.entity
    when 'meal_entries' then
      (a.r ->> 'member_id')::uuid = me.id
      and (a.action <> 'insert'
           or (a.r ->> 'is_off')::boolean or (a.r ->> 'guest_count')::int > 0
           -- a fill that was changed within minutes is merged into its insert (above): keep it
           or (a.r ->> 'count')::numeric <> 1)
    when 'deposits' then (a.r ->> 'member_id')::uuid = me.id
    when 'bazars' then
      me.id in ((a.new ->> 'paid_by_member_id')::uuid, (a.old ->> 'paid_by_member_id')::uuid,
                (a.r ->> 'buyer_member_id')::uuid)
      or exists (select 1 from bazar_buyers bb where bb.bazar_id = a.entity_id and bb.member_id = me.id)
    else
      me.id in ((a.new ->> 'paid_by_member_id')::uuid, (a.old ->> 'paid_by_member_id')::uuid)
      or exists (select 1 from expense_shares s where s.expense_id = a.entity_id and s.member_id = me.id)
  end
  order by a.at desc, a.id desc
  limit least(greatest(coalesce(p_limit, 30), 1), 100);
$$;
