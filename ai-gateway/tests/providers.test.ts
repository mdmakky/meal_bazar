import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { generate } from '../lib/providers';
import { z } from 'zod';
import { isPaidOpenRouter, listModels, normalizeGemini, normalizeOpenRouter, resetModelsCache } from '../lib/models';
import type { GenOptions } from '../lib/platform';

const prompt = { system: 's', user: 'aj Rahim 2' };
const validate = (raw: unknown) => z.object({ ok: z.literal(true) }).parse(raw);

const gemini = (text: string) => Response.json({ candidates: [{ content: { parts: [{ text }] } }] });
const openrouter = (content: string) => Response.json({ choices: [{ message: { content } }] });

let fetchMock: ReturnType<typeof vi.fn>;
beforeEach(() => {
  vi.stubEnv('GEMINI_API_KEY', 'g');
  vi.stubEnv('OPENROUTER_API_KEY', 'o');
  fetchMock = vi.fn();
  vi.stubGlobal('fetch', fetchMock);
  vi.spyOn(console, 'warn').mockImplementation(() => {});
  resetModelsCache();
});
afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllEnvs();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe('generate', () => {
  it('uses Gemini when it succeeds', async () => {
    fetchMock.mockResolvedValueOnce(gemini('{"ok":true}'));
    expect(await generate(prompt, validate)).toEqual({ ok: true });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchMock.mock.calls[0]![0]).toContain('generativelanguage.googleapis.com');
  });

  it('falls back to OpenRouter on Gemini 429', async () => {
    fetchMock.mockResolvedValueOnce(new Response('rate limited', { status: 429 }))
      .mockResolvedValueOnce(openrouter('```json\n{"ok":true}\n```'));
    expect(await generate(prompt, validate)).toEqual({ ok: true });
    expect(fetchMock.mock.calls[1]![0]).toBe('https://openrouter.ai/api/v1/chat/completions');
  });

  it('falls back on invalid JSON and on schema failure', async () => {
    fetchMock.mockResolvedValueOnce(gemini('not json')).mockResolvedValueOnce(openrouter('{"ok":true}'));
    expect(await generate(prompt, validate)).toEqual({ ok: true });
    fetchMock.mockResolvedValueOnce(gemini('{"ok":false}')).mockResolvedValueOnce(openrouter('{"ok":true}'));
    expect(await generate(prompt, validate)).toEqual({ ok: true });
  });

  it('falls back on timeout/network error', async () => {
    fetchMock.mockRejectedValueOnce(new DOMException('aborted', 'TimeoutError')).mockResolvedValueOnce(openrouter('{"ok":true}'));
    expect(await generate(prompt, validate)).toEqual({ ok: true });
  });

  it('returns null when both fail, without logging user text', async () => {
    fetchMock.mockResolvedValueOnce(new Response('', { status: 503 })).mockResolvedValueOnce(new Response('', { status: 500 }));
    expect(await generate(prompt, validate)).toBeNull();
    const logged = JSON.stringify((console.warn as any).mock.calls);
    expect(logged).not.toContain('Rahim');
  });

  it('sends the image inline to both providers', async () => {
    fetchMock.mockResolvedValueOnce(new Response('', { status: 500 })).mockResolvedValueOnce(openrouter('{"ok":true}'));
    await generate({ ...prompt, imageBase64: '/9j/AA==' }, validate);
    expect(JSON.parse(fetchMock.mock.calls[0]![1].body).contents[0].parts[1].inline_data.data).toBe('/9j/AA==');
    expect(fetchMock.mock.calls[1]![1].body).toContain('data:image/jpeg;base64,/9j/AA==');
  });
});

const opts = (chain: GenOptions['chain'], allowPaid = false): GenOptions => ({ chain, timeoutMs: 5000, temperature: 0.2, allowPaid });
const orList = (data: unknown[]) => Response.json({ data });

describe('chains', () => {
  it('walks the chain in order with the configured model, timeout and temperature', async () => {
    fetchMock.mockResolvedValueOnce(new Response('', { status: 500 }))
      .mockResolvedValueOnce(new Response('', { status: 500 }))
      .mockResolvedValueOnce(gemini('{"ok":true}'));
    const chain = [{ provider: 'gemini', model: 'g1' }, { provider: 'openrouter', model: 'x:free' }, { provider: 'gemini', model: 'g2' }] as const;
    expect(await generate(prompt, validate, opts([...chain]))).toEqual({ ok: true });
    expect(fetchMock.mock.calls.map((c) => c[0])).toEqual([
      expect.stringContaining('/models/g1:generateContent'),
      'https://openrouter.ai/api/v1/chat/completions',
      expect.stringContaining('/models/g2:generateContent'),
    ]);
    expect(JSON.parse(fetchMock.mock.calls[1]![1].body)).toMatchObject({ model: 'x:free', temperature: 0.2 });
    expect(JSON.parse(fetchMock.mock.calls[2]![1].body).generationConfig.temperature).toBe(0.2);
  });

  it('skips paid OpenRouter models unless allow_paid, using the models list', async () => {
    const list = orList([
      { id: 'paid/model', pricing: { prompt: '0.000001', completion: '0.000002' } },
      { id: 'zero/model', pricing: { prompt: '0', completion: '0' } },
    ]);
    fetchMock.mockResolvedValueOnce(list).mockResolvedValueOnce(openrouter('{"ok":true}'));
    const chain = [{ provider: 'openrouter', model: 'paid/model' }, { provider: 'openrouter', model: 'zero/model' }] as GenOptions['chain'];
    expect(await generate(prompt, validate, opts(chain))).toEqual({ ok: true });
    expect(fetchMock).toHaveBeenCalledTimes(2); // list + zero/model only
    expect(JSON.parse(fetchMock.mock.calls[1]![1].body).model).toBe('zero/model');

    fetchMock.mockClear();
    fetchMock.mockResolvedValueOnce(openrouter('{"ok":true}'));
    expect(await generate(prompt, validate, opts(chain, true))).toEqual({ ok: true });
    expect(JSON.parse(fetchMock.mock.calls[0]![1].body).model).toBe('paid/model');
  });

  it('treats unknown pricing as paid, except :free and openrouter/free', async () => {
    fetchMock.mockResolvedValue(orList([]));
    expect(await isPaidOpenRouter('openrouter/free')).toBe(false);
    expect(await isPaidOpenRouter('vendor/m:free')).toBe(false);
    expect(fetchMock).not.toHaveBeenCalled();
    expect(await isPaidOpenRouter('vendor/unknown')).toBe(true);
    fetchMock.mockRejectedValue(new Error('down'));
    resetModelsCache();
    expect(await isPaidOpenRouter('vendor/unknown')).toBe(true);
  });
});

describe('models', () => {
  it('normalises OpenRouter models: free/paid/vision', () => {
    const paid = normalizeOpenRouter({ id: 'v/p', name: 'P', description: 'd', context_length: 128000,
      pricing: { prompt: '0.0000025', completion: '0.00001' }, architecture: { input_modalities: ['text', 'image'] } });
    expect(paid).toEqual({ provider: 'openrouter', id: 'v/p', name: 'P', description: 'd', context_length: 128000,
      input_price_per_mtok: 2.5, output_price_per_mtok: 10, free: false, vision: true, text: true });
    const free = normalizeOpenRouter({ id: 'v/f:free', pricing: { prompt: '0', completion: '0' }, architecture: { input_modalities: ['text'] } });
    expect(free).toMatchObject({ name: 'v/f:free', free: true, vision: false, text: true, context_length: null });
    expect(normalizeOpenRouter({ id: 'v/u' })).toMatchObject({ input_price_per_mtok: null, free: false });
  });

  it('normalises Gemini models and keeps only generateContent ones', async () => {
    fetchMock.mockResolvedValueOnce(Response.json({ models: [
      { name: 'models/gemini-2.5-flash', displayName: 'Gemini 2.5 Flash', inputTokenLimit: 1048576, supportedGenerationMethods: ['generateContent'] },
      { name: 'models/gemini-1.0-ultra', supportedGenerationMethods: ['generateContent'] },
      { name: 'models/text-embedding-004', supportedGenerationMethods: ['embedContent'] },
    ], nextPageToken: 'p2' })).mockResolvedValueOnce(Response.json({ models: [
      { name: 'models/gemini-flash-latest', supportedGenerationMethods: ['generateContent'] },
    ] }));
    const models = await listModels('gemini');
    expect(models.map((m) => [m.id, m.vision])).toEqual([['gemini-2.5-flash', true], ['gemini-1.0-ultra', false], ['gemini-flash-latest', true]]);
    expect(models[0]).toEqual({ provider: 'gemini', id: 'gemini-2.5-flash', name: 'Gemini 2.5 Flash', description: '', context_length: 1048576,
      input_price_per_mtok: null, output_price_per_mtok: null, free: true, vision: true, text: true });
    expect(fetchMock.mock.calls[1]![0]).toContain('pageToken=p2');
    expect(fetchMock.mock.calls[0]![0]).not.toContain('key='); // key goes in a header
    expect(normalizeGemini({ name: 'models/gemma-3-27b-it' }).vision).toBe(false);
  });

  it('caches each provider list for 10 minutes', async () => {
    vi.useFakeTimers();
    fetchMock.mockImplementation(async () => orList([{ id: 'a' }]));
    await listModels('openrouter');
    vi.advanceTimersByTime(9 * 60_000);
    await listModels('openrouter');
    expect(fetchMock).toHaveBeenCalledTimes(1);
    vi.advanceTimersByTime(2 * 60_000);
    await listModels('openrouter');
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });
});
