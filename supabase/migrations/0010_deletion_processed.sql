-- 0010_deletion_processed: the daily cron (ai-gateway/api/cron/daily.ts) hard-deletes
-- queued auth users. Rows are kept as the audit trail of the hard delete, so the FK
-- (which cascaded the row away with the auth user) is dropped; the id is all that is left.
alter table public.deletion_requests
  drop constraint deletion_requests_user_id_fkey,
  add column processed_at    timestamptz,   -- auth user gone (or already absent)
  add column last_error      text,          -- last failure code, cleared on success
  add column last_attempt_at timestamptz;   -- failed rows go to the back of the queue

create index deletion_requests_pending_idx on public.deletion_requests (last_attempt_at nulls first, requested_at)
  where processed_at is null;
