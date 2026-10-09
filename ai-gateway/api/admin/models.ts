import { requireAdmin } from '../../lib/auth';
import { handle, HttpError, json } from '../../lib/http';
import { listModels, type ModelInfo, type Provider } from '../../lib/models';

// GET ?provider=gemini|openrouter|all → {models: ModelInfo[]}. Platform admins only.
export const GET = handle(async (req) => {
  await requireAdmin(req);
  const provider = new URL(req.url).searchParams.get('provider') ?? 'all';
  if (!['gemini', 'openrouter', 'all'].includes(provider)) throw new HttpError(400, 'bad_request');
  const providers: Provider[] = provider === 'all' ? ['gemini', 'openrouter'] : [provider as Provider];
  let models: ModelInfo[];
  try {
    models = (await Promise.all(providers.map(listModels))).flat();
  } catch (e) {
    console.warn(`model list failed: ${e instanceof Error ? e.message : typeof e}`); // HTTP status only
    throw new HttpError(502, 'upstream');
  }
  return json({ models });
});
