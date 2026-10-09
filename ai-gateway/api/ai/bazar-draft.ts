import { consumeQuota, userClient } from '../../lib/auth';
import { handle, HttpError, json, readJson } from '../../lib/http';
import { bazarPrompt } from '../../lib/prompts';
import { aiSettings } from '../../lib/platform';
import { generate } from '../../lib/providers';
import { BazarDraftRequest, toBazarDraft } from '../../lib/schemas';

// POST {mess_id, date, image_base64} → {draft} | {unavailable, reason}. The image is never stored.
export const POST = handle(async (req) => {
  const sb = userClient(req);
  const body = BazarDraftRequest.safeParse(await readJson(req, 600_000));
  if (!body.success) throw new HttpError(400, 'bad_request');

  const ai = await aiSettings();
  if (!ai.bazarScan) return json({ unavailable: true, reason: 'disabled' });
  const blocked = await consumeQuota(sb, body.data.mess_id, 'bazar_draft', ai.quotaBazarDraft);
  if (blocked) return json(blocked);

  const draft = await generate(bazarPrompt(body.data.image_base64), toBazarDraft, ai.models);
  return json(draft ? { draft } : { unavailable: true, reason: 'providers' });
});
