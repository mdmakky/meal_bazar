select set_config('meal_bazar.today', '2099-12-31', false);
-- Corrections are announced: bazar / shared cost to everyone else, a deposit
-- to its member, a manager's meal edit to that member (once per 10 minutes).
\set M '''37370000-0000-0000-0000-00000000000a'''
\set R '''37370000-0000-0000-0000-00000000000b'''
\set K '''37370000-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:R), (:K);
select test.act_as(:M);
select create_mess('Edit Mess', 'Manager') as mess \gset
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'Rahim') returning id as rahim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :K, 'Karim') returning id as karim \gset
select set_config('meal_bazar.trusted', '', false);
insert into device_tokens (token, user_id, platform) values ('tok-edit-mgr-0001', :M, 'android'),
  ('tok-edit-rahim-01', :R, 'android'), ('tok-edit-karim-01', :K, 'android');
select (now() at time zone 'Asia/Dhaka')::date as today \gset

-- ── bazar ────────────────────────────────────────────────────────────────
select test.act_as(:M);
insert into bazars (id, mess_id, date, amount, buyer_member_id, paid_by_member_id)
values ('37370000-0000-0000-0000-0000000000b1', :'mess', :'today', 100, :'rahim', null);
select test.act_as(null);
delete from push_outbox; delete from notifications;
select test.act_as(:M);
update bazars set amount = 100 where id = '37370000-0000-0000-0000-0000000000b1';   -- nothing changed
select test.act_as(null);
select test.check((select count(*) = 0 from push_outbox), 'an unchanged upsert sends nothing');
select test.act_as(:M);
update bazars set amount = 150 where id = '37370000-0000-0000-0000-0000000000b1';
select test.act_as(null);
select test.check((select count(*) = 2 and bool_and(type = 'entry_edited') from push_outbox
                   where user_id in (:R, :K)), 'everyone else is told about a changed bazar');
select test.check(not exists (select 1 from push_outbox where user_id = :M), 'not the editor');
select test.check((select body = 'Edit Mess: ৳১৫০ এর বাজার বদলানো হয়েছে (আগে ৳১০০)' from push_outbox where user_id = :R),
                  'the new and the old amount');
delete from push_outbox;
select test.act_as(:M);
update bazars set deleted_at = now() where id = '37370000-0000-0000-0000-0000000000b1';
select test.act_as(null);
select test.check((select count(*) = 2 and bool_and(title = 'বাজার মুছে ফেলা হয়েছে') from push_outbox), 'delete is announced');

-- ── shared cost ──────────────────────────────────────────────────────────
delete from push_outbox;
select test.act_as(:M);
insert into expenses (id, mess_id, date, category_id, amount, split)
values ('37370000-0000-0000-0000-0000000000e1', :'mess', :'today',
        (select id from expense_categories where mess_id = :'mess' limit 1), 600, 'equal');
select test.act_as(null);
delete from push_outbox;
select test.act_as(:M);
update expenses set amount = 650 where id = '37370000-0000-0000-0000-0000000000e1';
select test.act_as(null);
select test.check((select count(*) = 2 and bool_and(type = 'entry_edited') from push_outbox where user_id in (:R, :K)),
                  'everyone else is told about a changed shared cost');

-- ── deposit: only that member ────────────────────────────────────────────
delete from push_outbox;
select test.act_as(:M);
insert into deposits (id, mess_id, member_id, date, amount, method, status)
values ('37370000-0000-0000-0000-0000000000d1', :'mess', :'rahim', :'today', 500, 'cash', 'verified');
select test.act_as(null);
delete from push_outbox;
select test.act_as(:M);
update deposits set amount = 450 where id = '37370000-0000-0000-0000-0000000000d1';
select test.act_as(null);
select test.check((select count(*) = 1 and bool_and(user_id = :R and type = 'entry_edited'
                   and body = 'আপনার ৳৪৫০ জমা বদলানো হয়েছে (আগে ৳৫০০)') from push_outbox), 'only the member, with the old amount');
delete from push_outbox;
select test.act_as(:M);
update deposits set deleted_at = now() where id = '37370000-0000-0000-0000-0000000000d1';
select test.act_as(null);
select test.check((select count(*) = 1 and bool_and(user_id = :R and title = 'জমা মুছে ফেলা হয়েছে') from push_outbox), 'delete tells the member');

-- ── meals: a manager edits a member's meal ───────────────────────────────
delete from push_outbox; delete from notifications;
select id as mt from meal_types where mess_id = :'mess' order by created_at limit 1 \gset
select test.act_as(:M);
insert into meal_entries (mess_id, member_id, meal_type_id, date, count) values (:'mess', :'mgr', :'mt', :'today', 1);
select test.act_as(null);
select test.check((select count(*) = 0 from push_outbox), 'a manager editing their own meal tells nobody');
select test.act_as(:M);
insert into meal_entries (mess_id, member_id, meal_type_id, date, count) values (:'mess', :'rahim', :'mt', :'today', 1);
select test.act_as(null);
select test.check((select count(*) = 1 and bool_and(user_id = :R and type = 'entry_edited'
                   and data ->> 'route' like '/meals?date=%') from push_outbox), 'the member hears about the manager''s entry');
delete from push_outbox;
select test.act_as(:M);
update meal_entries set count = 0.5 where member_id = :'rahim' and date = :'today';
update meal_entries set count = 1 where member_id = :'rahim' and date = :'today';
select test.act_as(null);
select test.check((select count(*) = 0 from push_outbox), 'further edits within 10 minutes stay quiet');
select test.check(not exists (select 1 from push_outbox where user_id = :K), 'others are not told');
