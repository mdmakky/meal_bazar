import { serviceClient } from '../../lib/auth';
import { handle, HttpError, json } from '../../lib/http';
import { pushDispatchSecret } from '../../lib/platform';
import { drainOutbox, secretMatches } from '../../lib/push';

const BATCH = 200;

// Poked by the DB (push_kick via pg_net) after it queues notifications.
// Header x-push-secret must equal PUSH_DISPATCH_SECRET (platform_secrets, else env).
// → {claimed, sent, failed, dropped_tokens}. Leftovers go out with the next poke or the daily cron.
export const POST = handle(async (req) => {
  const expected = await pushDispatchSecret();
  if (!expected || !secretMatches(req.headers.get('x-push-secret'), expected)) throw new HttpError(401, 'unauthorized');
  return json(await drainOutbox(serviceClient(), BATCH));
});
