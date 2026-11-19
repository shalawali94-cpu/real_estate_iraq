import { ZodError } from 'zod';

import { ApiError, ErrorCode } from './errors';

type Handler<C> = (req: Request, ctx: C) => Promise<Response>;

export function json(data: unknown, init?: ResponseInit): Response {
  return new Response(
    JSON.stringify(data, (_k, v) => (typeof v === 'bigint' ? v.toString() : v)),
    {
      ...init,
      headers: { 'content-type': 'application/json', ...init?.headers },
    },
  );
}

/**
 * Wraps a route handler: request id, typed error responses, no silent failures.
 * Unknown errors are logged with the request id and returned as INTERNAL.
 */
export function route<C = unknown>(handler: Handler<C>): Handler<C> {
  return async (req, ctx) => {
    const requestId = req.headers.get('x-request-id') ?? crypto.randomUUID();
    try {
      const res = await handler(req, ctx);
      res.headers.set('x-request-id', requestId);
      return res;
    } catch (err) {
      if (err instanceof ApiError) {
        return json(
          { error: { code: err.code, details: err.details ?? null, requestId } },
          { status: err.status, headers: { 'x-request-id': requestId } },
        );
      }
      if (err instanceof ZodError) {
        return json(
          { error: { code: ErrorCode.VALIDATION_FAILED, details: err.issues, requestId } },
          { status: 400, headers: { 'x-request-id': requestId } },
        );
      }
      console.error(JSON.stringify({ level: 'error', requestId, err: String(err) }));
      return json(
        { error: { code: ErrorCode.INTERNAL, details: null, requestId } },
        { status: 500, headers: { 'x-request-id': requestId } },
      );
    }
  };
}
