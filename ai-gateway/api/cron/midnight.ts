import { rpcError, serviceClient } from '../../lib/auth';
import { handle, HttpError, json } from '../../lib/http';

// Vercel cron, 18:00 UTC = 00:00 Asia/Dhaka: fills the meals nobody entered
// for the day that just ended (auto_fill_meals, 0031). The SQL is idempotent
// and catches up the last 3 days, so a late or repeated run is harmless.
export const GET = handle(async (req) => {
  const secret = process.env.CRON_SECRET;
  if (!secret || req.headers.get('authorization') !== `Bearer ${secret}`) throw new HttpError(401, 'unauthorized');
  const { data, error } = await serviceClient().rpc('auto_fill_meals');
  if (error) throw rpcError(error);
  return json({ filled: Number(data ?? 0) });
});
