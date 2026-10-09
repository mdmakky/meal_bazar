import { providerKeys } from './platform';

// Provider model lists for the admin panel and the allow_paid check, cached 10 min per provider.

export type Provider = 'gemini' | 'openrouter';
export type ModelInfo = {
  provider: Provider; id: string; name: string; description: string; context_length: number | null;
  input_price_per_mtok: number | null; output_price_per_mtok: number | null; free: boolean; vision: boolean; text: boolean;
};

const TTL_MS = 10 * 60_000;
const cache = new Map<Provider, { value: ModelInfo[]; at: number }>();
export const resetModelsCache = () => cache.clear();

async function getJson(url: string, headers: Record<string, string>): Promise<any> {
  const res = await fetch(url, { headers, signal: AbortSignal.timeout(15_000) });
  if (!res.ok) throw new Error(`HTTP ${res.status}`); // never the URL or headers (keys)
  return res.json();
}

const perMtok = (usdPerToken: unknown) => {
  const n = Number(usdPerToken);
  return usdPerToken == null || usdPerToken === '' || !Number.isFinite(n) ? null : n * 1e6;
};

// https://openrouter.ai/docs/api-reference/list-available-models
export function normalizeOpenRouter(m: any): ModelInfo {
  const input = perMtok(m?.pricing?.prompt), output = perMtok(m?.pricing?.completion);
  const modalities: string[] = m?.architecture?.input_modalities ?? [];
  return {
    provider: 'openrouter',
    id: String(m.id),
    name: String(m.name ?? m.id),
    description: String(m.description ?? ''),
    context_length: typeof m.context_length === 'number' ? m.context_length : null,
    input_price_per_mtok: input,
    output_price_per_mtok: output,
    free: input === 0 && output === 0,
    vision: modalities.includes('image'),
    text: modalities.length === 0 || modalities.includes('text'),
  };
}

// https://ai.google.dev/api/models#method:-models.list. Free tier assumed, price unknown.
export function normalizeGemini(m: any): ModelInfo {
  const id = String(m.name).replace(/^models\//, '');
  return {
    provider: 'gemini',
    id,
    name: String(m.displayName ?? id),
    description: String(m.description ?? ''),
    context_length: typeof m.inputTokenLimit === 'number' ? m.inputTokenLimit : null,
    input_price_per_mtok: null,
    output_price_per_mtok: null,
    free: true,
    vision: /^gemini-/.test(id) && (/^gemini-(1\.5|[2-9])/.test(id) || /flash|pro/.test(id)),
    text: true,
  };
}

async function fetchModels(provider: Provider): Promise<ModelInfo[]> {
  const keys = await providerKeys();
  if (provider === 'openrouter') {
    const auth: Record<string, string> = keys.openrouter ? { authorization: `Bearer ${keys.openrouter}` } : {};
    const data = await getJson('https://openrouter.ai/api/v1/models', auth); // public list; key optional
    return (data?.data ?? []).map(normalizeOpenRouter);
  }
  if (!keys.gemini) return [];
  const out: ModelInfo[] = [];
  let page = '';
  do { // key in a header, not ?key=, so it can't leak via URLs
    const data = await getJson(
      `https://generativelanguage.googleapis.com/v1beta/models?pageSize=1000${page && `&pageToken=${encodeURIComponent(page)}`}`,
      { 'x-goog-api-key': keys.gemini },
    );
    for (const m of data?.models ?? []) {
      if ((m.supportedGenerationMethods ?? []).includes('generateContent')) out.push(normalizeGemini(m));
    }
    page = data?.nextPageToken ?? '';
  } while (page);
  return out;
}

export async function listModels(provider: Provider): Promise<ModelInfo[]> {
  const hit = cache.get(provider);
  if (hit && Date.now() - hit.at < TTL_MS) return hit.value;
  const value = await fetchModels(provider);
  cache.set(provider, { value, at: Date.now() });
  return value;
}

// allow_paid=false guard. Name rule first (no lookup), then the cached list; unknown pricing = paid.
export async function isPaidOpenRouter(model: string): Promise<boolean> {
  if (model === 'openrouter/free' || model.endsWith(':free')) return false;
  try {
    const m = (await listModels('openrouter')).find((x) => x.id === model);
    return !m?.free;
  } catch {
    return true;
  }
}
