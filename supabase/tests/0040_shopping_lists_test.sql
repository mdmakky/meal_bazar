select set_config('meal_bazar.today', '2099-12-31', false);
-- The bazar list: planned, assigned, ticked with prices, submitted, reviewed.
\set M '''40400000-0000-0000-0000-00000000000a'''
\set R '''40400000-0000-0000-0000-00000000000b'''
\set K '''40400000-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:R), (:K);
select test.act_as(:M);
select create_mess('List Mess', 'Manager') as mess \gset
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'Rahim') returning id as rahim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :K, 'Karim') returning id as karim \gset
select set_config('meal_bazar.trusted', '', false);
update mess_members set joined_on = current_date - 70 where mess_id = :'mess';
insert into device_tokens (token, user_id, platform) values ('tok-list-mgr-0001', :M, 'android'), ('tok-list-rahim-01', :R, 'android'), ('tok-list-karim-01', :K, 'android');
select set_config('meal_bazar.today', '', false);
select (now() at time zone 'Asia/Dhaka')::date as today \gset

-- ── a manager plans a list and sends Rahim ───────────────────────────────
select test.act_as(:M);
select save_shopping_list('40400000-0000-0000-0000-0000000000a1', :'mess', :'today', 'Friday', null, :'rahim');
insert into shopping_items (id, list_id, name, qty, unit, sort) values
  ('40400000-0000-0000-0000-0000000000b1', '40400000-0000-0000-0000-0000000000a1', 'চাল', 5, 'kg', 1),
  ('40400000-0000-0000-0000-0000000000b2', '40400000-0000-0000-0000-0000000000a1', 'ডিম', 2, 'dozen', 2);
select test.act_as(null);
select test.check((select count(*) = 1 from push_outbox where user_id = :R and type = 'shopping_assigned'
                   and data ->> 'route' = '/bazar/list/40400000-0000-0000-0000-0000000000a1'), 'Rahim is told');
select test.act_as(:K);
select test.check((select count(*) = 0 from shopping_lists), 'Karim cannot see it');
select test.check((select count(*) = 0 from shopping_items), '…nor its items');
select test.expect_error($$select save_shopping_list(gen_random_uuid(), (select id from messes where name = 'List Mess'), current_date, null, null,
  (select id from mess_members where display_name = 'Rahim'))$$, 'NOT_MANAGER');

-- ── Rahim shops: ticks, prices, an extra, submits ────────────────────────
select test.act_as(:R);
select test.check((select count(*) = 1 from shopping_lists), 'Rahim sees his list');
update shopping_items set bought = true, price = 600 where id = '40400000-0000-0000-0000-0000000000b1';
update shopping_items set bought = true, price = 220 where id = '40400000-0000-0000-0000-0000000000b2';
insert into shopping_items (id, list_id, name, extra, bought, price, sort)
values ('40400000-0000-0000-0000-0000000000b3', '40400000-0000-0000-0000-0000000000a1', 'কাঁচা মরিচ', true, true, 30, 3);
select submit_shopping_list('40400000-0000-0000-0000-0000000000a1', true);
select test.act_as(null);
select test.check((select status = 'submitted' from shopping_lists), 'list is submitted');
select request_id as req1 from shopping_lists where id = '40400000-0000-0000-0000-0000000000a1' \gset
select test.check((select status = 'pending' and amount = 850 and member_id = :'rahim' and jsonb_array_length(items) = 3
                   from bazar_requests where id = :'req1'), 'a pending bazar request of 850 with 3 items');
select test.check((select count(*) = 1 from push_outbox where user_id = :M and type = 'bazar_request'), 'the manager is told');
-- while submitted nobody edits it
select test.act_as(:R);
update shopping_items set price = 1 where id = '40400000-0000-0000-0000-0000000000b1';
select test.act_as(null);
select test.check((select price = 600 from shopping_items where id = '40400000-0000-0000-0000-0000000000b1'), 'no edits while submitted');

-- ── the manager rejects, the list reopens, then approves ─────────────────
select test.act_as(:M);
select review_bazar_request(:'req1', false, 'দাম ভুল');
select test.act_as(null);
select test.check((select status = 'open' and reject_reason = 'দাম ভুল' from shopping_lists), 'rejected: back to open with the reason');
select test.act_as(:R);
update shopping_items set price = 580 where id = '40400000-0000-0000-0000-0000000000b1';
select submit_shopping_list('40400000-0000-0000-0000-0000000000a1', true);
select test.act_as(null);
select request_id as req2 from shopping_lists where id = '40400000-0000-0000-0000-0000000000a1' \gset
select test.check(:'req2' <> :'req1', 'a fresh request after the rejection');
select test.act_as(:M);
select review_bazar_request(:'req2', true);
select test.act_as(null);
select test.check((select status = 'done' from shopping_lists), 'approved: done');
select test.check((select amount = 830 and paid_by_member_id = :'rahim' from bazars where id = :'req2'), 'the real bazar, Rahim paid');
select test.check((select count(*) = 3 from bazar_items where bazar_id = :'req2'), 'with its items');

-- ── a member plans their own list; a manager's own list is instant ───────
select test.act_as(:K);
select save_shopping_list('40400000-0000-0000-0000-0000000000a2', :'mess', :'today', null, null, null);
insert into shopping_items (id, list_id, name, qty, unit, bought, price) values
  ('40400000-0000-0000-0000-0000000000c1', '40400000-0000-0000-0000-0000000000a2', 'আলু', 3, 'kg', true, 90);
select submit_shopping_list('40400000-0000-0000-0000-0000000000a2', true);
select test.act_as(null);
select test.check((select status = 'submitted' from shopping_lists where id = '40400000-0000-0000-0000-0000000000a2'), 'a member list waits for the manager');
select test.act_as(:M);
select save_shopping_list('40400000-0000-0000-0000-0000000000a3', :'mess', :'today', null, null, null);
insert into shopping_items (id, list_id, name, bought, price) values
  ('40400000-0000-0000-0000-0000000000d1', '40400000-0000-0000-0000-0000000000a3', 'তেল', true, 410);
select submit_shopping_list('40400000-0000-0000-0000-0000000000a3', false);
select test.act_as(null);
select request_id as req3 from shopping_lists where id = '40400000-0000-0000-0000-0000000000a3' \gset
select test.check((select status = 'done' from shopping_lists where id = '40400000-0000-0000-0000-0000000000a3')
                  and exists (select 1 from bazars where id = :'req3' and amount = 410 and paid_by_member_id is null),
                  'a manager list becomes the bazar at once (from the fund)');

-- ── a manager changes their mind: revoke, send to someone else, take it back ──
select test.act_as(:M);
select save_shopping_list('40400000-0000-0000-0000-0000000000a5', :'mess', :'today', null, null, :'rahim');
select test.act_as(null);
delete from push_outbox;
select test.act_as(:M);
select save_shopping_list('40400000-0000-0000-0000-0000000000a5', :'mess', :'today', null, null, :'karim');
select test.act_as(null);
select test.check((select count(*) = 1 from push_outbox where user_id = :R and title = 'বাজারের তালিকা সরানো হয়েছে'), 'Rahim is told it was taken back');
select test.check((select count(*) = 1 from push_outbox where user_id = :K and type = 'shopping_assigned' and title = 'বাজারের তালিকা'), 'Karim is told it is his');
select test.act_as(:R);
select test.check((select count(*) = 0 from shopping_lists where id = '40400000-0000-0000-0000-0000000000a5'), 'Rahim no longer sees it');
select test.act_as(:K);
select test.check((select count(*) = 1 from shopping_lists where id = '40400000-0000-0000-0000-0000000000a5'), 'Karim sees it');
select test.act_as(:M);
select save_shopping_list('40400000-0000-0000-0000-0000000000a5', :'mess', :'today', null, null, :'mgr');
select test.act_as(null);
select test.check((select assignee_id is null and created_by = :'mgr' from shopping_lists where id = '40400000-0000-0000-0000-0000000000a5'), 'taken back by its own maker: no assignee');
select test.act_as(:K);
select test.check((select count(*) = 0 from shopping_lists where id = '40400000-0000-0000-0000-0000000000a5'), 'Karim lost it');

-- nothing ticked with a price cannot be submitted
select test.act_as(:M);
select save_shopping_list('40400000-0000-0000-0000-0000000000a4', :'mess', :'today', null, null, null);
select test.expect_error($$select submit_shopping_list('40400000-0000-0000-0000-0000000000a4')$$, 'ITEMS_INVALID');
select cancel_shopping_list('40400000-0000-0000-0000-0000000000a4');
select test.act_as(null);
select test.check((select status = 'cancelled' from shopping_lists where id = '40400000-0000-0000-0000-0000000000a4'), 'cancelled');
