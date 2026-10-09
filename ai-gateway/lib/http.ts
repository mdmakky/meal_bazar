// JSON helpers shared by every endpoint. Errors are always {error: code}.

export class HttpError extends Error {
  constructor(public status: number, public code: string) {
    super(code);
  }
}

export const json = (body: unknown, status = 200) => Response.json(body, { status });

export async function readJson(req: Request, maxBytes: number): Promise<unknown> {
  if (Number(req.headers.get('content-length') ?? 0) > maxBytes) throw new HttpError(413, 'too_large');
  const text = await req.text();
  if (Buffer.byteLength(text) > maxBytes) throw new HttpError(413, 'too_large');
  try {
    return JSON.parse(text);
  } catch {
    throw new HttpError(400, 'bad_json');
  }
}

// Wraps a handler so thrown HttpErrors become JSON responses. Never logs request data.
export function handle(fn: (req: Request) => Promise<Response>) {
  return async (req: Request): Promise<Response> => {
    try {
      return await fn(req);
    } catch (e) {
      if (e instanceof HttpError) return json({ error: e.code }, e.status);
      console.error('unhandled', e instanceof Error ? e.name : typeof e);
      return json({ error: 'internal' }, 500);
    }
  };
}

// CORS for browser callers (the admin web panel). Auth is a Bearer token, not cookies,
// so a wildcard is safe; set ADMIN_ORIGINS="https://admin.example.com,..." to restrict it.
function corsHeaders(req: Request): Record<string, string> {
  const allowed = (process.env.ADMIN_ORIGINS ?? '').split(',').map((s) => s.trim()).filter(Boolean);
  const origin = req.headers.get('origin') ?? '';
  const allow = allowed.length === 0 ? '*' : allowed.includes(origin) ? origin : (allowed[0] ?? '*');
  return {
    'access-control-allow-origin': allow,
    'access-control-allow-headers': 'authorization, content-type',
    'access-control-allow-methods': 'GET, POST, OPTIONS',
    'access-control-max-age': '600',
    vary: 'origin',
  };
}

export function withCors(fn: (req: Request) => Promise<Response>) {
  return async (req: Request): Promise<Response> => {
    const res = await fn(req);
    const headers = new Headers(res.headers);
    for (const [k, v] of Object.entries(corsHeaders(req))) headers.set(k, v);
    return new Response(res.body, { status: res.status, headers });
  };
}

export const preflight = async (req: Request) => new Response(null, { status: 204, headers: corsHeaders(req) });
