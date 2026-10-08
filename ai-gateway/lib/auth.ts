import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { HttpError } from './http';

export type Unavailable = { unavailable: true; reason: 'disabled' | 'quota' | 'providers' };

// Supabase client acting as the caller: anon key + their JWT, so RLS applies.
// PostgREST verifies the JWT on the first query (see rpcError).
export function userClient(req: Request): SupabaseClient {
  const auth = req.headers.get('authorization') ?? '';
  if (!/^Bearer \S+$/.test(auth)) throw new HttpError(401, 'unauthorized');
  return createClient(env('SUPABASE_URL'), env('SUPABASE_ANON_KEY'), {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

// Kill switches + membership + daily quota. Returns null when the call may proceed.
export async function consumeQuota(
  sb: SupabaseClient, messId: string, feature: string, limit: number,
): Promise<Unavailable | null> {
  if (process.env.AI_ENABLED === 'false') return { unavailable: true, reason: 'disabled' };
  const { data, error } = await sb.rpc('ai_consume', { p_mess: messId, p_feature: feature, p_limit: limit });
  if (error?.message === 'AI_DISABLED') return { unavailable: true, reason: 'disabled' };
  if (error) throw rpcError(error);
  return data === true ? null : { unavailable: true, reason: 'quota' };
}

export function rpcError(e: { code?: string; message?: string }): HttpError {
  if (e.message === 'NOT_AUTHENTICATED' || e.code?.startsWith('PGRST3') || /jwt/i.test(e.message ?? '')) {
    return new HttpError(401, 'unauthorized');
  }
  if (e.message === 'NOT_MEMBER') return new HttpError(403, 'forbidden');
  return new HttpError(502, 'database');
}

export function env(name: string): string {
  const v = process.env[name];
  if (!v) throw new HttpError(500, 'misconfigured');
  return v;
}
