-- 0008_member_meal_off: a member switches their own meal off/on before the cutoff.
-- Rules: PRODUCT_RULES.md §1 (meal-off cutoff), §6. Managers keep using direct writes.

-- Cutoff = previous day at messes.meal_off_cutoff, Asia/Dhaka. Security definer
-- because meal_entries RLS is manager-only; the caller can only touch their own row.
-- The closed-month guard and normalize trigger still run on the write.
create or replace function public.set_my_meal_off(
  p_mess uuid, p_date date, p_meal_type uuid, p_off boolean
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := require_user();
  v_member uuid;
  v_cutoff timestamptz;
begin
  select id into v_member from mess_members
  where mess_id = p_mess and user_id = v_uid and status = 'active';
  if v_member is null then
    perform fail('NOT_MEMBER');
  end if;

  select ((p_date - 1) + meal_off_cutoff) at time zone 'Asia/Dhaka' into v_cutoff
  from messes where id = p_mess;
  if now() >= v_cutoff then
    perform fail('CUTOFF_PASSED');
  end if;

  if not exists (select 1 from meal_types where id = p_meal_type and mess_id = p_mess and enabled) then
    perform fail('MEAL_TYPE_INVALID');
  end if;

  insert into meal_entries (mess_id, member_id, meal_type_id, date, count, is_off, source)
  values (p_mess, v_member, p_meal_type, p_date, case when p_off then 0 else 1 end, p_off, 'app')
  on conflict (member_id, date, meal_type_id) do update
    set is_off = excluded.is_off,
        count  = case when excluded.is_off then 0 else 1 end,
        source = 'app';
end $$;
