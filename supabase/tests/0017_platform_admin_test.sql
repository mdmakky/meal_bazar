-- Platform admin: admin-only RPCs, public config, validated config edits,
-- defaults for new messes, mess/user suspension, last-admin guard, audit,
-- write-only secrets and the branding bucket.
\set A '''17170000-0000-0000-0000-00000000000a'''
\set M '''17170000-0000-0000-0000-00000000000b'''
\set U '''17170000-0000-0000-0000-00000000000c'''
\set S '''17170000-0000-0000-0000-00000000000d'''
insert into auth.users (id, email, last_sign_in_at) values
  (:A, 'admin@mealbazar.test', now()), (:M, 'manager@mealbazar.test', now()),
  (:U, 'member@mealbazar.test', null), (:S, 'suspend@mealbazar.test', null);
-- Bootstrap step from DATABASE.md.
insert into platform_admins select id from auth.users where email = 'admin@mealbazar.test';

select test.act_as(:M);
select create_mess('Admin Test Mess', 'Manager') as mess \gset
select create_invite(:'mess') as code \gset
select test.act_as(:U);
select join_mess(:'code', 'Rahim') as rahim \gset
select test.act_as(:M);
update mess_members set status = 'active' where id = :'rahim';
select id as lunch from meal_types where mess_id = :'mess' and name = 'দুপুর' \gset
insert into meal_entries (mess_id, member_id, meal_type_id, date) values (:'mess', :'rahim', :'lunch', current_date);

-- ── non-admins get NOT_PLATFORM_ADMIN everywhere ─────────────────────────
select test.check(not is_platform_admin(), 'manager is not a platform admin');
select test.expect_error(sql, 'NOT_PLATFORM_ADMIN') from unnest(array[
  'select admin_stats()',
  'select * from admin_list_messes(null, 10, 0)',
  'select * from admin_list_users(null, 10, 0)',
  format('select admin_set_mess_suspended(%L, true, %L)', :'mess', 'x'),
  format('select admin_set_user_suspended(%L, true, %L)', :M, 'x'),
  $$select admin_set_admin('manager@mealbazar.test', true)$$,
  'select * from admin_ai_usage(7)',
  'select * from admin_deletion_queue()',
  $$select admin_set_config('features', '{"ai": false}')$$,
  $$select admin_set_secret('GEMINI_API_KEY', 'sk-123456789012')$$,
  'select * from admin_list_secrets()'
]) sql;
-- No back doors: tables are closed to direct writes and suspension columns are admin-only.
select test.expect_error($$insert into platform_admins (user_id) values (auth.uid())$$, 'row-level security');
select test.check(test.rows($$update platform_config set value = '{}'$$) = 0, 'config not writable directly');
select test.check((select count(*) from platform_audit) = 0, 'audit not readable by non-admins');
select test.expect_error(format($$update messes set suspended_at = now() where id = %L$$, :'mess'), 'NOT_PLATFORM_ADMIN');
select test.expect_error($$update profiles set suspended_at = now() where id = auth.uid()$$, 'NOT_PLATFORM_ADMIN');

-- ── public config: anon and authenticated read it ────────────────────────
select set_config('request.jwt.claim.sub', '', false);
set role anon;
select test.check(get_platform_config() ?& array['features', 'ai', 'app', 'defaults', 'catalogue',
                                                 'payment_methods', 'branding'], 'anon reads all keys');
select test.check((get_platform_config() -> 'features' ->> 'invite_qr')::boolean, 'full flag list seeded');
select test.check(jsonb_array_length(get_platform_config() -> 'catalogue' -> 'groups') = 4, 'catalogue seeded');
select test.check(get_platform_config() -> 'ai' -> 'text_chain' -> 0 ->> 'provider' = 'gemini', 'ai v3 shape');
select test.expect_error('select get_platform_secrets()', 'permission denied');
select test.expect_error('select * from platform_secrets', 'permission denied');
reset role;
select test.act_as(:U);
select test.check(get_platform_config() -> 'branding' ->> 'accent_light' = '#C98A0B', 'member reads branding');
select test.check(is_platform_admin() = false, 'is_platform_admin callable by authenticated');

-- ── admin edits config: valid ok, invalid refused ────────────────────────
select test.act_as(:A);
select test.check(is_platform_admin(), 'bootstrapped admin');
select admin_set_config('features', '{"ai": false, "duty": true, "brand_new_flag": true}');
select test.check((get_platform_config() -> 'features' ->> 'ai')::boolean = false, 'features updated');
select test.expect_error($$select admin_set_config('features', '{"ai": "no"}')$$, 'INVALID_CONFIG');
select test.expect_error($$select admin_set_config('features', '[]')$$, 'INVALID_CONFIG');
select test.expect_error($$select admin_set_config('nope', '{}')$$, 'UNKNOWN_CONFIG_KEY');

\set ai_ok '{"enabled":true,"text_chain":[{"provider":"openrouter","model":"x/y:free"}],"vision_chain":[{"provider":"gemini","model":"gemini-flash-latest"}],"quota_meal_draft":50,"quota_bazar_draft":0,"timeout_ms":3000,"temperature":1,"allow_paid":true}'
select admin_set_config('ai', :'ai_ok');
select test.check((get_platform_config() -> 'ai' ->> 'quota_meal_draft')::int = 50, 'ai updated');
select test.expect_error(format('select admin_set_config(%L, %L)', 'ai', v), 'INVALID_CONFIG')
from unnest(array[
  jsonb_set(:'ai_ok', '{quota_meal_draft}', '1001'),
  jsonb_set(:'ai_ok', '{quota_meal_draft}', '2.5'),
  jsonb_set(:'ai_ok', '{quota_bazar_draft}', '"10"'),
  jsonb_set(:'ai_ok', '{timeout_ms}', '2999'),
  jsonb_set(:'ai_ok', '{timeout_ms}', '55001'),
  jsonb_set(:'ai_ok', '{temperature}', '1.1'),
  jsonb_set(:'ai_ok', '{allow_paid}', '"yes"'),
  jsonb_set(:'ai_ok', '{text_chain}', '[]'),
  jsonb_set(:'ai_ok', '{text_chain}', '[{"provider":"openai","model":"gpt"}]'),
  jsonb_set(:'ai_ok', '{vision_chain}', '[{"provider":"gemini","model":""}]'),
  jsonb_set(:'ai_ok', '{vision_chain}', jsonb_build_array(jsonb_build_object('provider', 'gemini', 'model', repeat('m', 121)))),
  jsonb_set(:'ai_ok', '{vision_chain}', (select jsonb_agg('{"provider":"gemini","model":"m"}'::jsonb) from generate_series(1, 6))),
  :'ai_ok'::jsonb - 'enabled'
]::jsonb[]) v;

\set app_ok '{"maintenance":true,"maintenance_message_bn":"রক্ষণাবেক্ষণ","min_version":"1.2.0","latest_version":"1.3.10","banner":{"active":true,"text_bn":"হ্যালো","text_en":"Hi","level":"warning"}}'
select admin_set_config('app', :'app_ok');
select test.expect_error(format('select admin_set_config(%L, %L)', 'app', v), 'INVALID_CONFIG')
from unnest(array[
  jsonb_set(:'app_ok', '{min_version}', '"1.2"'),
  jsonb_set(:'app_ok', '{min_version}', '"v1.2.0"'),
  jsonb_set(:'app_ok', '{maintenance}', '1'),
  jsonb_set(:'app_ok', '{banner,level}', '"danger"')
]::jsonb[]) v;

\set defaults_ok '{"month_start_day":5,"meal_off_cutoff":"21:30","meal_types":[{"name":"দুপুর","weight":1.5,"enabled":true},{"name":"রাত","weight":1}],"expense_categories":[{"name":"ভাড়া","split":"equal"},{"name":"রান্না","split":"meal"}]}'
select test.expect_error(format('select admin_set_config(%L, %L)', 'defaults', v), 'INVALID_CONFIG')
from unnest(array[
  jsonb_set(:'defaults_ok', '{meal_types}', '[]'),
  jsonb_set(:'defaults_ok', '{meal_types,0,weight}', '5.5'),
  jsonb_set(:'defaults_ok', '{meal_types,0,weight}', '-1'),
  jsonb_set(:'defaults_ok', '{meal_types,0,name}', '""'),
  jsonb_set(:'defaults_ok', '{month_start_day}', '29'),
  jsonb_set(:'defaults_ok', '{meal_off_cutoff}', '"24:00"'),
  jsonb_set(:'defaults_ok', '{expense_categories,0,split}', '"weird"')
]::jsonb[]) v;
select admin_set_config('defaults', :'defaults_ok');

select admin_set_config('payment_methods', '[{"key":"cash","label_bn":"নগদ টাকা","label_en":"Cash","enabled":true},{"key":"bkash","label_bn":"বিকাশ","label_en":"bKash","enabled":false}]');
select test.expect_error($$select admin_set_config('payment_methods', '[{"key":"paypal","label_bn":"x","label_en":"x","enabled":true}]')$$, 'INVALID_CONFIG');
select test.expect_error($$select admin_set_config('payment_methods', '[{"key":"cash","label_bn":"x","label_en":"x","enabled":true},{"key":"cash","label_bn":"y","label_en":"y","enabled":true}]')$$, 'INVALID_CONFIG');

select admin_set_config('catalogue', '{"groups":[{"name":"চাল","items":[{"name":"চাল","unit":"কেজি"}]}]}');
select test.expect_error($$select admin_set_config('catalogue', '{"groups":[{"name":"x","items":[{"name":""}]}]}')$$, 'INVALID_CONFIG');

\set brand_ok '{"app_name_bn":"মিল বাজার","app_name_en":"Meal Bazar","tagline_bn":"","tagline_en":"","logo_url":null,"accent_light":"#c98a0b","accent_dark":"#E8B33A"}'
select admin_set_config('branding', :'brand_ok');
select admin_set_config('branding', jsonb_set(:'brand_ok', '{logo_url}', '"https://x.supabase.co/storage/v1/object/public/branding/logo.png"'));
select test.expect_error(format('select admin_set_config(%L, %L)', 'branding', v), 'INVALID_CONFIG')
from unnest(array[
  jsonb_set(:'brand_ok', '{accent_light}', '"#C98A0"'),
  jsonb_set(:'brand_ok', '{accent_dark}', '"red"'),
  jsonb_set(:'brand_ok', '{accent_dark}', '"#GGGGGG"'),
  jsonb_set(:'brand_ok', '{app_name_en}', '""'),
  jsonb_set(:'brand_ok', '{logo_url}', '42')
]::jsonb[]) v;
select test.check((select count(*) from platform_audit where action = 'set_config') = 8, 'each config write audited');
select test.check((select old ->> 'ai' = 'true' and new ->> 'ai' = 'false' and actor_id = :A
                   from platform_audit where action = 'set_config' and target = 'features'), 'audit has old/new/actor');

-- ── new messes follow the edited defaults ────────────────────────────────
select test.act_as(:U);
select create_mess('Defaults Mess', 'Rahim') as dmess \gset
select test.check((select month_start_day = 5 and meal_off_cutoff = '21:30' from messes where id = :'dmess'), 'mess settings from defaults');
select test.check((select string_agg(name || ':' || weight || ':' || enabled, ',' order by sort_order)
                   from meal_types where mess_id = :'dmess') = 'দুপুর:1.50:true,রাত:1.00:true', 'meal types from defaults');
select test.check((select string_agg(name || ':' || default_split, ',' order by sort_order)
                   from expense_categories where mess_id = :'dmess') = 'ভাড়া:equal,রান্না:meal', 'categories from defaults');
select create_mess('Explicit Mess', 'Rahim', 10::smallint) as emess \gset
select test.check((select month_start_day = 10 from messes where id = :'emess'), 'explicit month_start_day wins');
-- Missing defaults row → hard-coded fallback.
select test.act_as(null);
delete from platform_config where key = 'defaults';
select test.act_as(:U);
select create_mess('Fallback Mess', 'Rahim') as fmess \gset
select test.check((select count(*) from meal_types where mess_id = :'fmess') = 3
                  and (select count(*) from expense_categories where mess_id = :'fmess') = 9
                  and (select month_start_day = 1 and meal_off_cutoff = '22:00' from messes where id = :'fmess'),
                  'fallback to built-in defaults');

-- ── stats and lists ──────────────────────────────────────────────────────
select test.act_as(:A);
select admin_stats() as stats \gset
select test.check((:'stats'::jsonb ->> 'users_total')::int >= 4 and (:'stats'::jsonb ->> 'messes_total')::int >= 4
                  and (:'stats'::jsonb ->> 'messes_active_7d')::int >= 1 and (:'stats'::jsonb ->> 'meals_7d')::int >= 1
                  and :'stats'::jsonb ?& array['users_7d', 'bazars_7d', 'ai_calls_7d', 'suspended_messes', 'deletion_pending'],
                  'stats look sane');
select test.check((select member_count = 2 and manager_names = 'Manager' and last_activity is not null and suspended_at is null
                   from admin_list_messes('admin test', 10, 0)), 'list messes');
select test.check((select count(*) from admin_list_messes(null, 2, 0)) = 2, 'list messes paginates');
select test.check((select email = 'member@mealbazar.test' and mess_count = 4 and not is_admin
                   from admin_list_users('member@', 10, 0)), 'list users');
select test.check((select is_admin and last_sign_in_at is not null from admin_list_users('admin@mealbazar', 10, 0)), 'admin flagged');
select test.act_as(null);
insert into ai_usage (mess_id, day, feature, count) values (:'mess', current_date, 'meal_draft', 3);
select test.act_as(:A);
select test.check((select calls >= 3 from admin_ai_usage(7) where feature = 'meal_draft' and day = current_date), 'ai usage');
select test.check((select count(*) from admin_deletion_queue()) >= 1, 'deletion queue visible');

-- ── mess suspension: reads ok, writes refused, admin bypass, unsuspend ───
select test.expect_error(format($$select admin_set_mess_suspended(%L, true, ' ')$$, :'mess'), 'REASON_REQUIRED');
select admin_set_mess_suspended(:'mess', true, 'Spam');
select test.act_as(:M);
select test.check((select count(*) from meal_entries where mess_id = :'mess') = 1, 'suspended mess still readable');
select test.check((select suspended_reason = 'Spam' from messes where id = :'mess'), 'member sees why');
select test.expect_error(format($$insert into meal_entries (mess_id, member_id, meal_type_id, date) values (%L, %L, %L, current_date + 1)$$, :'mess', :'rahim', :'lunch'), 'MESS_SUSPENDED');
select test.expect_error(format($$update meal_entries set count = 2 where mess_id = %L$$, :'mess'), 'MESS_SUSPENDED');
select test.expect_error(format($$delete from meal_entries where mess_id = %L$$, :'mess'), 'MESS_SUSPENDED');
select test.expect_error(format($$insert into bazars (mess_id, date, amount) values (%L, current_date, 100)$$, :'mess'), 'MESS_SUSPENDED');
select test.expect_error(format($$update messes set name = 'Renamed' where id = %L$$, :'mess'), 'MESS_SUSPENDED');
select test.expect_error(format($$select create_invite(%L)$$, :'mess'), 'MESS_SUSPENDED');
select test.act_as(:U);
select test.expect_error(format($$select record_my_deposit(%L, gen_random_uuid(), current_date, 10, 'cash', null, null, null)$$, :'mess'), 'MESS_SUSPENDED');
select create_mess('Unaffected', 'Rahim') as other \gset
select test.check(test.rows(format($$update messes set name = 'Still Fine' where id = %L$$, :'other')) = 1, 'other messes unaffected');
select test.act_as(:A);
-- The guard lets admins through (they still need RLS access to touch rows).
select assert_mess_writable(:'mess');
select admin_set_mess_suspended(:'mess', false, null);
select test.act_as(:M);
select test.check(test.rows(format($$update meal_entries set count = 1 where mess_id = %L$$, :'mess')) = 1, 'unsuspend restores writes');

-- ── user suspension ──────────────────────────────────────────────────────
select test.act_as(:A);
select admin_set_user_suspended(:M, true, 'Abuse');
select test.act_as(:M);
select test.check((select count(*) from meal_entries where mess_id = :'mess') = 1, 'suspended user still reads');
select test.expect_error(format($$update meal_entries set count = 2 where mess_id = %L$$, :'mess'), 'USER_SUSPENDED');
select test.expect_error($$select create_mess('New', 'Me')$$, 'USER_SUSPENDED');
select test.expect_error($$update profiles set full_name = 'X' where id = auth.uid()$$, 'USER_SUSPENDED');
select test.act_as(:U);
select test.check(test.rows(format($$update meal_entries set count = 1 where mess_id = %L$$, :'mess')) = 0, 'others unaffected (RLS still applies)');
select test.act_as(:A);
select admin_set_user_suspended(:M, false, null);
select test.act_as(:M);
select test.check(test.rows(format($$update meal_entries set count = 2 where mess_id = %L$$, :'mess')) = 1, 'unsuspended user writes');

-- A suspended user can still delete their account.
select test.act_as(null);
insert into auth.users (id, email) values (:S, 'suspend@mealbazar.test') on conflict do nothing;
select test.act_as(:S);
select create_mess('Suspend Mess', 'Sumon') as smess \gset
select test.act_as(:A);
select admin_set_user_suspended(:S, true, 'Spam');
select admin_set_mess_suspended(:'smess', true, 'Spam');
select test.act_as(:S);
select delete_my_account();
select test.act_as(null);
select test.check((select deleted_at is not null from profiles where id = :S), 'suspended user deleted account');

-- ── admins: grant, last-admin guard ──────────────────────────────────────
select test.act_as(:A);
select test.expect_error($$select admin_set_admin('ghost@mealbazar.test', true)$$, 'USER_NOT_FOUND');
select test.expect_error($$select admin_set_admin('admin@mealbazar.test', false)$$, 'LAST_ADMIN');
select admin_set_admin('Manager@MealBazar.test', true);
select test.act_as(:M);
select test.check(is_platform_admin(), 'granted admin');
select admin_set_admin('admin@mealbazar.test', false);
select test.expect_error($$select admin_set_admin('manager@mealbazar.test', false)$$, 'LAST_ADMIN');
select test.act_as(:A);
select test.expect_error('select admin_stats()', 'NOT_PLATFORM_ADMIN');

-- ── secrets: write-only ──────────────────────────────────────────────────
select test.act_as(:M);
select admin_set_secret('GEMINI_API_KEY', ' AIzaSyTESTVALUE1234 ');
select admin_set_secret('SMTP_PASSWORD', 'short');
select test.expect_error($$select admin_set_secret('AWS_KEY', 'x')$$, 'INVALID_SECRET_NAME');
select test.check((select string_agg(name || ':' || last4, ',' order by name) from admin_list_secrets())
                  = 'GEMINI_API_KEY:1234,SMTP_PASSWORD:••••', 'list shows last4 only');
select test.check(not exists (select 1 from admin_list_secrets() s where s::text like '%AIzaSy%'), 'list never returns values');
select test.expect_error('select get_platform_secrets()', 'permission denied');
select test.expect_error('select * from platform_secrets', 'permission denied');
select admin_set_secret('SMTP_PASSWORD', '');
select test.check((select count(*) from admin_list_secrets()) = 1, 'empty value deletes');
select test.act_as(:U);
select test.expect_error('select get_platform_secrets()', 'permission denied');
select test.act_as(null);
set role service_role;
select get_platform_secrets() ->> 'GEMINI_API_KEY' as gemini \gset
reset role;
select test.check(:'gemini' = 'AIzaSyTESTVALUE1234', 'service_role reads secrets');
select test.check((select count(*) from platform_audit where action in ('set_secret', 'delete_secret')) = 3, 'secret writes audited');
select test.check(not exists (select 1 from platform_audit where coalesce(old::text, '') || coalesce(new::text, '') like '%AIza%'), 'secret values never logged');
select test.check((select count(*) from platform_audit where action in ('suspend_mess', 'unsuspend_mess', 'suspend_user',
                   'unsuspend_user', 'grant_admin', 'revoke_admin')) = 8, 'admin writes audited');

-- ── branding bucket: public read, admin write ───────────────────────────
-- The storage stub exists from the 0009 test; replay the bucket setup against it.
set client_min_messages = warning;
select setup_branding_storage();
select test.check((select public from storage.buckets where id = 'branding'), 'public branding bucket');
select test.act_as(:U);
select test.expect_error($$insert into storage.objects (bucket_id, name) values ('branding', 'logo.png')$$, 'row-level security');
select test.act_as(:M);
insert into storage.objects (bucket_id, name) values ('branding', 'logo.png');
select test.act_as(:U);
select test.check((select count(*) from storage.objects where bucket_id = 'branding') = 1, 'everyone reads branding');
select test.check(test.rows($$delete from storage.objects where bucket_id = 'branding'$$) = 0, 'non-admin cannot delete');
select test.act_as(:M);
select test.check(test.rows($$delete from storage.objects where bucket_id = 'branding'$$) = 1, 'admin deletes');
