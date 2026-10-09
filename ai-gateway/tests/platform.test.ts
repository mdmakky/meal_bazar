import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { aiSettings, resetPlatformCache } from '../lib/platform';
import { POST as mealDraft } from '../api/ai/meal-draft';
import { POST as bazarDraft } from '../api/ai/bazar-draft';

// Fake supabase: get_platform_config returns state.config (or fails), ai_consume records the quota.
const state = vi.hoisted(() => ({
  config: {} as unknown,
  configFails: false,
  rpcCalls: [] as { fn: string; args?: Record<string, unknown>; key: string }[],
}));

vi.mock('@supabase/supabase-js', () => ({
  createClient: (_url: string, key: string) => ({
    rpc: async (fn: string, args?: Record<string, unknown>) => {
      state.rpcCalls.push({ fn, args, key });
      if (fn === 'get_platform_config') {
        return state.configFails ? { data: null, error: { message: 'boom' } } : { data: state.config, error: null };
      }
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
  vi.spyOn(console, 'warn').mockImplementation(() => {});
  state.config = {};
  state.configFails = false;
  state.rpcCalls = [];
  resetPlatformCache();
});
afterEach(() => {
  vi.unstubAllEnvs();
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
    expect(await aiSettings()).toEqual({
      mealDraft: true, bazarScan: true, models: { primary: 'p1', fallback: 'f1' }, quotaMealDraft: 5, quotaBazarDraft: 2,
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
    expect(await aiSettings()).toEqual({
      mealDraft: true, bazarScan: true, models: { primary: 'gemini-flash-latest', fallback: 'env-fallback' },
      quotaMealDraft: 30, quotaBazarDraft: 10,
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
});
