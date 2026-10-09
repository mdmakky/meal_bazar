// Provider chain: Gemini → OpenRouter → null ("AI unavailable"). Plain fetch, 20 s each.
// Models come from lib/platform.ts (platform config > env > defaults).
// Any failure (HTTP error, timeout, bad JSON, schema rejection) moves to the next provider.

import { envModels, type Models } from './platform';

export type Prompt = { system: string; user: string; imageBase64?: string };

const TIMEOUT_MS = 20_000;

async function post(url: string, headers: Record<string, string>, body: unknown): Promise<any> {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...headers },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  // Only the status is surfaced: provider error bodies can echo the user's input.
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

// https://ai.google.dev/api/generate-content
async function gemini(p: Prompt, model: string): Promise<string> {
  const key = process.env.GEMINI_API_KEY;
  if (!key) throw new Error('no key');
  const parts: unknown[] = [{ text: p.user }];
  if (p.imageBase64) parts.push({ inline_data: { mime_type: 'image/jpeg', data: p.imageBase64 } });
  const data = await post(
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
    { 'x-goog-api-key': key },
    {
      system_instruction: { parts: [{ text: p.system }] },
      contents: [{ role: 'user', parts }],
      generationConfig: { responseMimeType: 'application/json', temperature: 0 },
    },
  );
  return (data?.candidates?.[0]?.content?.parts ?? []).map((x: { text?: string }) => x.text ?? '').join('');
}

// https://openrouter.ai/docs/api-reference/chat-completion (OpenAI-compatible)
async function openrouter(p: Prompt, model: string): Promise<string> {
  const key = process.env.OPENROUTER_API_KEY;
  if (!key) throw new Error('no key');
  const content = p.imageBase64
    ? [{ type: 'text', text: p.user }, { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${p.imageBase64}` } }]
    : p.user;
  const data = await post(
    'https://openrouter.ai/api/v1/chat/completions',
    { authorization: `Bearer ${key}`, 'X-Title': 'Meal Bazar' },
    {
      model,
      messages: [{ role: 'system', content: p.system }, { role: 'user', content }],
      response_format: { type: 'json_object' },
      temperature: 0,
    },
  );
  return data?.choices?.[0]?.message?.content ?? '';
}

// Some models wrap JSON in ```json fences despite JSON mode.
const parseJson = (s: string) => JSON.parse(s.replace(/^\s*```(?:json)?\s*|\s*```\s*$/g, ''));

export async function generate<T>(p: Prompt, validate: (raw: unknown) => T, models: Models = envModels()): Promise<T | null> {
  const chain = [['gemini', gemini, models.primary], ['openrouter', openrouter, models.fallback]] as const;
  for (const [name, call, model] of chain) {
    try {
      return validate(parseJson(await call(p, model)));
    } catch (e) {
      const why = e instanceof Error && e.name !== 'ZodError' && e.name !== 'SyntaxError' ? e.message : (e as Error)?.name;
      console.warn(`ai provider ${name} failed: ${why}`); // never the prompt or reply
    }
  }
  return null;
}
