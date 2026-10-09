import { createHash, createSign, timingSafeEqual } from 'node:crypto';
import type { SupabaseClient } from '@supabase/supabase-js';
import { rpcError } from './auth';
import { HttpError } from './http';

// FCM HTTP v1 sender for push_outbox (supabase/migrations/0019_push.sql).
// FIREBASE_SERVICE_ACCOUNT is the full service-account JSON; it is never logged.

const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const TOKEN_URI = 'https://oauth2.googleapis.com/token';
const CHANNEL = 'mealbazar_default';
const ROW_CONCURRENCY = 10;
const TIMEOUT_MS = 10_000;

type ServiceAccount = { client_email: string; private_key: string; project_id: string; token_uri?: string };
export type OutboxRow = { id: number; user_id: string; title: string; body: string; data: Record<string, unknown> | null; tokens: string[] | null };
export type DrainResult = { claimed: number; sent: number; failed: number; dropped_tokens: number };

export function serviceAccount(): ServiceAccount | null {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) return null;
  try {
    const sa = JSON.parse(raw) as Partial<ServiceAccount>;
    if (typeof sa.client_email === 'string' && typeof sa.private_key === 'string' && typeof sa.project_id === 'string') {
      return sa as ServiceAccount;
    }
  } catch {
    // fall through: malformed JSON (contents never logged)
  }
  return null;
}

// Constant-time compare of the dispatch secret (hashing equalises lengths).
export function secretMatches(given: string | null, expected: string): boolean {
  const h = (s: string) => createHash('sha256').update(s).digest();
  return given !== null && timingSafeEqual(h(given), h(expected));
}

// ── OAuth2: RS256 JWT bearer grant, cached until 5 min before expiry ──────
let cachedToken: { token: string; exp: number; email: string } | null = null;
export const resetPushCache = () => { cachedToken = null; };

export async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.email === sa.client_email && cachedToken.exp - 300 > now) return cachedToken.token;
  const aud = sa.token_uri ?? TOKEN_URI;
  const enc = (o: object) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const unsigned = `${enc({ alg: 'RS256', typ: 'JWT' })}.${enc({ iss: sa.client_email, scope: SCOPE, aud, iat: now, exp: now + 3600 })}`;
  const sig = createSign('RSA-SHA256').update(unsigned).sign(sa.private_key).toString('base64url');
  const res = await fetch(aud, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: `${unsigned}.${sig}` }),
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  const j = (await res.json().catch(() => ({}))) as { access_token?: string; expires_in?: number };
  if (!res.ok || !j.access_token) throw new HttpError(502, 'oauth');
  cachedToken = { token: j.access_token, exp: now + (j.expires_in ?? 3600), email: sa.client_email };
  return cachedToken.token;
}

// ── one message ───────────────────────────────────────────────────────────
type SendResult = 'ok' | 'dead' | string; // anything else = retryable error code

async function sendOne(sa: ServiceAccount, bearer: string, token: string, row: OutboxRow): Promise<SendResult> {
  // FCM data values must be strings.
  const data = Object.fromEntries(Object.entries(row.data ?? {}).map(([k, v]) => [k, String(v)]));
  try {
    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
      method: 'POST',
      headers: { authorization: `Bearer ${bearer}`, 'content-type': 'application/json' },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: row.title, body: row.body },
          data,
          android: { priority: 'high', notification: { channel_id: CHANNEL } },
        },
      }),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    if (res.ok) return 'ok';
    const err = ((await res.json().catch(() => ({}))) as {
      error?: { status?: string; details?: { errorCode?: string }[] };
    }).error;
    const code = err?.details?.find((d) => d.errorCode)?.errorCode ?? err?.status ?? `http_${res.status}`;
    if (code === 'UNREGISTERED' || code === 'INVALID_ARGUMENT') return 'dead';
    if (res.status === 401) resetPushCache(); // next run mints a fresh token
    return code;
  } catch (e) {
    return e instanceof Error && e.name === 'TimeoutError' ? 'timeout' : 'network';
  }
}

// ── drain ─────────────────────────────────────────────────────────────────
// Claims rows (push_claim), sends each to every device of its user, then:
// - any device accepted it, or the user has no live device → sent_at;
// - otherwise last_error + claim released, retried on the next run (≤ 5 tries);
// - tokens FCM calls UNREGISTERED / INVALID_ARGUMENT are deleted.
export async function drainOutbox(sb: SupabaseClient, limit: number): Promise<DrainResult> {
  const sa = serviceAccount();
  if (!sa) throw new HttpError(500, 'misconfigured');
  const { data, error } = await sb.rpc('push_claim', { p_limit: limit });
  if (error) throw rpcError(error);
  const rows = (data ?? []) as OutboxRow[];
  const result: DrainResult = { claimed: rows.length, sent: 0, failed: 0, dropped_tokens: 0 };
  if (!rows.length) return result;

  const bearer = await accessToken(sa);
  const done: number[] = [];
  const failures: { id: number; code: string }[] = [];
  const dead = new Set<string>();

  for (let i = 0; i < rows.length; i += ROW_CONCURRENCY) {
    await Promise.all(rows.slice(i, i + ROW_CONCURRENCY).map(async (row) => {
      const tokens = row.tokens ?? [];
      const results = await Promise.all(tokens.map((t) => sendOne(sa, bearer, t, row)));
      results.forEach((r, k) => { if (r === 'dead') dead.add(tokens[k]!); });
      const retry = results.find((r) => r !== 'ok' && r !== 'dead');
      if (results.includes('ok') || retry === undefined) done.push(row.id);
      else failures.push({ id: row.id, code: retry });
    }));
  }

  const now = new Date().toISOString();
  if (done.length) {
    const { error: e } = await sb.from('push_outbox').update({ sent_at: now, last_error: null }).in('id', done);
    if (e) throw rpcError(e);
  }
  for (const f of failures) {
    await sb.from('push_outbox').update({ last_error: f.code.slice(0, 80), claimed_at: null }).eq('id', f.id);
  }
  if (dead.size) {
    const { error: e } = await sb.from('device_tokens').delete().in('token', [...dead]);
    if (!e) result.dropped_tokens = dead.size;
  }
  result.sent = done.length;
  result.failed = failures.length;
  return result;
}
