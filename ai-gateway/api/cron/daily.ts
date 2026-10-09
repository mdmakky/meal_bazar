import type { SupabaseClient } from '@supabase/supabase-js';
import { rpcError, serviceClient } from '../../lib/auth';
import { handle, HttpError, json } from '../../lib/http';
import { drainOutbox, serviceAccount, type DrainResult } from '../../lib/push';

const BATCH = 50;
const CONCURRENCY = 5;
const PUSH_BATCH = 500;

// Vercel cron, once a day:
// 1. keep-alive: one trivial query so the free Supabase project is not paused;
// 2. hard-delete auth users queued by delete_my_account() (DATABASE.md, 0007/0010);
// 3. queue today's bazar-duty reminders (send_duty_reminders, 0028; 03:00 UTC = 09:00 Dhaka);
// 4. automatic due reminders to members in debt (send_auto_due_reminders, 0030);
// 5. prune messages and audit rows older than 2 months (prune_old_data, 0029);
// 6. send push_outbox leftovers (a missed pg_net kick); skipped without FIREBASE_SERVICE_ACCOUNT.
export const GET = handle(async (req) => {
  const secret = process.env.CRON_SECRET;
  if (!secret || req.headers.get('authorization') !== `Bearer ${secret}`) throw new HttpError(401, 'unauthorized');
  const sb = serviceClient();
  const { error } = await sb.from('messes').select('id', { head: true }).limit(1);
  if (error) throw rpcError(error);

  const { deleted, failed } = await processDeletions(sb);
  if (deleted || failed) console.log('account deletions', { deleted, failed }); // counts only, never ids

  // Reminders are a nicety: a failure never stops the rest of the run.
  let dutyReminders = 0;
  try {
    const { data, error } = await sb.rpc('send_duty_reminders');
    if (error) console.log('duty reminders failed', error.code);
    else dutyReminders = Number(data ?? 0);
  } catch {
    console.log('duty reminders failed');
  }

  // Automatic due reminders (send_auto_due_reminders, 0030).
  let dueReminders = 0;
  try {
    const { data, error } = await sb.rpc('send_auto_due_reminders');
    if (error) console.log('due reminders failed', error.code);
    else dueReminders = Number(data ?? 0);
  } catch {
    console.log('due reminders failed');
  }

  let pruned: unknown = null;
  try {
    const { data, error } = await sb.rpc('prune_old_data');
    if (error) console.log('prune failed', error.code);
    else pruned = data;
  } catch {
    console.log('prune failed');
  }

  let push: DrainResult | { error: string } | null = null;
  if (serviceAccount()) {
    try {
      push = await drainOutbox(sb, PUSH_BATCH);
    } catch (e) {
      push = { error: e instanceof HttpError ? e.code : 'internal' }; // never undoes the work above
    }
  }
  return json({ kept_alive: true, deleted, failed, duty_reminders: dutyReminders, due_reminders: dueReminders, pruned, push });
});

async function processDeletions(sb: SupabaseClient) {
  const { data, error } = await sb
    .from('deletion_requests')
    .select('user_id')
    .is('processed_at', null)
    .order('last_attempt_at', { ascending: true, nullsFirst: true }) // failures retry after fresh rows
    .order('requested_at', { ascending: true })
    .limit(BATCH);
  if (error) throw rpcError(error);

  let deleted = 0;
  let failed = 0;
  const rows = data ?? [];
  for (let i = 0; i < rows.length; i += CONCURRENCY) {
    const results = await Promise.all(rows.slice(i, i + CONCURRENCY).map((r) => deleteOne(sb, r.user_id as string)));
    for (const ok of results) ok ? deleted++ : failed++;
  }
  return { deleted, failed };
}

async function deleteOne(sb: SupabaseClient, userId: string): Promise<boolean> {
  const now = new Date().toISOString();
  let lastError: string | null = null;
  try {
    const { error } = await sb.auth.admin.deleteUser(userId);
    // Already gone (deleted from the dashboard, or a previous run died before marking) = done.
    if (error && error.status !== 404 && error.code !== 'user_not_found') lastError = error.code ?? `http_${error.status ?? 'unknown'}`;
  } catch (e) {
    lastError = e instanceof Error ? e.name : 'exception';
  }
  const { error } = await sb
    .from('deletion_requests')
    .update(lastError ? { last_error: lastError, last_attempt_at: now } : { processed_at: now, last_error: null, last_attempt_at: now })
    .eq('user_id', userId);
  // A failed mark after a successful delete is retried next run and then hits "not found".
  return !lastError && !error;
}
