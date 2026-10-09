-- 0026_member_bazar_and_inbox: a member submits their own bazar for the
-- manager to approve; an in-app notification inbox; the member is told when
-- a manager records a deposit for them; a month cannot close with pending
-- items; the member's last-month settlement for Home.
-- Contract: DATABASE.md "Member bazar, inbox, month close (0026)".

-- ── bazar requests ───────────────────────────────────────────────────────
-- A request is not a bazar: no money math reads this table. Approving it
-- creates the real bazar (+ items + buyers) in one transaction.
create table public.bazar_requests (
  id            uuid primary key,                       -- client generated
  mess_id       uuid not null references public.messes(id) on delete cascade,
  member_id     uuid not null,                          -- who submitted
  date          date not null,
  amount        numeric(12,2) not null check (amount > 0),
  own_pocket    boolean not null default true,          -- false = paid from the mess fund
  buyer_ids     uuid[] not null default '{}',           -- companions, the submitter included
  items         jsonb not null default '[]' check (jsonb_typeof(items) = 'array'),
  note          text check (char_length(note) <= 300),
  receipt_path  text,
  status        text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  reject_reason text check (char_length(reject_reason) <= 200),
  bazar_id      uuid references public.bazars(id) on delete set null,
  reviewed_by   uuid,
  reviewed_at   timestamptz,
  created_at    timestamptz not null default now(),
  foreign key (member_id, mess_id) references public.mess_members(id, mess_id)
);
create index bazar_requests_mess_idx on public.bazar_requests(mess_id, status, date);

create trigger bazar_requests_suspension before insert or update or delete on public.bazar_requests
  for each row execute function public.guard_suspension();
create trigger bazar_requests_audit after insert or update or delete on public.bazar_requests
  for each row execute function public.audit_row();

alter table public.bazar_requests enable row level security;
-- The submitter and the managers see a request; writes only through the RPCs.
create policy bazar_requests_read on public.bazar_requests for select using (
  has_mess_role(mess_id, 'manager')
  or exists (select 1 from mess_members m where m.id = member_id and m.user_id = auth.uid()));

-- Member: submit (idempotent on id, so an offline retry never doubles).
create or replace function public.submit_bazar_request(
  p_mess uuid, p_id uuid, p_date date, p_amount numeric, p_own_pocket boolean,
  p_buyer_ids uuid[], p_items jsonb, p_note text, p_receipt_path text
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := require_user();
  v_member uuid;
  v_buyers uuid[];
begin
  select id into v_member from mess_members
  where mess_id = p_mess and user_id = v_uid and status = 'active';
  if v_member is null then
    perform fail('NOT_MEMBER');
  end if;
  if coalesce(platform_default('features', 'member_bazar'), 'true') = 'false'::jsonb then
    perform fail('FEATURE_OFF');
  end if;
  if p_date > (now() at time zone 'Asia/Dhaka')::date then
    perform fail('FUTURE_DATE');
  end if;
  if month_is_closed(p_mess, p_date) then
    perform fail('MONTH_CLOSED');
  end if;
  if p_receipt_path is not null and receipt_mess(p_receipt_path) is distinct from p_mess then
    perform fail('RECEIPT_PATH_INVALID');
  end if;
  -- Buyers: the submitter first, then distinct active members of this mess.
  select array_agg(id order by id <> v_member, ord) into v_buyers
  from (select distinct on (b) b as id, ord
        from unnest(array_prepend(v_member, coalesce(p_buyer_ids, '{}'))) with ordinality u(b, ord)
        order by b, ord) x
  where exists (select 1 from mess_members m where m.id = x.id and m.mess_id = p_mess and m.status = 'active');
  if jsonb_typeof(coalesce(p_items, '[]')) <> 'array' or jsonb_array_length(coalesce(p_items, '[]')) > 100 then
    perform fail('ITEMS_INVALID');
  end if;

  insert into bazar_requests (id, mess_id, member_id, date, amount, own_pocket, buyer_ids, items,
                              note, receipt_path)
  values (p_id, p_mess, v_member, p_date, p_amount, coalesce(p_own_pocket, true), v_buyers,
          coalesce(p_items, '[]'), nullif(btrim(p_note), ''), p_receipt_path)
  on conflict (id) do nothing;
  if not exists (select 1 from bazar_requests where id = p_id and member_id = v_member) then
    perform fail('NOT_MEMBER');            -- id taken by someone else's row
  end if;
  return p_id;
end $$;

-- Member: withdraw their own pending request.
create or replace function public.cancel_bazar_request(p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform require_user();
  update bazar_requests r set status = 'cancelled'
  where r.id = p_id and r.status = 'pending'
    and exists (select 1 from mess_members m where m.id = r.member_id and m.user_id = auth.uid());
  if not found then
    perform fail('BAZAR_REQUEST_NOT_PENDING');
  end if;
end $$;

-- Manager: approve (→ a real bazar with the same id) or reject with a reason.
create or replace function public.review_bazar_request(p_id uuid, p_approve boolean, p_reason text default null)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  r      bazar_requests%rowtype;
  v_user uuid;
begin
  perform require_user();
  select * into r from bazar_requests where id = p_id for update;
  if r.id is null or not has_mess_role(r.mess_id, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  if r.status <> 'pending' then
    perform fail('BAZAR_REQUEST_NOT_PENDING');
  end if;
  select user_id into v_user from mess_members where id = r.member_id;

  if not p_approve then
    update bazar_requests
    set status = 'rejected', reject_reason = nullif(btrim(p_reason), ''),
        reviewed_by = auth.uid(), reviewed_at = now()
    where id = p_id;
    perform push_enqueue(array[v_user], 'bazar_request_reviewed',
      'বাজারের হিসাব ফেরত এসেছে',
      format('আপনার %s বাজার গ্রহণ করা হয়নি%s', push_money(r.amount, true),
             coalesce(': ' || nullif(btrim(p_reason), ''), '')),
      'Bazar not accepted',
      format('Your %s bazar was not accepted%s', push_money(r.amount, false),
             coalesce(': ' || nullif(btrim(p_reason), ''), '')),
      '/bazar');
    return null;
  end if;

  -- The submitter already knows; the generic "new bazar" push skips them.
  perform set_config('meal_bazar.push_skip_user', coalesce(v_user::text, ''), true);
  insert into bazars (id, mess_id, date, buyer_member_id, amount, paid_by_member_id, note,
                      receipt_path, source)
  values (r.id, r.mess_id, r.date, r.buyer_ids[1], r.amount,
          case when r.own_pocket then r.member_id end, r.note, r.receipt_path, 'app');
  perform set_config('meal_bazar.push_skip_user', '', true);

  insert into bazar_items (bazar_id, mess_id, name, qty, unit, price, sort)
  select r.id, r.mess_id, left(btrim(i ->> 'name'), 60), nullif(i ->> 'qty', '')::numeric,
         nullif(left(btrim(coalesce(i ->> 'unit', '')), 12), ''), coalesce(nullif(i ->> 'price', '')::numeric, 0),
         (ord - 1)::smallint
  from jsonb_array_elements(r.items) with ordinality e(i, ord)
  where char_length(btrim(coalesce(i ->> 'name', ''))) > 0;

  insert into bazar_buyers (bazar_id, member_id)
  select r.id, b from unnest(r.buyer_ids) b
  where exists (select 1 from mess_members m where m.id = b and m.mess_id = r.mess_id);

  update bazar_requests
  set status = 'approved', bazar_id = r.id, reviewed_by = auth.uid(), reviewed_at = now()
  where id = p_id;
  perform push_enqueue(array[v_user], 'bazar_request_reviewed',
    'বাজার যোগ হয়েছে', format('আপনার %s বাজার মেসের হিসাবে যোগ হয়েছে', push_money(r.amount, true)),
    'Bazar added', format('Your %s bazar was added to the mess', push_money(r.amount, false)),
    '/bazar');
  return r.id;
end $$;

-- Managers hear about a new request.
create or replace function public.push_on_bazar_request() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_name text;
begin
  select display_name into v_name from mess_members where id = new.member_id;
  perform push_enqueue(push_mess_users(new.mess_id, 'manager', auth.uid()), 'bazar_request',
    'বাজারের হিসাব যাচাই করুন', format('%s %s এর বাজার জমা দিয়েছেন', v_name, push_money(new.amount, true)),
    'Bazar to review', format('%s submitted a %s bazar', v_name, push_money(new.amount, false)),
    '/bazar');
  return null;
end $$;
create trigger bazar_requests_push after insert on public.bazar_requests
  for each row execute function public.push_on_bazar_request();

-- The generic "new bazar" push, now also skipping the request's submitter.
create or replace function public.push_on_bazar() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_mess text;
  v_skip uuid := nullif(current_setting('meal_bazar.push_skip_user', true), '')::uuid;
begin
  if new.deleted_at is null then
    select name into v_mess from messes where id = new.mess_id;
    perform push_enqueue(array(select u from unnest(push_mess_users(new.mess_id, null, auth.uid())) u
                               where u is distinct from v_skip), 'bazar_added',
      'নতুন বাজার', format('%s: %s এর বাজার যোগ হয়েছে', v_mess, push_money(new.amount, true)),
      'New bazar', format('%s: %s bazar added', v_mess, push_money(new.amount, false)),
      '/bazar');
  end if;
  return null;
end $$;

-- ── deposit recorded by a manager → the member is told ───────────────────
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

-- ── notification inbox ───────────────────────────────────────────────────
-- Every notification is also kept here, device or not, push setting or not
-- (the setting only silences the phone). Chat has its own unread counts, so
-- message types are not copied. Kept 60 days.
create table public.notifications (
  id         bigint generated always as identity primary key,
  user_id    uuid not null,
  type       text not null,
  title      text not null,
  body       text not null,
  route      text,
  created_at timestamptz not null default now(),
  read_at    timestamptz
);
create index notifications_user_idx on public.notifications(user_id, created_at desc);
alter table public.notifications enable row level security;
create policy notifications_read on public.notifications for select using (user_id = auth.uid());

create or replace function public.mark_notifications_read(p_ids bigint[] default null) returns void
language sql security definer set search_path = public as $$
  update notifications set read_at = now()
  where user_id = auth.uid() and read_at is null and (p_ids is null or id = any (p_ids));
$$;

create or replace function public.unread_notification_count() returns int
language sql stable set search_path = public as $$
  select count(*)::int from notifications where user_id = auth.uid() and read_at is null;
$$;

-- The tagged enqueue (0023) is the one every path goes through.
create or replace function public.push_enqueue(
  p_users uuid[], p_type text, p_title_bn text, p_body_bn text, p_title_en text, p_body_en text,
  p_route text, p_tag text
) returns int
language plpgsql security definer set search_path = public as $$
declare
  n int;
begin
  if coalesce(cardinality(p_users), 0) = 0 then
    return 0;
  end if;
  if p_type not in ('message', 'group_message') then
    insert into notifications (user_id, type, title, body, route)
    select p.id, p_type,
           case when p.locale = 'en' then p_title_en else p_title_bn end,
           left(case when p.locale = 'en' then p_body_en else p_body_bn end, 240),
           p_route
    from profiles p
    where p.id = any (p_users) and p.deleted_at is null;
    delete from notifications where created_at < now() - interval '60 days';
  end if;
  if coalesce(platform_default('features', 'push'), 'true') = 'false'::jsonb then
    return 0;
  end if;
  insert into push_outbox (user_id, type, title, body, data)
  select p.id, p_type,
         case when p.locale = 'en' then p_title_en else p_title_bn end,
         left(case when p.locale = 'en' then p_body_en else p_body_bn end, 240),
         jsonb_strip_nulls(jsonb_build_object('route', p_route, 'type', p_type, 'tag', p_tag))
  from profiles p
  where p.id = any (p_users) and p.deleted_at is null
    and coalesce(p.notification_prefs ->> p_type, 'true') <> 'false'
    and exists (select 1 from device_tokens t where t.user_id = p.id);
  get diagnostics n = row_count;
  if n > 0 then
    perform push_kick();
  end if;
  return n;
end $$;
revoke execute on function public.push_enqueue(uuid[], text, text, text, text, text, text, text)
  from public, anon, authenticated;

-- ── month close: nothing may be left waiting ─────────────────────────────
-- A pending deposit or bazar request inside a closed month could never be
-- reviewed (the closed-month guard refuses the write), so closing waits.
create or replace function public.month_pending_items(p_mess uuid, p_from date, p_to date)
returns table (pending_deposits int, pending_bazar_requests int)
language sql stable security definer set search_path = public as $$
  select (select count(*)::int from deposits
          where mess_id = p_mess and deleted_at is null and status = 'pending'
            and date >= p_from and date < p_to),
         (select count(*)::int from bazar_requests
          where mess_id = p_mess and status = 'pending' and date >= p_from and date < p_to)
  where is_mess_member(p_mess);
$$;

create or replace function public.close_month(p_mess uuid, p_date date) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_from  date;
  v_to    date;
  v_month uuid;
begin
  perform require_user();
  if not has_mess_role(p_mess, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  select start_date, end_date into v_from, v_to from month_period(p_mess, p_date);

  if month_is_closed(p_mess, v_from) then
    perform fail('MONTH_CLOSED');
  end if;
  -- Months close in order: earlier activity must be covered by a closed month ending here.
  if not exists (select 1 from months where mess_id = p_mess and status = 'closed' and end_date = v_from)
     and (exists (select 1 from meal_entries where mess_id = p_mess and date < v_from)
          or exists (select 1 from bazars where mess_id = p_mess and deleted_at is null and date < v_from)
          or exists (select 1 from expenses where mess_id = p_mess and deleted_at is null and date < v_from)
          or exists (select 1 from deposits where mess_id = p_mess and deleted_at is null and date < v_from)) then
    perform fail('PREVIOUS_MONTH_OPEN');
  end if;
  if exists (select 1 from month_pending_items(p_mess, v_from, v_to)
             where pending_deposits + pending_bazar_requests > 0) then
    perform fail('PENDING_ITEMS');
  end if;

  insert into months (mess_id, start_date, end_date, status, closed_at, closed_by)
  values (p_mess, v_from, v_to, 'closed', now(), auth.uid())
  on conflict (mess_id, start_date)
    do update set status = 'closed', closed_at = now(), closed_by = auth.uid()
  returning id into v_month;

  delete from month_member_summary where month_id = v_month;
  insert into month_member_summary
    (month_id, mess_id, member_id, meals, food_cost, extra_cost, credit, opening_balance, closing_balance)
  select v_month, p_mess, b.member_id, b.meals, b.food_cost, b.extra_cost, b.credit,
         b.opening_balance, b.closing_balance
  from member_balances(p_mess, v_from, v_to) b;

  insert into audit_log (mess_id, actor_id, action, entity, entity_id, new)
  values (p_mess, auth.uid(), 'close_month', 'months', v_month,
          jsonb_build_object('start_date', v_from, 'end_date', v_to));
  return v_month;
end $$;

-- ── the caller's previous month, for Home ────────────────────────────────
-- The period before the one containing today (Dhaka). status 'open' when no
-- months row exists yet. The money columns are the caller's own closed
-- snapshot (null while the month is open). No row when that period had no
-- activity at all (a brand-new mess).
create or replace function public.my_last_month(p_mess uuid)
returns table (start_date date, end_date date, status public.month_status, closed_at timestamptz,
               meals numeric, food_cost numeric, extra_cost numeric, credit numeric,
               opening_balance numeric, closing_balance numeric)
language sql stable set search_path = public as $$
  with cur as (select * from month_period(p_mess, (now() at time zone 'Asia/Dhaka')::date)),
       prev as (select p.* from cur, month_period(p_mess, cur.start_date - 1) p)
  select prev.start_date, prev.end_date, coalesce(mo.status, 'open'), mo.closed_at,
         s.meals, s.food_cost, s.extra_cost, s.credit, s.opening_balance, s.closing_balance
  from prev
  left join months mo on mo.mess_id = p_mess and mo.start_date = prev.start_date
  left join mess_members me on me.mess_id = p_mess and me.user_id = auth.uid()
  left join month_member_summary s on s.month_id = mo.id and s.member_id = me.id
                                  and mo.status = 'closed'
  where is_mess_member(p_mess)
    and (mo.status = 'closed'
         or exists (select 1 from meal_entries e where e.mess_id = p_mess
                    and e.date >= prev.start_date and e.date < prev.end_date)
         or exists (select 1 from bazars b where b.mess_id = p_mess and b.deleted_at is null
                    and b.date >= prev.start_date and b.date < prev.end_date))
  limit 1;
$$;

-- ── manager attention, now with bazar requests ───────────────────────────
drop function public.manager_attention(uuid, date);
create function public.manager_attention(p_mess uuid, p_date date)
returns table (pending_deposits int, pending_members int, meals_missing int, pending_recurring int,
               pending_bazar_requests int)
language sql stable set search_path = public as $$
  select
    (select count(*)::int from deposits d
     where d.mess_id = p_mess and d.deleted_at is null and d.status = 'pending'),
    (select count(*)::int from mess_members m
     where m.mess_id = p_mess and m.status = 'pending'),
    (select count(*)::int from mess_members m
     where m.mess_id = p_mess and m.status = 'active' and is_present(m, p_date)
       and not exists (select 1 from meal_entries e
                       where e.member_id = m.id and e.date = p_date)),
    pending_recurring_count(p_mess, p_date),
    (select count(*)::int from bazar_requests r
     where r.mess_id = p_mess and r.status = 'pending')
  where is_mess_member(p_mess);
$$;

