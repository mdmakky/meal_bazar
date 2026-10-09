import { createClient } from '@supabase/supabase-js';
import { z } from 'zod';

// Platform settings (docs/platform-admin.md), cached in module memory for 60 s:
// - get_platform_config() with the anon key: features + ai settings.
// - get_platform_secrets() with the service-role key: provider API keys.
// Precedence: AI_ENABLED=false env > platform config/secrets > env > built-in defaults.
// On an RPC failure the last good value is used, else env/defaults. Contents are never logged.

const TTL_MS = 60_000;

const Provider = z.enum(['gemini', 'openrouter']);
const Chain = z.array(z.object({ provider: Provider, model: z.string().min(1) })).min(1).max(5);
export type ChainEntry = z.infer<typeof Chain>[number];

// Unknown keys are dropped and missing keys count as defaults.
const Config = z.object({
  features: z.object({ ai: z.boolean(), ai_meal_draft: z.boolean(), ai_bazar_scan: z.boolean() }).partial().optional(),
  ai: z.object({
    enabled: z.boolean(),
    text_chain: Chain,
    vision_chain: Chain,
    primary_model: z.string().min(1), // pre-v3 flat fields, fallback for the chains
    fallback_model: z.string().min(1),
    quota_meal_draft: z.number().int().nonnegative(),
    quota_bazar_draft: z.number().int().nonnegative(),
    timeout_ms: z.number().int().min(1000).max(60_000),
    temperature: z.number().min(0).max(2),
    allow_paid: z.boolean(),
  }).partial().optional(),
}).nullable();

const Secrets = z.object({
  GEMINI_API_KEY: z.string().min(1), OPENROUTER_API_KEY: z.string().min(1), PUSH_DISPATCH_SECRET: z.string().min(1),
}).partial().nullable();

function cachedRpc<T>(fn: string, keyEnv: string, schema: z.ZodType<T>) {
  let cache: { value: T; at: number } | null = null;
  const load = async (): Promise<T | null> => {
    if (cache && Date.now() - cache.at < TTL_MS) return cache.value;
    try {
      const url = process.env.SUPABASE_URL, key = process.env[keyEnv];
      if (!url || !key) throw new Error('no env');
      const sb = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
      const { data, error } = await sb.rpc(fn);
      if (error) throw new Error('rpc');
      cache = { value: schema.parse(data), at: Date.now() };
      return cache.value;
    } catch (e) {
      // Only the error kind: zod messages could echo config values or secrets.
      // ponytail: failures aren't cached, so a down DB costs one RPC per request.
      const why = e instanceof Error && (e.message === 'no env' || e.message === 'rpc') ? e.message : (e as Error)?.name;
      console.warn(`${fn} unavailable: ${why}`);
      return cache?.value ?? null;
    }
  };
  load.reset = () => { cache = null; };
  return load;
}

const loadConfig = cachedRpc('get_platform_config', 'SUPABASE_ANON_KEY', Config);
const loadSecrets = cachedRpc('get_platform_secrets', 'SUPABASE_SERVICE_ROLE_KEY', Secrets);

export function resetPlatformCache() {
  loadConfig.reset();
  loadSecrets.reset();
}

export type GenOptions = { chain: ChainEntry[]; timeoutMs: number; temperature: number; allowPaid: boolean };
export type AiSettings = {
  mealDraft: boolean; bazarScan: boolean; quotaMealDraft: number; quotaBazarDraft: number;
  text: GenOptions; vision: GenOptions;
};

const envChain = (primary?: string, fallback?: string): ChainEntry[] => [
  { provider: 'gemini', model: primary || process.env.AI_PRIMARY_MODEL || 'gemini-flash-latest' },
  { provider: 'openrouter', model: fallback || process.env.AI_FALLBACK_MODEL || 'openrouter/free' },
];

// Used when no platform settings apply (tests, direct generate() calls).
export const envOptions = (): GenOptions => ({ chain: envChain(), timeoutMs: 20_000, temperature: 0, allowPaid: false });

export async function aiSettings(): Promise<AiSettings> {
  const killed = process.env.AI_ENABLED === 'false';
  const c = killed ? null : await loadConfig(); // kill switch: no config fetch at all
  const f = c?.features ?? {}, ai = c?.ai ?? {};
  const on = !killed && (ai.enabled ?? true) && (f.ai ?? true);
  const flat = envChain(ai.primary_model, ai.fallback_model);
  const opts = (chain?: ChainEntry[]): GenOptions => ({
    chain: chain ?? flat,
    timeoutMs: ai.timeout_ms ?? 20_000,
    temperature: ai.temperature ?? 0,
    allowPaid: ai.allow_paid ?? false,
  });
  return {
    mealDraft: on && (f.ai_meal_draft ?? true),
    bazarScan: on && (f.ai_bazar_scan ?? true),
    quotaMealDraft: ai.quota_meal_draft ?? 30,
    quotaBazarDraft: ai.quota_bazar_draft ?? 10,
    text: opts(ai.text_chain),
    vision: opts(ai.vision_chain),
  };
}

// Provider keys: DB secret > env. Missing → undefined (that provider is skipped).
export async function providerKeys(): Promise<{ gemini?: string; openrouter?: string }> {
  const s = await loadSecrets();
  return {
    gemini: s?.GEMINI_API_KEY || process.env.GEMINI_API_KEY || undefined,
    openrouter: s?.OPENROUTER_API_KEY || process.env.OPENROUTER_API_KEY || undefined,
  };
}

// Shared secret the DB sends to /api/push/dispatch: DB secret > env. Missing → undefined (endpoint refuses).
export async function pushDispatchSecret(): Promise<string | undefined> {
  return (await loadSecrets())?.PUSH_DISPATCH_SECRET || process.env.PUSH_DISPATCH_SECRET || undefined;
}
