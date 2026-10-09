import { consumeQuota, rpcError, userClient } from '../../lib/auth';
import { handle, HttpError, json, readJson } from '../../lib/http';
import { mealPrompt } from '../../lib/prompts';
import { aiSettings } from '../../lib/platform';
import { generate } from '../../lib/providers';
import { MealDraftRequest, toMealDraft, type MealContext } from '../../lib/schemas';

// POST {mess_id, date, text} → {draft} | {unavailable, reason}
export const POST = handle(async (req) => {
  const sb = userClient(req);
  const body = MealDraftRequest.safeParse(await readJson(req, 8_000));
  if (!body.success) throw new HttpError(400, 'bad_request');
  const { mess_id, date, text } = body.data;

  const ai = await aiSettings();
  if (!ai.mealDraft) return json({ unavailable: true, reason: 'disabled' });
  const blocked = await consumeQuota(sb, mess_id, 'meal_draft', ai.quotaMealDraft);
  if (blocked) return json(blocked);

  const { data: ctx, error } = await sb.rpc('ai_meal_context', { p_mess: mess_id });
  if (error) throw rpcError(error);
  if (!ctx) throw new HttpError(403, 'forbidden');

  const draft = await generate(mealPrompt(ctx as MealContext, date, text), (raw) => toMealDraft(raw, ctx as MealContext), ai.models);
  return json(draft ? { draft } : { unavailable: true, reason: 'providers' });
});
