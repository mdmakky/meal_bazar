-- Deletion queue: processed rows outlive the auth user; the queue stays service-role only.
\set U '''10101010-0000-0000-0000-00000000000a'''
insert into auth.users (id, phone) values (:U, '+8801710101010');
select test.act_as(:U);
select delete_my_account();
select test.check((select count(*) from deletion_requests) = 0, 'queue not readable by users');
select test.check(test.rows($$update deletion_requests set processed_at = now()$$) = 0, 'queue not writable by users');

select test.act_as(null);
select test.check(
  (select processed_at is null and last_error is null from deletion_requests where user_id = :U),
  'new request is pending');
update deletion_requests set last_error = 'unexpected_failure', last_attempt_at = now() where user_id = :U;
delete from auth.users where id = :U;
update deletion_requests set processed_at = now(), last_error = null where user_id = :U;
select test.check(
  (select processed_at is not null and last_error is null from deletion_requests where user_id = :U),
  'row kept as audit trail after the auth user is gone');
