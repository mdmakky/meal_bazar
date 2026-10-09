import { afterEach, beforeEach, expect, it, vi } from 'vitest';
import { GET } from '../api/cron/midnight';

const rpc = vi.hoisted(() => vi.fn());
vi.mock('@supabase/supabase-js', () => ({ createClient: () => ({ rpc }) }));

beforeEach(() => {
  vi.stubEnv('CRON_SECRET', 's3cret');
  vi.stubEnv('SUPABASE_URL', 'http://127.0.0.1:1');
  vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY', 'service');
  rpc.mockReset();
});
afterEach(() => vi.unstubAllEnvs());

it('needs the cron secret and does nothing without it', async () => {
  expect((await GET(new Request('http://x'))).status).toBe(401);
  expect(rpc).not.toHaveBeenCalled();
});

it('runs the fill and reports how many meals it created', async () => {
  rpc.mockResolvedValue({ data: 7, error: null });
  const res = await GET(new Request('http://x', { headers: { authorization: 'Bearer s3cret' } }));
  expect(rpc).toHaveBeenCalledWith('auto_fill_meals');
  expect(await res.json()).toEqual({ filled: 7 });
});
