import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { POST as mealDraft } from '../api/ai/meal-draft';
import { POST as bazarDraft } from '../api/ai/bazar-draft';
import { GET as cron } from '../api/cron/daily';

const body = JSON.stringify({ mess_id: '11111111-0000-0000-0000-00000000000a', date: '2026-10-08', text: 'aj Rahim 2' });
const post = (headers: Record<string, string> = {}) => new Request('http://x/api', { method: 'POST', body, headers });

beforeEach(() => {
  vi.stubEnv('SUPABASE_URL', 'http://127.0.0.1:1');
  vi.stubEnv('SUPABASE_ANON_KEY', 'anon');
  vi.stubGlobal('fetch', vi.fn(() => { throw new Error('no network in tests'); }));
});
afterEach(() => {
  vi.unstubAllEnvs();
  vi.unstubAllGlobals();
});

describe('auth', () => {
  it('rejects requests without a bearer token', async () => {
    for (const res of [await mealDraft(post()), await bazarDraft(post()), await mealDraft(post({ authorization: 'Basic abc' }))]) {
      expect(res.status).toBe(401);
      expect(await res.json()).toEqual({ error: 'unauthorized' });
    }
    expect(fetch).not.toHaveBeenCalled();
  });

  it('rejects oversized bodies', async () => {
    const res = await mealDraft(new Request('http://x', { method: 'POST', body: 'x'.repeat(9000), headers: { authorization: 'Bearer t' } }));
    expect(res.status).toBe(413);
  });

  it('honours the AI_ENABLED kill switch before any database call', async () => {
    vi.stubEnv('AI_ENABLED', 'false');
    const res = await mealDraft(post({ authorization: 'Bearer t' }));
    expect(await res.json()).toEqual({ unavailable: true, reason: 'disabled' });
    expect(fetch).not.toHaveBeenCalled();
  });

  it('protects the cron with CRON_SECRET', async () => {
    vi.stubEnv('CRON_SECRET', 's3cret');
    expect((await cron(new Request('http://x'))).status).toBe(401);
    expect((await cron(new Request('http://x', { headers: { authorization: 'Bearer wrong' } }))).status).toBe(401);
  });
});
