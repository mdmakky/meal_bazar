import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { aiSettings, providerKeys, resetPlatformCache } from '../lib/platform';
import { generate } from '../lib/providers';
import { resetModelsCache } from '../lib/models';
import { POST as mealDraft } from '../api/ai/meal-draft';
import { POST as bazarDraft } from '../api/ai/bazar-draft';
import { GET as adminModels } from '../api/admin/models';
import { POST as testModel } from '../api/admin/test-model';

// Fake supabase: get_platform_config returns state.config (or fails), ai_consume records the quota.
const state = vi.hoisted(() => ({
  config: {} as unknown,
  configFails: false,
  secrets: {} as unknown,
  secretsFail: false,
  isAdmin: false,
  rpcCalls: [] as { fn: string; args?: Record<string, unknown>; key: string }[],
}));

vi.mock('@supabase/supabase-js', () => ({
  createClient: (_url: string, key: string) => ({
    rpc: async (fn: string, args?: Record<string, unknown>) => {
      state.rpcCalls.push({ fn, args, key });
      if (fn === 'get_platform_config') {
        return state.configFails ? { data: null, error: { message: 'boom' } } : { data: state.config, error: null };
      }
      if (fn === 'get_platform_secrets') {
        if (key !== 'service') return { data: null, error: { message: 'permission denied' } };
        return state.secretsFail ? { data: null, error: { message: 'boom' } } : { data: state.secrets, error: null };
      }
      if (fn === 'is_platform_admin') return { data: state.isAdmin, error: null };
      if (fn === 'ai_consume') return { data: false, error: null }; // quota hit: stops before any provider call
      return { data: null, error: { message: 'unexpected' } };
    },
  }),
}));

const mealBody = JSON.stringify({ mess_id: '11111111-0000-0000-0000-00000000000a', date: '2026-10-08', text: 'aj Rahim 2' });
const bazarBody = JSON.stringify({ mess_id: '11111111-0000-0000-0000-00000000000a', date: '2026-10-08', image_base64: '/9j/AA==' });
const req = (body: string) => new Request('http://x/api', { method: 'POST', body, headers: { authorization: 'Bearer t' } });
const configFetches = () => state.rpcCalls.filter((c) => c.fn === 'get_platform_config').length;

beforeEach(() => {
  vi.stubEnv('SUPABASE_URL', 'http://127.0.0.1:1');
  vi.stubEnv('SUPABASE_ANON_KEY', 'anon');
  vi.stubEnv('AI_PRIMARY_MODEL', '');
  vi.stubEnv('AI_FALLBACK_MODEL', '');
  vi.stubEnv('AI_ENABLED', '');
  vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY', 'service');
  vi.stubEnv('GEMINI_API_KEY', 'env-gemini-key');
  vi.stubEnv('OPENROUTER_API_KEY', 'env-or-key');
  vi.stubGlobal('fetch', vi.fn(() => { throw new Error('no network in tests'); }));
  vi.spyOn(console, 'warn').mockImplementation(() => {});
  state.config = {};
  state.configFails = false;
  state.rpcCalls = [];
  state.secrets = {};
  state.secretsFail = false;
  state.isAdmin = false;
  resetPlatformCache();
  resetModelsCache();
});
afterEach(() => {
  vi.unstubAllEnvs();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  vi.useRealTimers();
});

describe('platform settings', () => {
  it('returns unavailable when the platform disables a feature', async () => {
    state.config = { features: { ai_meal_draft: false } };
    expect(await (await mealDraft(req(mealBody))).json()).toEqual({ unavailable: true, reason: 'disabled' });
    expect(state.rpcCalls.map((c) => c.fn)).not.toContain('ai_consume');
    // bazar scan is still on: it reaches the quota check
    expect(await (await bazarDraft(req(bazarBody))).json()).toEqual({ unavailable: true, reason: 'quota' });
  });

  it('turns everything off when ai.enabled or features.ai is false', async () => {
    for (const config of [{ ai: { enabled: false } }, { features: { ai: false } }]) {
      state.config = config;
      resetPlatformCache();
      expect(await aiSettings()).toMatchObject({ mealDraft: false, bazarScan: false });
    }
  });

  it('lets the AI_ENABLED=false env kill switch beat the platform, without fetching config', async () => {
    vi.stubEnv('AI_ENABLED', 'false');
    state.config = { features: { ai: true }, ai: { enabled: true } };
    expect(await (await bazarDraft(req(bazarBody))).json()).toEqual({ unavailable: true, reason: 'disabled' });
    expect(configFetches()).toBe(0);
  });

  it('takes models and quotas from the platform, over env', async () => {
    vi.stubEnv('AI_PRIMARY_MODEL', 'env-primary');
    state.config = { ai: { primary_model: 'p1', fallback_model: 'f1', quota_meal_draft: 5, quota_bazar_draft: 2 } };
    const flat = { chain: [{ provider: 'gemini', model: 'p1' }, { provider: 'openrouter', model: 'f1' }], timeoutMs: 20_000, temperature: 0, allowPaid: false };
    expect(await aiSettings()).toEqual({
      mealDraft: true, bazarScan: true, quotaMealDraft: 5, quotaBazarDraft: 2, text: flat, vision: flat,
    });
    await mealDraft(req(mealBody));
    await bazarDraft(req(bazarBody));
    expect(state.rpcCalls.filter((c) => c.fn === 'ai_consume').map((c) => c.args?.p_limit)).toEqual([5, 2]);
    expect(state.rpcCalls.find((c) => c.fn === 'get_platform_config')!.key).toBe('anon');
  });

  it('caches the config for 60 s', async () => {
    vi.useFakeTimers();
    state.config = { ai: { quota_meal_draft: 5 } };
    await aiSettings();
    state.config = { ai: { quota_meal_draft: 7 } };
    vi.advanceTimersByTime(59_000);
    expect((await aiSettings()).quotaMealDraft).toBe(5);
    expect(configFetches()).toBe(1);
    vi.advanceTimersByTime(2_000);
    expect((await aiSettings()).quotaMealDraft).toBe(7);
    expect(configFetches()).toBe(2);
  });

  it('falls back to env/defaults on RPC failure, and to the last good value once it has one', async () => {
    vi.stubEnv('AI_FALLBACK_MODEL', 'env-fallback');
    state.configFails = true;
    const env = { chain: [{ provider: 'gemini', model: 'gemini-flash-latest' }, { provider: 'openrouter', model: 'env-fallback' }], timeoutMs: 20_000, temperature: 0, allowPaid: false };
    expect(await aiSettings()).toEqual({
      mealDraft: true, bazarScan: true, quotaMealDraft: 30, quotaBazarDraft: 10, text: env, vision: env,
    });

    vi.useFakeTimers();
    state.configFails = false;
    state.config = { features: { ai_bazar_scan: false }, ai: { quota_meal_draft: 3 } };
    await aiSettings();
    state.configFails = true;
    vi.advanceTimersByTime(61_000);
    expect(await aiSettings()).toMatchObject({ bazarScan: false, quotaMealDraft: 3 });
  });

  it('treats a malformed config as a failure and never logs its contents', async () => {
    state.config = { ai: { quota_meal_draft: 'lots', primary_model: 'secret-model' } };
    expect((await aiSettings()).quotaMealDraft).toBe(30);
    expect(JSON.stringify((console.warn as any).mock.calls)).not.toContain('secret-model');
  });

  it('reads v3 chains, timeout, temperature and allow_paid; chains beat the flat fields', async () => {
    const text_chain = [{ provider: 'openrouter', model: 'a:free' }, { provider: 'gemini', model: 'g2' }];
    const vision_chain = [{ provider: 'gemini', model: 'gv' }];
    state.config = { ai: { primary_model: 'p1', text_chain, vision_chain, timeout_ms: 5000, temperature: 0.2, allow_paid: true } };
    const ai = await aiSettings();
    expect(ai.text).toEqual({ chain: text_chain, timeoutMs: 5000, temperature: 0.2, allowPaid: true });
    expect(ai.vision.chain).toEqual(vision_chain);
  });

  it('rejects chains outside 1-5 entries or with unknown providers (falls back)', async () => {
    for (const text_chain of [[], Array(6).fill({ provider: 'gemini', model: 'x' }), [{ provider: 'openai', model: 'x' }]]) {
      state.config = { ai: { text_chain } };
      resetPlatformCache();
      expect((await aiSettings()).text.chain[0]).toEqual({ provider: 'gemini', model: 'gemini-flash-latest' });
    }
  });
});

describe('platform secrets', () => {
  it('uses DB keys over env, read with the service-role key', async () => {
    state.secrets = { GEMINI_API_KEY: 'db-gemini-key' };
    expect(await providerKeys()).toEqual({ gemini: 'db-gemini-key', openrouter: 'env-or-key' });
    expect(state.rpcCalls.find((c) => c.fn === 'get_platform_secrets')!.key).toBe('service');
  });

  it('falls back to the last good value, then env, on RPC failure', async () => {
    state.secretsFail = true;
    expect(await providerKeys()).toEqual({ gemini: 'env-gemini-key', openrouter: 'env-or-key' });

    vi.useFakeTimers();
    state.secretsFail = false;
    state.secrets = { OPENROUTER_API_KEY: 'db-or-key' };
    await providerKeys();
    state.secretsFail = true;
    vi.advanceTimersByTime(61_000);
    expect((await providerKeys()).openrouter).toBe('db-or-key');
  });

  it('sends the DB key to the provider and never logs keys', async () => {
    state.secrets = { GEMINI_API_KEY: 'db-gemini-key', OPENROUTER_API_KEY: 'db-or-key' };
    const fetchMock = vi.fn().mockResolvedValue(new Response('', { status: 401 }));
    vi.stubGlobal('fetch', fetchMock);
    expect(await generate({ system: 's', user: 'u' }, (x) => x)).toBeNull();
    expect(fetchMock.mock.calls[0]![1].headers['x-goog-api-key']).toBe('db-gemini-key');
    expect(fetchMock.mock.calls[1]![1].headers.authorization).toBe('Bearer db-or-key');
    const logged = JSON.stringify((console.warn as any).mock.calls);
    for (const k of ['db-gemini-key', 'db-or-key', 'env-gemini-key', 'env-or-key']) expect(logged).not.toContain(k);
  });
});

describe('admin endpoints', () => {
  const get = (q = '') => new Request(`http://x/api/admin/models${q}`, { headers: { authorization: 'Bearer t' } });
  const testReq = (body: unknown) => new Request('http://x/api/admin/test-model', { method: 'POST', body: JSON.stringify(body), headers: { authorization: 'Bearer t' } });

  it('returns 403 for non-admins and 401 without a token, before any provider call', async () => {
    expect((await adminModels(get())).status).toBe(403);
    expect((await testModel(testReq({ provider: 'gemini', model: 'g', kind: 'text' }))).status).toBe(403);
    expect((await adminModels(new Request('http://x/api/admin/models'))).status).toBe(401);
    expect(fetch).not.toHaveBeenCalled();
  });

  it('lists normalised models for admins and validates the provider', async () => {
    state.isAdmin = true;
    expect((await adminModels(get('?provider=openai'))).status).toBe(400);
    vi.stubGlobal('fetch', vi.fn(async () => Response.json({ data: [{ id: 'a:free', name: 'A', pricing: { prompt: '0', completion: '0' }, architecture: { input_modalities: ['text', 'image'] }, context_length: 8000 }] })));
    const res = await adminModels(get('?provider=openrouter'));
    expect(await res.json()).toEqual({ models: [{
      provider: 'openrouter', id: 'a:free', name: 'A', description: '', context_length: 8000,
      input_price_per_mtok: 0, output_price_per_mtok: 0, free: true, vision: true, text: true,
    }] });
  });

  it('test-model returns {ok, latency_ms, sample, error} without touching a mess quota', async () => {
    state.isAdmin = true;
    const fetchMock = vi.fn().mockResolvedValueOnce(Response.json({ candidates: [{ content: { parts: [{ text: '{"ok":true}' }] } }] }))
      .mockResolvedValueOnce(new Response('', { status: 404 }));
    vi.stubGlobal('fetch', fetchMock);
    const ok = await (await testModel(testReq({ provider: 'gemini', model: 'gemini-flash-latest', kind: 'vision' }))).json();
    expect(ok).toMatchObject({ ok: true, sample: '{"ok":true}', error: null });
    expect(ok.latency_ms).toEqual(expect.any(Number));
    expect(JSON.parse(fetchMock.mock.calls[0]![1].body).contents[0].parts[1].inline_data.mime_type).toBe('image/png');
    const bad = await (await testModel(testReq({ provider: 'openrouter', model: 'x', kind: 'text' }))).json();
    expect(bad).toMatchObject({ ok: false, sample: '', error: 'HTTP 404' });
    expect(state.rpcCalls.map((c) => c.fn)).not.toContain('ai_consume');
  });
});
