// Provider chain: walks the configured chain (lib/platform.ts) in order → null ("AI unavailable").
// Plain fetch, timeout_ms each. Any failure (HTTP error, timeout, bad JSON, schema rejection)
// moves to the next entry. With allow_paid=false, paid OpenRouter models are skipped.

import { isPaidOpenRouter } from './models';
import { envOptions, providerKeys, type ChainEntry, type GenOptions } from './platform';

export type Prompt = { system: string; user: string; imageBase64?: string; imageMime?: string };
type CallOpts = { key?: string; timeoutMs: number; temperature: number };

async function post(url: string, headers: Record<string, string>, body: unknown, timeoutMs: number): Promise<any> {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...headers },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(timeoutMs),
  });
  // Only the status is surfaced: provider error bodies can echo the user's input.
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

// https://ai.google.dev/api/generate-content
async function gemini(p: Prompt, model: string, o: CallOpts): Promise<string> {
  if (!o.key) throw new Error('no key');
  const parts: unknown[] = [{ text: p.user }];
  if (p.imageBase64) parts.push({ inline_data: { mime_type: p.imageMime ?? 'image/jpeg', data: p.imageBase64 } });
  const data = await post(
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
    { 'x-goog-api-key': o.key },
    {
      system_instruction: { parts: [{ text: p.system }] },
      contents: [{ role: 'user', parts }],
      generationConfig: { responseMimeType: 'application/json', temperature: o.temperature },
    },
    o.timeoutMs,
  );
  return (data?.candidates?.[0]?.content?.parts ?? []).map((x: { text?: string }) => x.text ?? '').join('');
}

// https://openrouter.ai/docs/api-reference/chat-completion (OpenAI-compatible)
async function openrouter(p: Prompt, model: string, o: CallOpts): Promise<string> {
  if (!o.key) throw new Error('no key');
  const content = p.imageBase64
    ? [{ type: 'text', text: p.user }, { type: 'image_url', image_url: { url: `data:${p.imageMime ?? 'image/jpeg'};base64,${p.imageBase64}` } }]
    : p.user;
  const data = await post(
    'https://openrouter.ai/api/v1/chat/completions',
    { authorization: `Bearer ${o.key}`, 'X-Title': 'Meal Bazar' },
    {
      model,
      messages: [{ role: 'system', content: p.system }, { role: 'user', content }],
      response_format: { type: 'json_object' },
      temperature: o.temperature,
    },
    o.timeoutMs,
  );
  return data?.choices?.[0]?.message?.content ?? '';
}

// One raw call to one chain entry (also used by the admin Test button).
export async function callModel(e: ChainEntry, p: Prompt, o: Omit<GenOptions, 'chain' | 'allowPaid'>): Promise<string> {
  const keys = await providerKeys();
  const call = e.provider === 'gemini' ? gemini : openrouter;
  return call(p, e.model, { key: keys[e.provider], timeoutMs: o.timeoutMs, temperature: o.temperature });
}

// Some models wrap JSON in ```json fences despite JSON mode.
const parseJson = (s: string) => JSON.parse(s.replace(/^\s*```(?:json)?\s*|\s*```\s*$/g, ''));

// Error kinds only: never keys, prompts or replies.
export const errorKind = (e: unknown) =>
  e instanceof Error && e.name !== 'ZodError' && e.name !== 'SyntaxError' ? e.message : (e as Error)?.name;

export async function generate<T>(p: Prompt, validate: (raw: unknown) => T, opts: GenOptions = envOptions()): Promise<T | null> {
  for (const entry of opts.chain) {
    if (entry.provider === 'openrouter' && !opts.allowPaid && await isPaidOpenRouter(entry.model)) {
      console.warn('ai provider openrouter skipped: paid model');
      continue;
    }
    try {
      return validate(parseJson(await callModel(entry, p, opts)));
    } catch (e) {
      console.warn(`ai provider ${entry.provider} failed: ${errorKind(e)}`);
    }
  }
  return null;
}
