-- Core: mess creation, invites, membership, RLS isolation, manager guards.
\set A '''aaaaaaaa-0000-0000-0000-000000000001'''
\set B '''bbbbbbbb-0000-0000-0000-000000000002'''
\set C '''cccccccc-0000-0000-0000-000000000003'''

insert into auth.users (id, phone) values
  (:A, '+8801711111111'), (:B, '+8801722222222'), (:C, '+8801733333333');
select test.check((select count(*) from profiles) = 3, 'profiles auto-created for new users');

-- A creates a mess and becomes its manager.
select test.act_as(:A);
select create_mess('Green House', 'Arafat') as mess \gset
select test.check(
  (select role = 'manager' and status = 'active' from mess_members where mess_id = :'mess' and user_id = :A),
  'creator is active manager');
select test.check((select count(*) from audit_log where entity = 'mess_members') = 1, 'member insert audited');
select test.expect_error($$select create_mess('X', 'Me')$$, 'check');           -- name too short
select create_invite(:'mess') as code \gset

-- C (outsider) sees nothing of A's mess.
select test.act_as(:C);
select test.check((select count(*) from messes) = 0, 'outsider cannot read mess');
select test.check((select count(*) from mess_members) = 0, 'outsider cannot read members');
select test.check((select count(*) from mess_invites) = 0, 'outsider cannot read invites');
select test.check((select count(*) from audit_log) = 0, 'outsider cannot read audit');
select test.check((select count(*) from profiles) = 1, 'outsider sees only own profile');
select test.expect_error(format($$select create_invite(%L)$$, :'mess'), 'NOT_MANAGER');
select test.expect_error(
  format($$insert into mess_members (mess_id, display_name) values (%L, 'Hacker')$$, :'mess'),
  'row-level security');
select test.check(test.rows(format($$update messes set name = 'Pwned' where id = %L$$, :'mess')) = 0,
  'outsider cannot update mess');

-- B joins with the code → pending; sees own row but not the mess yet.
select test.act_as(:B);
select test.expect_error($$select join_mess('ZZZZZZ', 'Rahim')$$, 'INVALID_INVITE');
select join_mess(lower(:'code'), 'Rahim') as b_member \gset
select test.expect_error(format($$select join_mess(%L, 'Rahim')$$, :'code'), 'ALREADY_MEMBER');
select test.check((select count(*) from mess_members) = 1, 'pending user sees only own row');
select test.check((select count(*) from messes) = 0, 'pending user cannot read mess');
select test.check(test.rows(format($$update mess_members set status = 'active' where id = %L$$, :'b_member')) = 0,
  'pending user cannot approve self');

-- A approves B.
select test.act_as(:A);
select test.check(test.rows(format($$update mess_members set status = 'active' where id = %L$$, :'b_member')) = 1,
  'manager approves');
select test.expect_error(
  format($$insert into mess_members (mess_id, user_id, display_name) values (%L, %L, 'Linked')$$, :'mess', :C),
  'USER_LINK_FORBIDDEN');
select test.expect_error(
  format($$update mess_members set user_id = %L where id = %L$$, :C, :'b_member'),
  'USER_LINK_FORBIDDEN');
insert into mess_members (mess_id, display_name) values (:'mess', 'Karim (no app)');   -- offline member
select test.check((select count(*) from profiles) = 2, 'manager sees co-member profile');

-- B (member) can read but not manage.
select test.act_as(:B);
select test.check((select count(*) from messes) = 1, 'member reads mess');
select test.check((select count(*) from mess_members) = 3, 'member reads all members');
select test.check(test.rows($$update mess_members set role = 'manager'$$) = 0, 'member cannot change roles');
select test.check(test.rows($$update messes set name = 'Mine now'$$) = 0, 'member cannot update mess');
select test.check((select count(*) from mess_invites) = 0, 'member cannot read invites');

-- Last-manager guard.
select test.act_as(:A);
select test.expect_error(
  format($$update mess_members set role = 'member' where mess_id = %L and user_id = %L$$, :'mess', :A),
  'LAST_MANAGER');
select test.expect_error(
  format($$update mess_members set status = 'left', left_on = current_date where mess_id = %L and user_id = %L$$, :'mess', :A),
  'LAST_MANAGER');
update mess_members set role = 'manager' where id = :'b_member';
update mess_members set role = 'member' where mess_id = :'mess' and user_id = :A;
select test.check(not has_mess_role(:'mess', 'manager'), 'A demoted after B promoted');

-- A leaves; history row stays, access is gone; A can rejoin via a new invite.
select test.act_as(:B);
update mess_members set status = 'left', left_on = current_date where mess_id = :'mess' and user_id = :A;
select create_invite(:'mess') as code2 \gset
select test.act_as(:A);
select test.check((select count(*) from messes) = 0, 'left member loses access');
select join_mess(:'code2', 'Arafat');
select test.check((select status = 'pending' and left_on is null from mess_members where user_id = :A),
  'left member can request to rejoin');

-- Pending requests can be rejected (deleted); active members cannot be deleted.
select test.act_as(:B);
select test.check(test.rows(format($$delete from mess_members where mess_id = %L and user_id = %L$$, :'mess', :A)) = 1,
  'manager rejects pending request');
select test.check(test.rows(format($$delete from mess_members where id = %L$$, :'b_member')) = 0,
  'active member cannot be deleted');

select test.act_as(null);
select test.check((select count(*) from audit_log where actor_id is not null) >= 6, 'changes audited with actor');
