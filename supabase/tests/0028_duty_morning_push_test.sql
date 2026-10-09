-- Today's duty → one morning push + inbox row; done or repeat runs add none.
\set M '''28280000-0000-0000-0000-00000000000a'''
\set R '''28280000-0000-0000-0000-00000000000b'''
insert into auth.users (id) values (:M), (:R);
select test.act_as(:M);
select create_mess('Duty Push Mess', 'Manager') as mess \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'Rahim') returning id as rahim \gset
select set_config('meal_bazar.trusted', '', false);
insert into bazar_duties (mess_id, date, member_id)
values (:'mess', (now() at time zone 'Asia/Dhaka')::date, :'rahim'),
       (:'mess', (now() at time zone 'Asia/Dhaka')::date + 1, (select id from mess_members where user_id = :M));
select test.check(send_duty_reminders() >= 1, 'sent');
select test.check(send_duty_reminders() = 0, 'once a day');
select test.check((select count(*) = 1 from notifications where user_id = :R and type = 'duty_today'), 'Rahim told');
select test.check(not exists (select 1 from notifications where user_id = :M and type = 'duty_today'), 'tomorrow''s duty not yet');
select test.act_as(:R);
select test.expect_error('select send_duty_reminders()', 'permission denied');
select test.act_as(null);
