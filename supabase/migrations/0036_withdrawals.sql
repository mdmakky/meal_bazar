-- 0036_withdrawals: a manager pays a member back part of what they deposited.
-- A withdrawal is a NEGATIVE deposit (kind = 'withdrawal', amount < 0), so every
-- existing sum — the member's credit, the mess fund, the month totals and the
-- closing snapshot — becomes net automatically; nothing else needs a minus.
-- Only managers can record one (members have no insert right on deposits), and
-- only up to the member's current balance. Contract: DATABASE.md "Withdrawals (0036)".

alter table public.deposits
  drop constraint if exists deposits_amount_check,
  add column kind text not null default 'deposit' check (kind in ('deposit', 'withdrawal')),
  add constraint deposits_amount_sign check (
    (kind = 'deposit' and amount > 0) or (kind = 'withdrawal' and amount < 0));

-- Manager only; idempotent on p_id (an offline retry). p_amount is what is
-- paid out, positive. Verified at once: the cash is handed over as it is entered.
create or replace function public.record_withdrawal(
  p_mess uuid, p_id uuid, p_member uuid, p_date date, p_amount numeric,
  p_method public.pay_method, p_note text
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_from  date;
  v_to    date;
  v_avail numeric;
begin
  perform require_user();
  if not has_mess_role(p_mess, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  perform assert_mess_writable(p_mess);
  if p_amount is null or p_amount <= 0 then
    perform fail('AMOUNT_INVALID');
  end if;
  if p_date > dhaka_today() then
    perform fail('FUTURE_DATE');
  end if;
  if month_is_closed(p_mess, p_date) then
    perform fail('MONTH_CLOSED');
  end if;
  if not exists (select 1 from mess_members m where m.id = p_member and m.mess_id = p_mess
                 and m.status in ('active', 'inactive', 'left')) then
    perform fail('NOT_MEMBER');
  end if;
  if exists (select 1 from deposits where id = p_id) then
    if not exists (select 1 from deposits where id = p_id and mess_id = p_mess and member_id = p_member
                   and kind = 'withdrawal') then
      perform fail('NOT_MEMBER');            -- id taken by something else
    end if;
    return p_id;
  end if;
  -- Never more than the member is owed right now (SQL's own balance figure).
  select start_date, end_date into v_from, v_to from month_period(p_mess, p_date);
  select b.closing_balance into v_avail from member_balances(p_mess, v_from, v_to) b where b.member_id = p_member;
  if p_amount > greatest(coalesce(v_avail, 0), 0) then
    perform fail('WITHDRAWAL_EXCEEDS_BALANCE');
  end if;
  insert into deposits (id, mess_id, member_id, date, amount, kind, method, status, note, source)
  values (p_id, p_mess, p_member, p_date, -p_amount, 'withdrawal', p_method, 'verified',
          nullif(btrim(p_note), ''), 'app');
  return p_id;
end $$;

-- The member hears about it in the right words (0026's trigger, one branch changed).
create or replace function public.push_on_deposit() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  m mess_members%rowtype;
begin
  if new.deleted_at is not null then
    return null;
  end if;
  select * into m from mess_members where id = new.member_id;
  if tg_op = 'INSERT' and new.status = 'pending' then
    perform push_enqueue(push_mess_users(new.mess_id, 'manager', auth.uid()), 'deposit_pending',
      'জমা যাচাই করুন', format('%s %s জমা দিয়েছেন', m.display_name, push_money(new.amount, true)),
      'Deposit to verify', format('%s deposited %s', m.display_name, push_money(new.amount, false)),
      '/money');
  elsif tg_op = 'INSERT' and new.status = 'verified' and new.kind = 'withdrawal'
        and m.user_id is distinct from auth.uid() then
    perform push_enqueue(array[m.user_id], 'deposit_added',
      'টাকা ফেরত', format('আপনাকে %s ফেরত দেওয়া হয়েছে', push_money(-new.amount, true)),
      'Money paid back', format('%s was paid back to you', push_money(-new.amount, false)),
      '/money');
  elsif tg_op = 'INSERT' and new.status = 'verified' and m.user_id is distinct from auth.uid() then
    perform push_enqueue(array[m.user_id], 'deposit_added',
      'জমা যোগ হয়েছে', format('আপনার নামে %s জমা যোগ করা হয়েছে', push_money(new.amount, true)),
      'Deposit recorded', format('%s was recorded as your deposit', push_money(new.amount, false)),
      '/money');
  elsif tg_op = 'UPDATE' and old.status = 'pending' and new.status <> 'pending'
        and m.user_id is distinct from auth.uid() then
    if new.status = 'verified' then
      perform push_enqueue(array[m.user_id], 'deposit_verified',
        'জমা গৃহীত হয়েছে', format('আপনার %s জমা যাচাই হয়েছে', push_money(new.amount, true)),
        'Deposit verified', format('Your %s deposit was verified', push_money(new.amount, false)),
        '/money');
    else
      perform push_enqueue(array[m.user_id], 'deposit_rejected',
        'জমা বাতিল হয়েছে', format('আপনার %s জমা বাতিল করা হয়েছে', push_money(new.amount, true)),
        'Deposit rejected', format('Your %s deposit was rejected', push_money(new.amount, false)),
        '/money');
    end if;
  end if;
  return null;
end $$;
