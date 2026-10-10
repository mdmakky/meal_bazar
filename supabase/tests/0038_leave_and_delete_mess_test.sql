select set_config('meal_bazar.today', '2099-12-31', false);
-- Leaving a mess (settled → at once; owing → refused), the push, the last
-- manager, and the 30-day mess deletion.
\set M '''38380000-0000-0000-0000-00000000000a'''
\set R '''38380000-0000-0000-0000-00000000000b'''
\set K '''38380000-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:R), (:K);
select test.act_as(:M);
select create_mess('Leave Mess', 'Manager') as mess \gset
select id as mgr from mess_members where mess_id = :'mess' and user_id = :M \gset
select test.act_as(null);
select set_config('meal_bazar.trusted', 'on', false);
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :R, 'Rahim') returning id as rahim \gset
insert into mess_members (mess_id, user_id, display_name) values (:'mess', :K, 'Karim') returning id as karim \gset
select set_config('meal_bazar.trusted', '', false);
update mess_members set joined_on = current_date - 70 where mess_id = :'mess';
insert into device_tokens (token, user_id, platform) values ('tok-leave-mgr-0001', :M, 'android');
select set_config('meal_bazar.today', '', false);
select (now() at time zone 'Asia/Dhaka')::date as today \gset

-- Rahim owes the mess: a bazar by the manager from the fund, and he deposited nothing.
select test.act_as(:M);
insert into bazars (mess_id, date, amount, buyer_member_id, paid_by_member_id) values (:'mess', :'today', 300, :'mgr', null);
select id as mt from meal_types where mess_id = :'mess' order by created_at limit 1 \gset
insert into meal_entries (mess_id, member_id, meal_type_id, date, count)
select :'mess', x, :'mt', :'today', 1 from unnest(array[:'mgr'::uuid, :'rahim'::uuid, :'karim'::uuid]) x;
select test.act_as(:R);
select test.check((select balance < 0 from leave_preview(:'mess')), 'preview: he owes');
select test.expect_error(format($$select leave_mess(%L)$$, :'mess'), 'DUES_OUTSTANDING');
select request_leave(:'mess');
select test.act_as(null);
select test.check((select count(*) = 1 from push_outbox where user_id = :M and type = 'member_left'
                   and title = 'মেস ছাড়তে চান'), 'the manager hears he wants to leave');
select test.check((select status = 'active' from mess_members where id = :'rahim'), 'still a member');

-- Karim has paid in more than his share: the mess owes him, he leaves at once.
delete from push_outbox;
select test.act_as(:M);
insert into deposits (mess_id, member_id, date, amount, method, status) values (:'mess', :'karim', :'today', 5000, 'cash', 'verified');
select test.act_as(:K);
select test.check((select balance > 0 from leave_preview(:'mess')), 'preview: the mess owes him');
select leave_mess(:'mess');
select test.act_as(null);
select test.check((select status = 'left' and left_on is not null from mess_members where id = :'karim'), 'he left');
select test.check((select count(*) = 1 from push_outbox where user_id = :M and type = 'member_left'
                   and title = 'সদস্য মেস ছেড়েছেন'), 'the manager is told');
select test.act_as(:K);
select test.check(not (select is_mess_member(:'mess')), 'no longer a member');
select test.expect_error(format($$select leave_mess(%L)$$, :'mess'), 'NOT_MEMBER');

-- The only manager cannot leave.
select test.act_as(:M);
select test.check((select only_manager from leave_preview(:'mess')), 'preview: only manager');
select test.expect_error(format($$select leave_mess(%L)$$, :'mess'), 'LAST_MANAGER');

-- ── deleting the mess ────────────────────────────────────────────────────
select test.act_as(:R);
select test.expect_error(format($$select request_mess_deletion(%L, 'Leave Mess')$$, :'mess'), 'NOT_OWNER');
select test.act_as(:M);
select test.expect_error(format($$select request_mess_deletion(%L, 'leave')$$, :'mess'), 'NAME_MISMATCH');
select test.act_as(null);
insert into device_tokens (token, user_id, platform) values ('tok-leave-rahim1', :R, 'android');
delete from push_outbox;
select test.act_as(:M);
select request_mess_deletion(:'mess', ' Leave Mess ');
select test.act_as(null);
select test.check((select delete_requested_at is not null from messes where id = :'mess'), 'marked for deletion');
select test.check((select count(*) = 1 and bool_and(user_id = :R and type = 'mess_deletion') from push_outbox), 'members are told');
select test.check((select purge_deleted_messes() = 0), 'nothing is erased within the grace');
select test.act_as(:M);
select cancel_mess_deletion(:'mess');
select test.act_as(null);
select test.check((select delete_requested_at is null from messes where id = :'mess'), 'cancelled');
update messes set delete_requested_at = now() - interval '31 days' where id = :'mess';
select test.check((select purge_deleted_messes() = 1), 'erased after 30 days');
select test.check(not exists (select 1 from messes where id = :'mess')
                  and not exists (select 1 from mess_members where mess_id = :'mess'), 'everything went with it');
