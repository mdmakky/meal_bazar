-- Member bazar requests (submit, idempotent, approve → real bazar + items +
-- buyers, reject, cancel, RLS), the notification inbox, the manager-recorded
-- deposit push, close_month refusing pending items, my_last_month.
\set M '''26260000-0000-0000-0000-00000000000a'''
\set R '''26260000-0000-0000-0000-00000000000b'''
\set K '''26260000-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:R), (:K);

select test.act_as(:M);
select create_mess('Request Mess', 'Manager') as mess \gset
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'Rahim') returning id as rahim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :K, 'Karim') returning id as karim \gset
select set_config('meal_bazar.trusted', '', false);
update mess_members set joined_on = current_date - 70 where mess_id = :'mess';
insert into device_tokens (token, user_id, platform) values ('tok-req-mgr-0001', :M, 'android'),
  ('tok-req-rahim-01', :R, 'android');
select (now() at time zone 'Asia/Dhaka')::date as today \gset

-- ── submit ───────────────────────────────────────────────────────────────
select test.act_as(:R);
select submit_bazar_request(:'mess', '26260000-0000-0000-0000-0000000000b1', :'today', 450, true,
  array[:'karim'::uuid, :'karim'::uuid, '26260000-0000-0000-0000-0000000000ff'::uuid],
  '[{"name":"চাল","qty":"5","unit":"kg","price":"350"},{"name":"ডিম","price":"100"},{"name":" "}]',
  ' bazar ', null);
-- Offline retry: no second row, no second push.
select submit_bazar_request(:'mess', '26260000-0000-0000-0000-0000000000b1', :'today', 450, true,
  null, '[]', null, null);
select test.check((select count(*) = 1 and bool_and(buyer_ids = array[:'rahim'::uuid, :'karim'::uuid])
                          and bool_and(note = 'bazar' and status = 'pending')
                   from bazar_requests), 'one request, submitter first, unknown buyers dropped');
select test.expect_error(format($$select submit_bazar_request(%L, gen_random_uuid(), %L, 10, true, null, '[]', null, null)$$,
                                :'mess', (:'today'::date + 1)), 'FUTURE_DATE');
select test.expect_error(format($$select submit_bazar_request(%L, gen_random_uuid(), %L, 0, true, null, '[]', null, null)$$,
                                :'mess', :'today'), 'check');
select test.expect_error($$insert into bazar_requests (id, mess_id, member_id, date, amount)
  values (gen_random_uuid(), (select id from messes where name = 'Request Mess'),
          (select id from mess_members where display_name = 'Rahim'), current_date, 5)$$, 'row-level security');
-- Karim (a companion, not the submitter) cannot see it; the manager can.
select test.act_as(:K);
select test.check((select count(*) from bazar_requests) = 0, 'other members do not see the request');
select test.expect_error($$select review_bazar_request('26260000-0000-0000-0000-0000000000b1', true)$$, 'NOT_MANAGER');
select test.act_as(:M);
select test.check((select count(*) from bazar_requests) = 1, 'manager sees it');
select test.check((select pending_bazar_requests = 1 from manager_attention(:'mess', :'today')), 'attention counts it');
select test.act_as(null);
select test.check((select count(*) = 1 from push_outbox where user_id = :M and type = 'bazar_request'
                   and body = 'Rahim ৳৪৫০ এর বাজার জমা দিয়েছেন'), 'manager pushed once');

-- ── close waits for it ───────────────────────────────────────────────────
select test.act_as(:M);
select test.expect_error(format($$select close_month(%L, %L)$$, :'mess', :'today'), 'PENDING_ITEMS');
select test.check((select pending_bazar_requests = 1 and pending_deposits = 0
                   from month_pending_items(:'mess', :'today'::date - 40, :'today'::date + 40)), 'pending items listed');

-- ── approve ──────────────────────────────────────────────────────────────
select test.act_as(null);
delete from push_outbox;
select test.act_as(:M);
select review_bazar_request('26260000-0000-0000-0000-0000000000b1', true);
select test.check((select amount = 450 and paid_by_member_id = :'rahim' and buyer_member_id = :'rahim' and note = 'bazar'
                   from bazars where id = '26260000-0000-0000-0000-0000000000b1'), 'real bazar, own pocket → Rahim credited');
select test.check((select count(*) = 2 and sum(price) = 450 and bool_or(name = 'চাল' and qty = 5 and unit = 'kg')
                   from bazar_items where bazar_id = '26260000-0000-0000-0000-0000000000b1'), 'items copied, blank skipped');
select test.check((select array_agg(member_id order by member_id) = array_agg(x order by x)
                   from bazar_buyers, unnest(array[:'rahim'::uuid, :'karim'::uuid]) x
                   where bazar_id = '26260000-0000-0000-0000-0000000000b1' and member_id = x), 'both buyers');
select test.check((select status = 'approved' and bazar_id is not null from bazar_requests), 'request approved');
select test.expect_error($$select review_bazar_request('26260000-0000-0000-0000-0000000000b1', true)$$, 'BAZAR_REQUEST_NOT_PENDING');
select test.act_as(null);
select test.check((select count(*) = 1 from push_outbox where user_id = :R and type = 'bazar_request_reviewed')
                  and not exists (select 1 from push_outbox where user_id = :R and type = 'bazar_added'),
                  'submitter gets the outcome, not the generic push');
select test.check((select credit = 450 from member_balances(:'mess', :'today'::date - 40, :'today'::date + 40)
                   where member_id = :'rahim'), 'counts in the balance');

-- ── reject and cancel ────────────────────────────────────────────────────
select test.act_as(:R);
select submit_bazar_request(:'mess', '26260000-0000-0000-0000-0000000000b2', :'today', 90, false, null, '[]', null, null);
select submit_bazar_request(:'mess', '26260000-0000-0000-0000-0000000000b3', :'today', 30, true, null, '[]', null, null);
select cancel_bazar_request('26260000-0000-0000-0000-0000000000b3');
select test.expect_error($$select cancel_bazar_request('26260000-0000-0000-0000-0000000000b3')$$, 'BAZAR_REQUEST_NOT_PENDING');
select test.act_as(:M);
select review_bazar_request('26260000-0000-0000-0000-0000000000b2', false, 'রসিদ নেই');
select test.check((select status = 'rejected' and reject_reason = 'রসিদ নেই' from bazar_requests
                   where id = '26260000-0000-0000-0000-0000000000b2'), 'rejected with reason');
select test.check(not exists (select 1 from bazars where id in ('26260000-0000-0000-0000-0000000000b2',
                                                              '26260000-0000-0000-0000-0000000000b3')), 'no bazar for those');

-- ── inbox ────────────────────────────────────────────────────────────────
select test.act_as(:R);
select test.check((select count(*) from notifications) = 2, 'Rahim: approved + rejected in the inbox');
select test.check(unread_notification_count() = 2, 'both unread');
select test.check((select body from notifications order by id desc limit 1)
                  = 'আপনার ৳৯০ বাজার গ্রহণ করা হয়নি: রসিদ নেই', 'reject text with reason');
select mark_notifications_read(array[(select min(id) from notifications)]);
select test.check(unread_notification_count() = 1, 'mark one');
select mark_notifications_read();
select test.check(unread_notification_count() = 0, 'mark all');
select test.act_as(:K);
select test.check((select count(*) from notifications where user_id = :R) = 0, 'others never see my inbox');
select test.check((select count(*) from notifications where type = 'bazar_added') = 1, 'Karim has no device but keeps the inbox row');

-- ── deposit recorded by the manager ──────────────────────────────────────
select test.act_as(:M);
insert into deposits (mess_id, member_id, date, amount, method, status)
values (:'mess', :'rahim', :'today', 500, 'cash', 'verified');
insert into deposits (mess_id, member_id, date, amount, method, status)
values (:'mess', :'mgr', :'today', 100, 'cash', 'verified');   -- own: no push
select test.act_as(null);
select test.check((select count(*) = 1 from push_outbox where user_id = :R and type = 'deposit_added'
                   and body = 'আপনার নামে ৳৫০০ জমা যোগ করা হয়েছে'), 'member told about the deposit');
select test.check(not exists (select 1 from push_outbox where user_id = :M and type = 'deposit_added'), 'not the actor');

-- ── my_last_month ────────────────────────────────────────────────────────
select test.act_as(:R);
select test.check((select count(*) from my_last_month(:'mess')) = 0, 'nothing for a new mess');
select test.act_as(:M);
select start_date as prev_from from month_period(:'mess', (select start_date - 1 from month_period(:'mess', :'today'))) \gset
insert into meal_entries (mess_id, member_id, meal_type_id, date, count)
select :'mess', :'rahim', id, :'prev_from', 1 from meal_types where mess_id = :'mess' limit 1;
select test.act_as(:R);
select test.check((select status = 'open' and closing_balance is null and start_date = :'prev_from'
                   from my_last_month(:'mess')), 'open last month, no snapshot yet');
select test.act_as(:M);
select close_month(:'mess', :'prev_from');
select test.act_as(:R);
select test.act_as(:R);
select test.check((select status = 'closed' and meals > 0 and closing_balance is not null
                   from my_last_month(:'mess')), 'closed: my own snapshot');
-- Nothing may be added to the closed month, by anyone.
select test.expect_error(format($$select submit_bazar_request(%L, gen_random_uuid(), %L, 10, true, null, '[]', null, null)$$,
                                :'mess', :'prev_from'), 'MONTH_CLOSED');
select test.expect_error(format($$select record_my_deposit(%L, gen_random_uuid(), %L, 10, 'cash', null, null, null)$$,
                                :'mess', :'prev_from'), 'MONTH_CLOSED');
