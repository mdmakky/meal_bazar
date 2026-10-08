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
