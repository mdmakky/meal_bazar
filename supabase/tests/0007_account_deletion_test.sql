-- Account deletion: last-manager refusal, anonymised profile, history kept, sole mess closed.
\set A '''77777777-0000-0000-0000-00000000000a'''
\set B '''77777777-0000-0000-0000-00000000000b'''
\set C '''77777777-0000-0000-0000-00000000000c'''
\set D '''77777777-0000-0000-0000-00000000000d'''
insert into auth.users (id, phone) values
  (:A, '+8801777777771'), (:B, '+8801777777772'), (:C, '+8801777777773'), (:D, '+8801777777774');

-- A manages a mess; B is an approved member with meal and money history; D is pending.
select test.act_as(:A);
select create_mess('Delete Mess', 'Arafat') as mess \gset
select create_invite(:'mess') as code \gset
select test.act_as(:B);
select join_mess(:'code', 'Rahim') as b_member \gset
select test.act_as(:D);
select join_mess(:'code', 'Dipu') as d_member \gset
select test.act_as(:A);
update mess_members set status = 'active' where id = :'b_member';
select id as lunch from meal_types where mess_id = :'mess' and name = 'দুপুর' \gset
insert into meal_entries (mess_id, member_id, meal_type_id, date) values (:'mess', :'b_member', :'lunch', current_date);
insert into deposits (mess_id, member_id, date, amount) values (:'mess', :'b_member', current_date, 500);
select test.check((select phone from profiles where id = :B) is not null, 'manager sees member phone before deletion');

-- Not signed in → refused.
select test.act_as(null);
select test.expect_error($$select delete_my_account()$$, 'NOT_AUTHENTICATED');

-- The only manager of a mess with other app users must hand over first.
select test.act_as(:A);
select test.expect_error($$select delete_my_account()$$, 'LAST_MANAGER');
select test.check((select deleted_at is null from profiles where id = :A), 'refused deletion changes nothing');

-- B deletes their account.
select test.act_as(:B);
select delete_my_account();
select test.check((select count(*) from messes) = 0, 'deleted user loses mess access');

select test.act_as(null);
select test.check(
  (select status = 'left' and left_on = current_date and user_id is null and display_name = 'Rahim'
   from mess_members where id = :'b_member'),
  'member row kept as left, unlinked, name kept');
select test.check((select count(*) from meal_entries where member_id = :'b_member') = 1, 'meal history kept');
select test.check((select count(*) from deposits where member_id = :'b_member') = 1, 'money history kept');
select test.check(
  (select full_name = 'Former member' and phone is null and avatar_path is null and deleted_at is not null
   from profiles where id = :B),
  'profile anonymised');
select test.check(exists (select 1 from deletion_requests where user_id = :B), 'auth deletion queued');
select test.check(
  exists (select 1 from audit_log where action = 'delete_account' and entity_id = :'b_member'),
  'deletion audited');

select test.act_as(:A);
select test.check((select count(*) from profiles where id = :B and phone is not null) = 0,
  'other users can no longer see the phone');
select test.check((select count(*) from mess_members where id = :'b_member') = 1, 'manager still sees the member row');
select test.check((select count(*) from meal_entries where member_id = :'b_member') = 1, 'manager still sees history');
select test.check((select count(*) from deletion_requests) = 0, 'deletion queue is not readable');

-- A pending requester's row is removed.
select test.act_as(:D);
select delete_my_account();
select test.act_as(null);
select test.check(not exists (select 1 from mess_members where id = :'d_member'), 'pending request deleted');

-- C is the only member of their mess → the mess is soft-deleted.
select test.act_as(:C);
select create_mess('Solo Mess', 'Chanchal') as solo \gset
select delete_my_account();
select test.act_as(null);
select test.check((select deleted_at is not null from messes where id = :'solo'), 'sole-member mess soft-deleted');
select test.check((select user_id is null from mess_members where mess_id = :'solo'), 'sole member unlinked');

-- A is now the only app user left in their mess → can delete; mess closes.
select test.act_as(:A);
select delete_my_account();
select test.act_as(null);
select test.check((select deleted_at is not null from messes where id = :'mess'), 'mess closed when last app user leaves');
select test.check((select count(*) from mess_members where mess_id = :'mess' and user_id is not null) = 0, 'no linked members remain');
