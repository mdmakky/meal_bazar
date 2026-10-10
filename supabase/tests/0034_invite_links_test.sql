-- Invite links: manager-only, long single-use code, preview readable before
-- sign-in, joining adds an ACTIVE member at once and uses the link up; the
-- classic shared code still waits for approval.
\set M '''34340000-0000-0000-0000-00000000000a'''
\set R '''34340000-0000-0000-0000-00000000000b'''
\set K '''34340000-0000-0000-0000-00000000000c'''
\set X '''34340000-0000-0000-0000-00000000000d'''
insert into auth.users (id) values (:M), (:R), (:K), (:X);
select test.act_as(:M);
select create_mess('Invite Mess', 'Joy') as mess \gset
select create_invite_link(:'mess', '  Rahim ') as code \gset
select test.check(:'code' ~ '^[A-Z2-9]{10}$', 'a long link code');
select test.check((select auto_approve and single_use and invitee_name = 'Rahim' from mess_invites where code = :'code'), 'link invite flags and trimmed name');
select test.act_as(:R);
select test.expect_error(format($$select create_invite_link(%L)$$, :'mess'), 'NOT_MANAGER');
-- The preview works for anyone (also before sign-in) and shows only the basics.
select test.act_as(null);
set role anon;
select test.check((select valid and mess_name = 'Invite Mess' and inviter_name = 'Joy' and invitee_name = 'Rahim' and auto_approve from invite_preview(:'code')), 'preview before sign-in');
select test.check((select not valid and reason = 'unknown' from invite_preview('NOSUCHCODE')), 'unknown code');
reset role;

-- Rahim opens the link with an account: added at once, active, link used up.
select test.act_as(:R);
select join_mess(:'code', 'Rahim') as rahim \gset
select test.check((select status = 'active' and joined_on = (now() at time zone 'Asia/Dhaka')::date from mess_members where id = :'rahim'), 'active immediately');
select test.act_as(null);
select test.check((select used_by = :R and used_at is not null from mess_invites where code = :'code'), 'invite used up');
select test.check((select not valid and reason = 'used' from invite_preview(:'code')), 'preview says used');
select test.check((select count(*) = 1 from notifications where user_id = :M and type = 'join_request' and body = 'Rahim মেসে যোগ দিয়েছেন'), 'manager told who joined');
select test.act_as(:K);
select test.expect_error(format($$select join_mess(%L, 'Karim')$$, :'code'), 'INVALID_INVITE');
-- Already a member: refused, nothing changes.
select test.act_as(:M);
select create_invite_link(:'mess') as code2 \gset
select test.act_as(:R);
select test.expect_error(format($$select join_mess(%L, 'Rahim')$$, :'code2'), 'ALREADY_MEMBER');
select test.act_as(null);
select test.check((select used_at is null from mess_invites where code = :'code2'), 'a refused join does not burn the link');

-- Expired and revoked links.
update mess_invites set expires_at = now() - interval '1 minute' where code = :'code2';
select test.act_as(:K);
select test.expect_error(format($$select join_mess(%L, 'Karim')$$, :'code2'), 'INVALID_INVITE');
select test.act_as(null);
select test.check((select reason = 'expired' from invite_preview(:'code2')), 'preview says expired');
select test.act_as(:M);
select create_invite_link(:'mess') as code3 \gset
select test.act_as(null);
update mess_invites set revoked_at = now() where code = :'code3';
select test.check((select reason = 'revoked' from invite_preview(:'code3')), 'preview says revoked');

-- The classic shared code keeps its old behaviour: pending until approved.
select test.act_as(:M);
select create_invite(:'mess') as old \gset
select test.act_as(:X);
select join_mess(:'old', 'Xavier') as xav \gset
select test.act_as(null);
select test.check((select status = 'pending' from mess_members where id = :'xav'), 'shared code still waits for approval');
select test.check((select not auto_approve and not single_use and used_at is null from mess_invites where code = :'old'), 'shared code is reusable');
