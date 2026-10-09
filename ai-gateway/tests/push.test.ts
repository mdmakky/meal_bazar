import { createVerify, generateKeyPairSync } from 'node:crypto';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { POST as dispatch } from '../api/push/dispatch';
import { GET as cron } from '../api/cron/daily';
import { resetPlatformCache } from '../lib/platform';
import { resetPushCache, secretMatches } from '../lib/push';

// Fake service-role Supabase: push_claim hands out state.rows; writes are recorded.
const state = vi.hoisted(() => ({
  rows: [] as unknown[],
  claims: 0,
  secrets: {} as Record<string, string>,
  sentIds: [] as number[],
  failures: [] as { id: number; values: Record<string, unknown> }[],
  deletedTokens: [] as string[],
}));

vi.mock('@supabase/supabase-js', () => ({
  createClient: () => ({
    rpc: async (fn: string) => {
      if (fn === 'get_platform_secrets') return { data: state.secrets, error: null };
      if (fn === 'push_claim') {
        state.claims++;
        const rows = state.rows;
        state.rows = [];
        return { data: rows, error: null };
      }
      return { data: null, error: { message: 'unexpected' } };
    },
    from: (table: string) => {
      const q: any = {
        select: () => q, is: () => q, order: () => q,
        limit: () => Promise.resolve(table === 'messes' ? { error: null } : { data: [], error: null }),
        update: (values: Record<string, unknown>) => ({
          in: (_c: string, ids: number[]) => { state.sentIds.push(...ids); return Promise.resolve({ error: null }); },
          eq: (_c: string, id: number) => { state.failures.push({ id, values }); return Promise.resolve({ error: null }); },
        }),
        delete: () => ({
          in: (_c: string, tokens: string[]) => { state.deletedTokens.push(...tokens); return Promise.resolve({ error: null }); },
        }),
      };
      return q;
    },
  }),
}));

const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const sa = {
  type: 'service_account',
  project_id: 'meal-bazar-bd869',
  client_email: 'push@meal-bazar-bd869.iam.gserviceaccount.com',
  private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }).toString(),
};

// Fake Google: OAuth token endpoint + FCM send. fcm[token] = [status, errorCode?].
let fcm: Record<string, [number, string?]> = {};
let oauthCalls: string[] = [];
let sends: { token: string; message: any; auth: string | null }[] = [];
const fetchMock = vi.fn(async (url: string | URL, init?: RequestInit) => {
  const u = String(url);
  if (u === 'https://oauth2.googleapis.com/token') {
    oauthCalls.push(new URLSearchParams(String(init?.body)).get('assertion')!);
    return Response.json({ access_token: `at-${oauthCalls.length}`, expires_in: 3600, token_type: 'Bearer' });
  }
  if (u === 'https://fcm.googleapis.com/v1/projects/meal-bazar-bd869/messages:send') {
    const { message } = JSON.parse(String(init?.body));
    sends.push({ token: message.token, message, auth: new Headers(init?.headers).get('authorization') });
    const [status, code] = fcm[message.token] ?? [200];
    if (status === 200) return Response.json({ name: 'projects/x/messages/1' });
    return Response.json({
      error: { code: status, status: code === 'UNREGISTERED' ? 'NOT_FOUND' : code,
               details: code ? [{ '@type': 'type.googleapis.com/google.firebase.fcm.v1.FcmError', errorCode: code }] : [] },
    }, { status });
  }
  throw new Error(`unexpected fetch ${u}`);
});

const row = (id: number, tokens: string[]) => ({
  id, user_id: `u${id}`, title: 'নতুন বাজার', body: 'Push Mess: ৳৩০০', data: { route: '/bazar', type: 'bazar_added' }, tokens,
});
const poke = (secret?: string) =>
  dispatch(new Request('http://x/api/push/dispatch', { method: 'POST', headers: secret ? { 'x-push-secret': secret } : {} }));

beforeEach(() => {
  vi.stubEnv('SUPABASE_URL', 'http://127.0.0.1:1');
  vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY', 'service');
  vi.stubEnv('CRON_SECRET', 'cron');
  vi.stubEnv('FIREBASE_SERVICE_ACCOUNT', JSON.stringify(sa));
  vi.stubEnv('PUSH_DISPATCH_SECRET', 'env-secret');
  vi.stubGlobal('fetch', fetchMock);
  Object.assign(state, { rows: [], claims: 0, secrets: {}, sentIds: [], failures: [], deletedTokens: [] });
  fcm = {}; oauthCalls = []; sends = [];
  resetPlatformCache();
  resetPushCache();
});
afterEach(() => {
  vi.unstubAllEnvs();
  vi.unstubAllGlobals();
  vi.useRealTimers();
});

describe('push dispatch', () => {
  it('refuses a missing or wrong secret before claiming anything', async () => {
    state.rows = [row(1, ['t1'])];
    expect((await poke()).status).toBe(401);
    expect((await poke('nope')).status).toBe(401);
    expect(state.claims).toBe(0);
    expect(sends).toEqual([]);
  });

  it('prefers the DB secret over the env var', async () => {
    state.secrets = { PUSH_DISPATCH_SECRET: 'db-secret' };
    expect((await poke('env-secret')).status).toBe(401);
    expect((await poke('db-secret')).status).toBe(200);
  });

  it('refuses everything when no secret is configured', async () => {
    vi.stubEnv('PUSH_DISPATCH_SECRET', '');
    expect((await poke('')).status).toBe(401);
  });

  it('compares secrets of any length safely', () => {
    expect(secretMatches('abc', 'abc')).toBe(true);
    expect(secretMatches('abcd', 'abc')).toBe(false);
    expect(secretMatches(null, 'abc')).toBe(false);
  });

  it('sends FCM v1 messages, marks results, drops dead tokens, keeps retryable failures', async () => {
    fcm = { dead1: [404, 'UNREGISTERED'], bad1: [400, 'INVALID_ARGUMENT'], busy1: [503, 'UNAVAILABLE'] };
    state.rows = [
      row(1, ['ok1', 'dead1']), // one device works → sent; the dead one is dropped
      row(2, ['bad1']),         // only dead devices → done, nothing to retry
      row(3, ['busy1']),        // transient → retried later
      row(4, []),               // no device → done
    ];
    const res = await poke('env-secret');
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ claimed: 4, sent: 3, failed: 1, dropped_tokens: 2 });
    expect(state.sentIds.sort()).toEqual([1, 2, 4]);
    expect(state.failures).toEqual([{ id: 3, values: { last_error: 'UNAVAILABLE', claimed_at: null } }]);
    expect(state.deletedTokens.sort()).toEqual(['bad1', 'dead1']);

    const ok = sends.find((s) => s.token === 'ok1')!;
    expect(ok.auth).toBe('Bearer at-1');
    expect(ok.message).toEqual({
      token: 'ok1',
      notification: { title: 'নতুন বাজার', body: 'Push Mess: ৳৩০০' },
      data: { route: '/bazar', type: 'bazar_added' },
      android: { priority: 'high', notification: { channel_id: 'mealbazar_default' } },
    });
  });

  it('sets the Android tag and collapse key from data.tag', async () => {
    state.rows = [{ ...row(1, ['g1']), data: { route: '/more/messages/th', type: 'group_message', tag: 'th' } }];
    await poke('env-secret');
    expect(sends[0]!.message.android).toEqual({
      priority: 'high', collapse_key: 'th', notification: { channel_id: 'mealbazar_default', tag: 'th' },
    });
    expect(sends[0]!.message.data.tag).toBe('th');
  });

  it('mints the OAuth token with an RS256 JWT from the service account', async () => {
    state.rows = [row(1, ['ok1'])];
    await poke('env-secret');
    expect(oauthCalls).toHaveLength(1);
    const [h, c, sig] = oauthCalls[0]!.split('.');
    expect(JSON.parse(Buffer.from(h!, 'base64url').toString())).toEqual({ alg: 'RS256', typ: 'JWT' });
    const claims = JSON.parse(Buffer.from(c!, 'base64url').toString());
    expect(claims).toMatchObject({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
    });
    expect(claims.exp - claims.iat).toBe(3600);
    expect(createVerify('RSA-SHA256').update(`${h}.${c}`).verify(publicKey, Buffer.from(sig!, 'base64url'))).toBe(true);
  });

  it('caches the access token until 5 minutes before expiry', async () => {
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(new Date('2026-10-09T00:00:00Z'));
    state.rows = [row(1, ['ok1'])];
    await poke('env-secret');
    vi.setSystemTime(new Date('2026-10-09T00:54:00Z')); // 54 min: still cached
    state.rows = [row(2, ['ok1'])];
    await poke('env-secret');
    expect(oauthCalls).toHaveLength(1);
    vi.setSystemTime(new Date('2026-10-09T00:55:01Z')); // inside the last 5 min: refresh
    state.rows = [row(3, ['ok1'])];
    await poke('env-secret');
    expect(oauthCalls).toHaveLength(2);
    expect(sends.at(-1)!.auth).toBe('Bearer at-2');
  });

  it('drops the cached token when FCM says 401', async () => {
    fcm = { stale: [401, 'UNAUTHENTICATED'] };
    state.rows = [row(1, ['stale'])];
    await poke('env-secret');
    state.rows = [row(2, ['ok1'])];
    await poke('env-secret');
    expect(oauthCalls).toHaveLength(2);
  });

  it('does not mint a token when there is nothing to send', async () => {
    expect(await (await poke('env-secret')).json()).toEqual({ claimed: 0, sent: 0, failed: 0, dropped_tokens: 0 });
    expect(oauthCalls).toEqual([]);
  });

  it('is misconfigured without a usable service account', async () => {
    vi.stubEnv('FIREBASE_SERVICE_ACCOUNT', '{not json');
    const res = await poke('env-secret');
    expect(res.status).toBe(500);
    expect(await res.json()).toEqual({ error: 'misconfigured' });
  });
});

describe('daily cron drains the outbox', () => {
  const run = () => cron(new Request('http://x/api/cron/daily', { headers: { authorization: 'Bearer cron' } }));

  it('sends leftovers', async () => {
    state.rows = [row(1, ['ok1'])];
    expect(await (await run()).json()).toEqual({
      kept_alive: true, deleted: 0, failed: 0, duty_reminders: 0, pruned: null, push: { claimed: 1, sent: 1, failed: 0, dropped_tokens: 0 },
    });
  });

  it('skips push without a service account', async () => {
    vi.stubEnv('FIREBASE_SERVICE_ACCOUNT', '');
    expect((await (await run()).json()).push).toBeNull();
    expect(state.claims).toBe(0);
  });

  it('reports a push failure without failing the cron', async () => {
    fetchMock.mockImplementationOnce(async () => Response.json({ error: 'invalid_grant' }, { status: 400 }));
    state.rows = [row(1, ['ok1'])];
    const res = await run();
    expect(res.status).toBe(200);
    expect((await res.json()).push).toEqual({ error: 'oauth' });
  });
});
