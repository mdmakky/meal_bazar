import { z } from 'zod';
import { requireAdmin } from '../../lib/auth';
import { handle, preflight, withCors, HttpError, json, readJson } from '../../lib/http';
import { aiSettings } from '../../lib/platform';
import { callModel, errorKind } from '../../lib/providers';

const Body = z.object({ provider: z.enum(['gemini', 'openrouter']), model: z.string().min(1).max(200), kind: z.enum(['text', 'vision']) });

// 1×1 white PNG.
const PIXEL = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4//8/AAX+Av4N70a4AAAAAElFTkSuQmCC';

// POST {provider, model, kind} → {ok, latency_ms, sample, error}. Platform admins only; no mess quota.
// Ignores allow_paid on purpose (the admin is choosing a model); honours the AI_ENABLED kill switch.
export const POST = withCors(handle(async (req) => {
  await requireAdmin(req);
  const body = Body.safeParse(await readJson(req, 2_000));
  if (!body.success) throw new HttpError(400, 'bad_request');
  if (process.env.AI_ENABLED === 'false') return json({ ok: false, latency_ms: 0, sample: '', error: 'disabled' });

  const { provider, model, kind } = body.data;
  const ai = await aiSettings();
  const prompt = {
    system: 'Reply with JSON only: {"ok":true,"color":"<main colour of the image, or none>"}',
    user: kind === 'vision' ? 'What colour is this image?' : 'Say ok.',
    ...(kind === 'vision' ? { imageBase64: PIXEL, imageMime: 'image/png' } : {}),
  };
  const started = Date.now();
  try {
    const reply = await callModel({ provider, model }, prompt, ai[kind]);
    return json({ ok: true, latency_ms: Date.now() - started, sample: reply.slice(0, 200), error: null });
  } catch (e) {
    return json({ ok: false, latency_ms: Date.now() - started, sample: '', error: errorKind(e) });
  }
}));

export const OPTIONS = preflight;
