-- Demo mess for manual feature testing. Run once against a project:
--   npx supabase db query --linked -f supabase/seed_demo.sql
-- Logins (password MealBazar@2026):
--   demo.manager@mealbazar.app  (manager)   demo.member@mealbazar.app  (member)
-- Data: Aug + Sep 2026 closed, Oct 2026 open up to today.
do $$
declare
  pw      text := 'MealBazar@2026';
  u_mgr   uuid := 'd0000000-0000-4000-a000-000000000001';
  u_mem   uuid := 'd0000000-0000-4000-a000-000000000002';
  v_mess  uuid := 'd0000000-0000-4000-b000-000000000001';
  m       uuid[];           -- member ids
  v_from  date := date '2026-08-01';
  v_today date := current_date;
  d       date;
  mid     uuid;
  t       record;
  b       uuid;
  e       uuid;
  i       int;
  items   text[][] := array[
    ['চাল','কেজি','70'],['মসুর ডাল','কেজি','120'],['সয়াবিন তেল','লিটার','185'],['আলু','কেজি','45'],
    ['পেঁয়াজ','কেজি','90'],['রসুন','কেজি','220'],['ডিম','হালি','52'],['মুরগি','কেজি','195'],
    ['রুই মাছ','কেজি','340'],['সবজি','কেজি','60'],['কাঁচা মরিচ','কেজি','160'],['লবণ','কেজি','40'],
    ['গরুর মাংস','কেজি','780'],['আটা','কেজি','60']];
  cat     record;
begin
  if exists (select 1 from auth.users where email = 'demo.manager@mealbazar.app') then
    raise exception 'demo already seeded';
  end if;
  perform setseed(0.42);

  -- auth users + identities
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                          confirmation_token, email_change, email_change_token_new, recovery_token)
  select '00000000-0000-0000-0000-000000000000', x.id, 'authenticated', 'authenticated', x.email,
         extensions.crypt(pw, extensions.gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}', jsonb_build_object('full_name', x.name),
         now(), now(), '', '', '', ''
  from (values (u_mgr, 'demo.manager@mealbazar.app', 'রাকিব হাসান'),
               (u_mem, 'demo.member@mealbazar.app', 'তানভীর আহমেদ')) x(id, email, name);
  insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  select gen_random_uuid(), u.id, u.id::text,
         jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true), 'email', now(), now(), now()
  from auth.users u where u.id in (u_mgr, u_mem);
  update profiles set full_name = 'রাকিব হাসান' where id = u_mgr;
  update profiles set full_name = 'তানভীর আহমেদ' where id = u_mem;

  -- act as the manager for RPCs, audit rows and defaults
  perform set_config('request.jwt.claims', jsonb_build_object('sub', u_mgr, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', u_mgr::text, true);
  perform set_config('meal_bazar.trusted', 'on', true);

  insert into messes (id, name, address, month_start_day, created_by)
  values (v_mess, 'শান্তিনীড় ছাত্রাবাস', 'বাড়ি ১২, রোড ৫, মিরপুর-১০, ঢাকা', 1, u_mgr);
  update meal_types set enabled = true where mess_id = v_mess;

  insert into mess_members (mess_id, user_id, display_name, role, status, joined_on, left_on, room) values
    (v_mess, u_mgr, 'রাকিব', 'manager', 'active', v_from, null, '101'),
    (v_mess, u_mem, 'তানভীর', 'member', 'active', v_from, null, '101'),
    (v_mess, null, 'সাকিব', 'member', 'active', v_from, null, '102'),
    (v_mess, null, 'ফাহিম', 'member', 'active', v_from, null, '102'),
    (v_mess, null, 'নাঈম', 'member', 'active', v_from, null, '103'),
    (v_mess, null, 'জুবায়ের', 'member', 'left', v_from, date '2026-09-30', '103'),
    (v_mess, null, 'আরিফ', 'member', 'active', date '2026-09-15', null, '103');
  select array_agg(id order by joined_on, display_name) into m from mess_members where mess_id = v_mess;

  -- meals: every present member, every meal type, every day
  d := v_from;
  while d <= v_today loop
    for t in select id, name from meal_types where mess_id = v_mess order by sort_order loop
      insert into meal_entries (mess_id, member_id, meal_type_id, date, count, guest_count, is_off)
      select v_mess, mm.id, t.id, d,
             case when r < 0.10 then 0 when r < 0.16 then 0.5 when r > 0.97 then 2 else 1 end,
             case when random() < 0.04 then 1 else 0 end,
             r < 0.10
      from mess_members mm, lateral (select random() + case when t.name = 'সকাল' then -0.15 else 0 end as r) z
      where mm.mess_id = v_mess and mm.joined_on <= d and (mm.left_on is null or d < mm.left_on)
        and (t.name <> 'সকাল' or random() < 0.75);
    end loop;
    d := d + 1;
  end loop;
  update meal_entries set count = 0 where mess_id = v_mess and is_off;
  update meal_entries set count = 0 where mess_id = v_mess and count < 0;

  -- bazar every 2nd/3rd day, rotating buyer, itemised
  d := v_from; i := 0;
  while d <= v_today loop
    mid := m[1 + (i % 5)];
    b := gen_random_uuid();
    insert into bazars (id, mess_id, date, buyer_member_id, amount, paid_by_member_id, note)
    values (b, v_mess, d, mid, 0, case when i % 4 = 3 then mid end,
            case when i % 6 = 0 then 'সাপ্তাহিক বড় বাজার' end);
    insert into bazar_items (bazar_id, mess_id, name, qty, unit, price, sort)
    select b, v_mess, items[k][1], q, items[k][2], round(q * items[k][3]::numeric * (0.95 + random() * 0.1)::numeric, 0), s
    from (select k, row_number() over () s, (1 + floor(random() * 4))::numeric q
          from (select distinct 1 + floor(random() * 14)::int k from generate_series(1, 7)) kk) x;
    update bazars set amount = (select sum(price) from bazar_items where bazar_id = b) where id = b;
    d := d + 2 + (i % 2); i := i + 1;
  end loop;

  -- monthly bills for Aug + Sep (Oct left for "post this month's bills")
  for d in select generate_series(v_from, date '2026-09-01', interval '1 month')::date loop
    for cat in select id, name from expense_categories where mess_id = v_mess loop
      insert into expenses (mess_id, date, category_id, amount, split, note, source)
      select v_mess, d + x.day, cat.id, x.amt, 'equal', x.note, 'system'
      from (values ('বাসা ভাড়া', 0, 21000, 'মাসিক ভাড়া'), ('বিদ্যুৎ', 9, 1850, 'বিদ্যুৎ বিল'),
                   ('গ্যাস', 4, 1080, 'দুই চুলা'), ('ওয়াইফাই', 1, 1000, '৩০ Mbps'),
                   ('বুয়া', 0, 4500, 'রান্নার বুয়া'), ('পানি', 9, 400, null)) x(name, day, amt, note)
      where x.name = cat.name;
    end loop;
  end loop;
  -- shared cost among selected members (AC repair in rooms 101/102)
  e := gen_random_uuid();
  insert into expenses (id, mess_id, date, category_id, amount, split, paid_by_member_id, note)
  select e, v_mess, date '2026-09-20', id, 1500, 'equal', m[1], 'রুম ১০১-১০২ ফ্যান মেরামত'
  from expense_categories where mess_id = v_mess and name = 'মেরামত';
  insert into expense_shares (expense_id, mess_id, member_id, weight)
  values (e, v_mess, m[1], 1), (e, v_mess, m[2], 1), (e, v_mess, m[3], 2), (e, v_mess, m[4], 1);
  insert into expenses (mess_id, date, category_id, amount, split, note)
  select v_mess, date '2026-10-03', id, 350, 'equal', 'ঝাড়ু, হারপিক, সাবান'
  from expense_categories where mess_id = v_mess and name = 'পরিষ্কার';

  -- deposits: two per member per month
  for d in select generate_series(v_from, date '2026-10-01', interval '1 month')::date loop
    insert into deposits (mess_id, member_id, date, amount, method, trx_id, status)
    select v_mess, mm.id, d + off,
           (case when off = 1 then 6000 else 3000 end + 500 * floor(random() * 3))::numeric,
           (array['cash','bkash','nagad','cash']::pay_method[])[1 + floor(random() * 4)::int],
           case when random() < 0.5 then upper(substr(md5(random()::text), 1, 10)) end, 'verified'
    from mess_members mm, (values (1), (14)) o(off)
    where mm.mess_id = v_mess and mm.joined_on <= d + off and (mm.left_on is null or d + off < mm.left_on)
      and d + off <= v_today;
  end loop;
  insert into deposits (mess_id, member_id, date, amount, method, trx_id, status, note)
  values (v_mess, m[2], v_today, 2000, 'bkash', 'BK7Q2X9LMA', 'pending', 'বিকাশে পাঠিয়েছি');

  -- close Aug and Sep (snapshots + carry-forward)
  perform close_month(v_mess, date '2026-08-15');
  perform close_month(v_mess, date '2026-09-15');

  -- recurring templates (Aug/Sep marked posted)
  insert into recurring_expenses (mess_id, category_id, amount, split, note, day_of_period)
  select v_mess, c.id, x.amt, 'equal', x.note, x.day
  from expense_categories c
  join (values ('বাসা ভাড়া', 1, 21000, 'মাসিক ভাড়া'), ('ওয়াইফাই', 2, 1000, '৩০ Mbps'),
               ('বুয়া', 1, 4500, 'রান্নার বুয়া')) x(name, day, amt, note) on x.name = c.name
  where c.mess_id = v_mess;
  insert into recurring_applied (recurring_id, period_start, mess_id)
  select r.id, p, v_mess from recurring_expenses r, (values (date '2026-08-01'), (date '2026-09-01')) pp(p)
  where r.mess_id = v_mess;

  -- meal defaults: সাকিব skips breakfast, নাঈম eats double dinner
  insert into meal_defaults (member_id, meal_type_id, mess_id, count)
  select m[3], id, v_mess, 0 from meal_types where mess_id = v_mess and name = 'সকাল'
  union all
  select m[5], id, v_mess, 2 from meal_types where mess_id = v_mess and name = 'রাত';

  -- notices
  insert into announcements (mess_id, title, body, pinned, created_at) values
    (v_mess, 'অক্টোবরের ভাড়া ৫ তারিখের মধ্যে', 'সবাই ৫ অক্টোবরের মধ্যে ভাড়ার টাকা জমা দিন। বিকাশ: 01700-000000', true, now() - interval '6 days'),
    (v_mess, 'শুক্রবার বিশেষ খাবার', 'এই শুক্রবার দুপুরে বিরিয়ানি। গেস্ট আনলে আগে জানাবেন।', false, now() - interval '1 day');

  -- bazar duty rotation for the rest of the month
  insert into bazar_duties (mess_id, date, member_id, done)
  select v_mess, dd::date, m[1 + (n % 5)], dd::date < v_today
  from generate_series(v_today - 6, v_today + 14, interval '2 days') with ordinality g(dd, n);

  insert into mess_invites (mess_id, code, created_by, expires_at)
  values (v_mess, 'DEMO26', u_mgr, now() + interval '30 days');
end $$;

select mm.display_name, b.*
from member_balances('d0000000-0000-4000-b000-000000000001', '2026-09-01', '2026-10-01') b
join mess_members mm on mm.id = b.member_id;
