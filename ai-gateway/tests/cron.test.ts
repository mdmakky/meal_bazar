import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { GET as cron } from '../api/cron/daily';

// Fake service-role client: keep-alive select, queue select, row updates, auth admin delete.
const state = vi.hoisted(() => ({
  queue: [] as { user_id: string }[],
  deleteResult: {} as Record<string, { status?: number; code?: string } | null>,
  updates: [] as { values: Record<string, unknown>; id: string }[],
  keepAliveError: null as unknown,
}));

vi.mock('@supabase/supabase-js', () => {
  const builder = (table: string) => {
    const q: any = {
      select: () => q, is: () => q, order: () => q,
      limit: () => Promise.resolve(table === 'messes'
        ? { error: state.keepAliveError }
        : { data: state.queue, error: null }),
      update: (values: Record<string, unknown>) => ({
        eq: (_col: string, id: string) => {
          state.updates.push({ values, id });
          return Promise.resolve({ error: null });
        },
      }),
    };
    return q;
  };
  return {
    createClient: () => ({
      from: builder,
      auth: { admin: { deleteUser: vi.fn(async (id: string) => ({ data: {}, error: state.deleteResult[id] ?? null })) } },
    }),
  };
});

const authed = () => new Request('http://x/api/cron/daily', { headers: { authorization: 'Bearer s3cret' } });

beforeEach(() => {
  vi.stubEnv('CRON_SECRET', 's3cret');
  vi.stubEnv('SUPABASE_URL', 'http://127.0.0.1:1');
  vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY', 'service');
  state.queue = [];
  state.deleteResult = {};
  state.updates = [];
  state.keepAliveError = null;
});
afterEach(() => vi.unstubAllEnvs());

describe('daily cron', () => {
  it('rejects a missing or wrong secret before touching the queue', async () => {
    state.queue = [{ user_id: 'u1' }];
    expect((await cron(new Request('http://x'))).status).toBe(401);
    expect((await cron(new Request('http://x', { headers: { authorization: 'Bearer nope' } }))).status).toBe(401);
    expect(state.updates).toEqual([]);
  });

  it('keeps alive with an empty queue', async () => {
    expect(await (await cron(authed())).json()).toEqual({ kept_alive: true, deleted: 0, failed: 0, duty_reminders: 0, push: null });
  });

  it('deletes queued users, marks successes, records failures and continues', async () => {
    state.queue = Array.from({ length: 7 }, (_, i) => ({ user_id: `u${i}` }));
    state.deleteResult = {
      u2: { status: 500, code: 'unexpected_failure' },
      u5: { status: 404, code: 'user_not_found' }, // already gone = success
    };
    const res = await cron(authed());
    expect(await res.json()).toEqual({ kept_alive: true, deleted: 6, failed: 1, duty_reminders: 0, push: null });

    const byId = Object.fromEntries(state.updates.map((u) => [u.id, u.values]));
    expect(Object.keys(byId)).toHaveLength(7);
    expect(byId.u2).toMatchObject({ last_error: 'unexpected_failure' });
    expect(byId.u2).not.toHaveProperty('processed_at');
    for (const id of ['u0', 'u1', 'u3', 'u4', 'u5', 'u6']) {
      expect(byId[id]).toMatchObject({ last_error: null });
      expect(byId[id]!.processed_at).toEqual(expect.any(String));
    }
  });

  it('fails loudly when the keep-alive query fails', async () => {
    state.keepAliveError = { message: 'boom' };
    expect((await cron(authed())).status).toBe(502);
  });
});
