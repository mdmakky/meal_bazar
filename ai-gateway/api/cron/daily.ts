import { createClient } from '@supabase/supabase-js';
import { env, rpcError } from '../../lib/auth';
import { handle, HttpError, json } from '../../lib/http';

// Vercel cron keep-alive: one trivial query so the free Supabase project is not paused.
export const GET = handle(async (req) => {
  const secret = process.env.CRON_SECRET;
  if (!secret || req.headers.get('authorization') !== `Bearer ${secret}`) throw new HttpError(401, 'unauthorized');
  const sb = createClient(env('SUPABASE_URL'), env('SUPABASE_SERVICE_ROLE_KEY'), { auth: { persistSession: false } });
  const { error } = await sb.from('messes').select('id', { head: true }).limit(1);
  if (error) throw rpcError(error);
  return json({ ok: true });
});
