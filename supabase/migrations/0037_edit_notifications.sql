-- 0037_edit_notifications: people hear about corrections.
--   bazar / shared cost edited or deleted → everyone else in the mess
--   a deposit (or payback) edited or deleted → that member
--   a manager changes a member's meals → that member (one push per 10 minutes)
-- One push type, 'entry_edited', so one switch in notification settings.
-- Nothing fires for system work (cron, no auth.uid()), for the actor's own
-- changes, or for an upsert that changes nothing (offline retries).

create or replace function public.push_on_bazar_edit() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_mess text;
  v_gone boolean := old.deleted_at is null and new.deleted_at is not null;
begin
  if auth.uid() is null or new.deleted_at is not null and not v_gone then
    return null;
  end if;
  if not v_gone and (old.amount, old.date, old.paid_by_member_id, old.buyer_member_id)
                    is not distinct from (new.amount, new.date, new.paid_by_member_id, new.buyer_member_id) then
    return null;
  end if;
  select name into v_mess from messes where id = new.mess_id;
  perform push_enqueue(push_mess_users(new.mess_id, null, auth.uid()), 'entry_edited',
    case when v_gone then 'বাজার মুছে ফেলা হয়েছে' else 'বাজার বদলানো হয়েছে' end,
    format('%s: %s এর বাজার %s%s', v_mess, push_money(new.amount, true),
           case when v_gone then 'মুছে ফেলা হয়েছে' else 'বদলানো হয়েছে' end,
           case when not v_gone and old.amount <> new.amount
                then format(' (আগে %s)', push_money(old.amount, true)) else '' end),
    case when v_gone then 'Bazar deleted' else 'Bazar changed' end,
    format('%s: %s bazar %s%s', v_mess, push_money(new.amount, false),
           case when v_gone then 'was deleted' else 'was changed' end,
           case when not v_gone and old.amount <> new.amount
                then format(' (was %s)', push_money(old.amount, false)) else '' end),
    '/bazar');
  return null;
end $$;
create trigger bazars_edit_push after update on public.bazars
  for each row execute function public.push_on_bazar_edit();

create or replace function public.push_on_expense_edit() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_mess text;
  v_cat text;
  v_gone boolean := old.deleted_at is null and new.deleted_at is not null;
begin
  if auth.uid() is null or new.deleted_at is not null and not v_gone then
    return null;
  end if;
  if not v_gone and (old.amount, old.date, old.category_id, old.split, old.paid_by_member_id)
                    is not distinct from (new.amount, new.date, new.category_id, new.split, new.paid_by_member_id) then
    return null;
  end if;
  select name into v_mess from messes where id = new.mess_id;
  select name into v_cat from expense_categories where id = new.category_id;
  perform push_enqueue(push_mess_users(new.mess_id, null, auth.uid()), 'entry_edited',
    case when v_gone then 'খরচ মুছে ফেলা হয়েছে' else 'খরচ বদলানো হয়েছে' end,
    format('%s: %s %s %s%s', v_mess, v_cat, push_money(new.amount, true),
           case when v_gone then 'মুছে ফেলা হয়েছে' else 'বদলানো হয়েছে' end,
           case when not v_gone and old.amount <> new.amount
                then format(' (আগে %s)', push_money(old.amount, true)) else '' end),
    case when v_gone then 'Expense deleted' else 'Expense changed' end,
    format('%s: %s %s %s%s', v_mess, v_cat, push_money(new.amount, false),
           case when v_gone then 'was deleted' else 'was changed' end,
           case when not v_gone and old.amount <> new.amount
                then format(' (was %s)', push_money(old.amount, false)) else '' end),
    '/money');
  return null;
end $$;
create trigger expenses_edit_push after update on public.expenses
  for each row execute function public.push_on_expense_edit();

-- Status changes (verify / reject) have their own pushes (0019, 0036).
create or replace function public.push_on_deposit_edit() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  m mess_members%rowtype;
  v_gone boolean := old.deleted_at is null and new.deleted_at is not null;
  v_pay boolean := new.kind = 'withdrawal';
begin
  if auth.uid() is null or new.status is distinct from old.status
     or new.deleted_at is not null and not v_gone then
    return null;
  end if;
  if not v_gone and (old.amount, old.date, old.method) is not distinct from (new.amount, new.date, new.method) then
    return null;
  end if;
  select * into m from mess_members where id = new.member_id;
  if m.user_id is null or m.user_id = auth.uid() then
    return null;
  end if;
  perform push_enqueue(array[m.user_id], 'entry_edited',
    case when v_gone then (case when v_pay then 'ফেরত মুছে ফেলা হয়েছে' else 'জমা মুছে ফেলা হয়েছে' end)
         else (case when v_pay then 'ফেরত বদলানো হয়েছে' else 'জমা বদলানো হয়েছে' end) end,
    format('আপনার %s %s%s', push_money(abs(new.amount), true),
           case when v_gone then (case when v_pay then 'ফেরত মুছে ফেলা হয়েছে' else 'জমা মুছে ফেলা হয়েছে' end)
                else (case when v_pay then 'ফেরত বদলানো হয়েছে' else 'জমা বদলানো হয়েছে' end) end,
           case when not v_gone and old.amount <> new.amount
                then format(' (আগে %s)', push_money(abs(old.amount), true)) else '' end),
    case when v_gone then (case when v_pay then 'Payback deleted' else 'Deposit deleted' end)
         else (case when v_pay then 'Payback changed' else 'Deposit changed' end) end,
    format('Your %s %s%s', push_money(abs(new.amount), false),
           case when v_gone then (case when v_pay then 'payback was deleted' else 'deposit was deleted' end)
                else (case when v_pay then 'payback was changed' else 'deposit was changed' end) end,
           case when not v_gone and old.amount <> new.amount
                then format(' (was %s)', push_money(abs(old.amount), false)) else '' end),
    '/money');
  return null;
end $$;
create trigger deposits_edit_push after update on public.deposits
  for each row execute function public.push_on_deposit_edit();

-- A manager entering a member's meals: they hear once per 10 minutes, with
-- the first date touched, so filling a month does not become 30 pushes.
create or replace function public.push_on_meal_edit() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  m mess_members%rowtype;
begin
  if auth.uid() is null or new.source in ('system', 'auto') then
    return null;
  end if;
  if tg_op = 'UPDATE' and (old.count, old.guest_count, old.is_off)
                          is not distinct from (new.count, new.guest_count, new.is_off) then
    return null;
  end if;
  select * into m from mess_members where id = new.member_id;
  if m.user_id is null or m.user_id = auth.uid() or not has_mess_role(new.mess_id, 'manager') then
    return null;
  end if;
  if exists (select 1 from notifications where user_id = m.user_id and type = 'entry_edited'
               and route like '/meals%' and created_at > now() - interval '10 minutes') then
    return null;
  end if;
  perform push_enqueue(array[m.user_id], 'entry_edited',
    'খাবারের হিসাব বদলানো হয়েছে',
    format('ম্যানেজার আপনার %s তারিখের খাবার বদলেছেন',
           translate(to_char(new.date, 'DD/MM'), '0123456789', '০১২৩৪৫৬৭৮৯')),
    'Your meals were changed',
    format('The manager changed your meals on %s', to_char(new.date, 'DD Mon')),
    '/meals?date=' || new.date::text);
  return null;
end $$;
create trigger meal_entries_edit_push after insert or update on public.meal_entries
  for each row execute function public.push_on_meal_edit();
