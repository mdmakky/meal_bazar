-- 0030: (1) the audit log keeps only what settles disputes: meals, bazars,
-- expenses, deposits, members, mess settings and month close/reopen.
-- (2) Automatic due reminders: a member whose balance is below zero gets one
-- of the manager's own messages, picked at random, in their message thread
-- (and as a push), every N days. Contract: DATABASE.md "Due reminders (0030)".

-- ── (1) leaner audit ─────────────────────────────────────────────────────
drop trigger if exists bazar_items_audit on public.bazar_items;
drop trigger if exists bazar_buyers_audit on public.bazar_buyers;
drop trigger if exists meal_types_audit on public.meal_types;
drop trigger if exists expense_categories_audit on public.expense_categories;
drop trigger if exists recurring_expenses_audit on public.recurring_expenses;
drop trigger if exists announcements_audit on public.announcements;
drop trigger if exists bazar_duties_audit on public.bazar_duties;
drop trigger if exists bazar_requests_audit on public.bazar_requests;
delete from public.audit_log
where entity in ('bazar_items', 'bazar_buyers', 'meal_types', 'expense_categories',
                 'recurring_expenses', 'announcements', 'bazar_duties', 'bazar_requests');

-- ── (2) due reminders ────────────────────────────────────────────────────
-- Null every = off. Only dues above min_due are reminded.
alter table public.messes
  add column due_reminder_every smallint check (due_reminder_every between 1 and 30),
  add column due_reminder_min   numeric(12,2) not null default 0 check (due_reminder_min >= 0),
  add column due_reminder_last  date;

-- The manager's texts. {name}, {amount} and {mess} are filled in.
create table public.due_reminder_texts (
  id         uuid primary key default gen_random_uuid(),
  mess_id    uuid not null references public.messes(id) on delete cascade,
  body       text not null check (char_length(btrim(body)) between 1 and 300),
  created_at timestamptz not null default now()
);
create index due_reminder_texts_mess_idx on public.due_reminder_texts(mess_id);
create trigger due_reminder_texts_suspension before insert or update or delete on public.due_reminder_texts
  for each row execute function public.guard_suspension();
alter table public.due_reminder_texts enable row level security;
create policy due_reminder_texts_all on public.due_reminder_texts for all
  using (has_mess_role(mess_id, 'manager')) with check (has_mess_role(mess_id, 'manager'));

create or replace function public.fill_due_text(p_body text, p_name text, p_due numeric, p_mess text)
returns text language sql immutable as $$
  select left(replace(replace(replace(p_body, '{name}', coalesce(p_name, '')),
                              '{amount}', push_money(p_due, true)), '{mess}', coalesce(p_mess, '')), 500);
$$;

-- Run by the daily cron (service role). For every mess whose reminder is due
-- today: each active app member with a balance below −min_due gets a random
-- text of the mess in their "বকেয়া" thread, posted as a system message
-- (the message push follows). Returns the number of members reminded.
create or replace function public.send_auto_due_reminders() returns int
language plpgsql security definer set search_path = public as $$
declare
  v_today  date := (now() at time zone 'Asia/Dhaka')::date;
  ms       record;
  r        record;
  v_from   date;
  v_to     date;
  v_body   text;
  v_thread uuid;
  n        int := 0;
begin
  if coalesce(platform_default('features', 'due_reminders'), 'true') = 'false'::jsonb
     or coalesce(platform_default('features', 'messages'), 'true') = 'false'::jsonb then
    return 0;
  end if;
  for ms in
    select * from messes
    where due_reminder_every is not null and suspended_at is null
      and (due_reminder_last is null or v_today - due_reminder_last >= due_reminder_every)
  loop
    select start_date, end_date into v_from, v_to from month_period(ms.id, v_today);
    for r in
      select m.id as member, m.display_name, -b.closing_balance as due
      from member_balances(ms.id, v_from, v_to) b
      join mess_members m on m.id = b.member_id
      where b.closing_balance < -ms.due_reminder_min and m.status = 'active' and m.user_id is not null
    loop
      select body into v_body from due_reminder_texts where mess_id = ms.id order by random() limit 1;
      v_body := fill_due_text(coalesce(v_body,
        '{name}, আপনার বকেয়া {amount}। অনুগ্রহ করে তাড়াতাড়ি জমা দিন।'), r.display_name, r.due, ms.name);
      select id into v_thread from message_threads
      where member_id = r.member and kind = 'direct' and created_by is null
        and subject = 'বকেয়া রিমাইন্ডার';
      if v_thread is null then
        insert into message_threads (mess_id, member_id, subject, created_by)
        values (ms.id, r.member, 'বকেয়া রিমাইন্ডার', null)
        returning id into v_thread;
      end if;
      insert into messages (thread_id, mess_id, sender_id, body, kind, meta)
      values (v_thread, ms.id, null, v_body, 'system',
              jsonb_build_object('t', 'due_reminder', 'amount', r.due));
      update message_threads set last_message_at = now(), status = 'open' where id = v_thread;
      n := n + 1;
    end loop;
    update messes set due_reminder_last = v_today where id = ms.id;
  end loop;
  return n;
end $$;
revoke execute on function public.send_auto_due_reminders() from public, anon, authenticated;
grant execute on function public.send_auto_due_reminders() to service_role;
