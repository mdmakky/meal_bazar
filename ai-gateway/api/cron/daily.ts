import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env, rpcError } from '../../lib/auth';
import { handle, HttpError, json } from '../../lib/http';

const BATCH = 50;
const CONCURRENCY = 5;

// Vercel cron, once a day:
// 1. keep-alive: one trivial query so the free Supabase project is not paused;
// 2. hard-delete auth users queued by delete_my_account() (DATABASE.md, 0007/0010).
export const GET = handle(async (req) => {
  const secret = process.env.CRON_SECRET;
  if (!secret || req.headers.get('authorization') !== `Bearer ${secret}`) throw new HttpError(401, 'unauthorized');
  const sb = createClient(env('SUPABASE_URL'), env('SUPABASE_SERVICE_ROLE_KEY'), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { error } = await sb.from('messes').select('id', { head: true }).limit(1);
  if (error) throw rpcError(error);

  const { deleted, failed } = await processDeletions(sb);
  if (deleted || failed) console.log('account deletions', { deleted, failed }); // counts only, never ids
  return json({ kept_alive: true, deleted, failed });
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
