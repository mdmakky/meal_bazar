-- Leaving removes the member's future duties, keeps past ones.
\set M '''27270000-0000-0000-0000-00000000000a'''
\set R '''27270000-0000-0000-0000-00000000000b'''
insert into auth.users (id) values (:M), (:R);
select test.act_as(:M);
select create_mess('Duty Leave Mess', 'Manager') as mess \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'Rahim') returning id as rahim \gset
select set_config('meal_bazar.trusted', '', false);
update mess_members set joined_on = current_date - 10 where id = :'rahim';
select test.act_as(:M);
insert into bazar_duties (mess_id, date, member_id)
select :'mess', current_date + d, :'rahim' from generate_series(-2, 3) d;
update mess_members set status = 'left', left_on = current_date where id = :'rahim';
select test.check((select count(*) = 3 and max(date) = current_date from bazar_duties where member_id = :'rahim'),
                  'future duties gone, past and today kept');
select test.act_as(null);
