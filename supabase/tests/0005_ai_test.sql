-- AI: quota, kill switch, membership, context shape, RLS.
\set M '''55555555-0000-0000-0000-00000000000a'''
\set P '''55555555-0000-0000-0000-00000000000b'''
\set X '''55555555-0000-0000-0000-00000000000c'''
insert into auth.users (id) values (:M), (:P), (:X);

select test.act_as(:M);
select create_mess('AI Mess', 'Manager') as mess \gset
select create_invite(:'mess') as code \gset
insert into mess_members (mess_id, display_name) values (:'mess', 'Rahim');
insert into mess_members (mess_id, display_name, status) values (:'mess', 'Gone', 'inactive');

-- Quota: 2 allowed, 3rd refused, other feature independent.
select test.check(ai_consume(:'mess', 'meal_draft', 2), 'first call allowed');
select test.check(ai_consume(:'mess', 'meal_draft', 2), 'second call allowed');
select test.check(not ai_consume(:'mess', 'meal_draft', 2), 'third call over quota');
select test.check(ai_consume(:'mess', 'bazar_draft', 1), 'other feature has own quota');
select test.check((select count from ai_usage where mess_id = :'mess' and feature = 'meal_draft'
                   and day = (now() at time zone 'Asia/Dhaka')::date) = 2, 'count capped at limit');
select test.check(not ai_consume(:'mess', 'x', 0), 'zero limit refuses');

-- Context: active members and enabled types only, refs in order.
select ai_meal_context(:'mess') as ctx \gset
select test.check(jsonb_array_length((:'ctx'::jsonb) -> 'members') = 2, 'two active members');
select test.check((:'ctx'::jsonb) #>> '{members,0,ref}' = 'M1', 'member ref M1');
select test.check((:'ctx'::jsonb) #>> '{members,0,aliases,0}' = 'Manager', 'alias is display name');
select test.check(jsonb_array_length((:'ctx'::jsonb) -> 'meal_types')
                  = (select count(*) from meal_types where mess_id = :'mess' and enabled), 'enabled types only');
select test.check((:'ctx'::jsonb) #>> '{meal_types,0,ref}' = 'T1', 'type ref T1');

-- Kill switch.
update messes set ai_settings = ai_settings || '{"enabled": false}' where id = :'mess';
select test.expect_error(format($$select ai_consume(%L, 'meal_draft', 30)$$, :'mess'), 'AI_DISABLED');
update messes set ai_settings = ai_settings || '{"enabled": true}' where id = :'mess';

-- Clients cannot write usage directly.
select test.check(test.rows(format($$update ai_usage set count = 0 where mess_id = %L$$, :'mess')) = 0, 'no client update');
select test.expect_error(format($$insert into ai_usage (mess_id, day, feature) values (%L, '2026-01-01', 'x')$$, :'mess'), 'row-level security');

-- Pending member and outsider: no quota, no context, no usage rows.
select test.act_as(:P);
select join_mess(:'code', 'Pending');
select test.expect_error(format($$select ai_consume(%L, 'meal_draft', 30)$$, :'mess'), 'NOT_MEMBER');
select test.check(ai_meal_context(:'mess') is null, 'pending gets no context');
select test.act_as(:X);
select test.expect_error(format($$select ai_consume(%L, 'meal_draft', 30)$$, :'mess'), 'NOT_MEMBER');
select test.check(ai_meal_context(:'mess') is null, 'outsider gets no context');
select test.check((select count(*) from ai_usage) = 0, 'outsider sees no usage');
select test.act_as(null);
select test.expect_error(format($$select ai_consume(%L, 'meal_draft', 30)$$, :'mess'), 'NOT_AUTHENTICATED');
