import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { generate } from '../lib/providers';
import { z } from 'zod';

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
});
afterEach(() => {
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
