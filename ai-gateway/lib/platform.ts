import { createClient } from '@supabase/supabase-js';
import { z } from 'zod';

// Platform settings from get_platform_config() (docs/platform-admin.md), read with the anon key.
// Precedence: AI_ENABLED=false env > platform config > env > built-in defaults.

const TTL_MS = 60_000;

const Config = z.object({
  features: z.object({ ai: z.boolean(), ai_meal_draft: z.boolean(), ai_bazar_scan: z.boolean() }).partial().optional(),
  ai: z.object({
    enabled: z.boolean(),
    primary_model: z.string().min(1),
    fallback_model: z.string().min(1),
    quota_meal_draft: z.number().int().nonnegative(),
    quota_bazar_draft: z.number().int().nonnegative(),
  }).partial().optional(),
});
type Config = z.infer<typeof Config>;

export type Models = { primary: string; fallback: string };
export type AiSettings = { mealDraft: boolean; bazarScan: boolean; models: Models; quotaMealDraft: number; quotaBazarDraft: number };

export const envModels = (): Models => ({
  primary: process.env.AI_PRIMARY_MODEL || 'gemini-flash-latest',
  fallback: process.env.AI_FALLBACK_MODEL || 'openrouter/free',
});

let cache: { value: Config; at: number } | null = null;

export function resetPlatformCache() {
  cache = null;
}

async function loadConfig(): Promise<Config | null> {
  if (cache && Date.now() - cache.at < TTL_MS) return cache.value;
  try {
    const url = process.env.SUPABASE_URL, key = process.env.SUPABASE_ANON_KEY;
    if (!url || !key) throw new Error('no env');
    const sb = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data, error } = await sb.rpc('get_platform_config');
    if (error) throw new Error('rpc');
    cache = { value: Config.parse(data), at: Date.now() };
    return cache.value;
  } catch (e) {
    // Never log the config itself. ponytail: failures aren't cached, so a down DB costs one RPC per request.
    console.warn(`platform config unavailable: ${e instanceof Error ? e.name : typeof e}`);
    return cache?.value ?? null; // last good value, however stale, else env defaults
  }
}

export async function aiSettings(): Promise<AiSettings> {
  const env = envModels();
  if (process.env.AI_ENABLED === 'false') {
    // Kill switch: no config fetch at all.
    return { mealDraft: false, bazarScan: false, models: env, quotaMealDraft: 30, quotaBazarDraft: 10 };
  }
  const c = await loadConfig();
  const f = c?.features ?? {}, ai = c?.ai ?? {};
  const on = (ai.enabled ?? true) && (f.ai ?? true);
  return {
    mealDraft: on && (f.ai_meal_draft ?? true),
    bazarScan: on && (f.ai_bazar_scan ?? true),
    models: { primary: ai.primary_model ?? env.primary, fallback: ai.fallback_model ?? env.fallback },
    quotaMealDraft: ai.quota_meal_draft ?? 30,
    quotaBazarDraft: ai.quota_bazar_draft ?? 10,
  };
}
