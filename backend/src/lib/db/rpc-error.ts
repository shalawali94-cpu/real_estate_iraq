import { ApiError, ErrorCode } from '@/lib/http/errors';

const known = new Set<string>(Object.values(ErrorCode));

/** Postgres error codes our SQL functions raise, mapped when the message is not a known code. */
const byPgCode: Record<string, ErrorCode> = {
  '42501': ErrorCode.FORBIDDEN,
  '28000': ErrorCode.UNAUTHENTICATED,
  P0002: ErrorCode.NOT_FOUND,
  '22023': ErrorCode.VALIDATION_FAILED,
  '23514': ErrorCode.VALIDATION_FAILED,
  '23505': ErrorCode.CONFLICT,
};

/**
 * Turns an error from supabase-js (rpc / query) into a typed ApiError.
 * Our functions raise messages like 'NOT_FOUND' or 'VALIDATION_FAILED: images'.
 * Anything unrecognised is re-thrown as a plain Error → INTERNAL (logged, not leaked).
 */
export function toApiError(err: { message?: string; code?: string } | null | undefined): Error {
  const message = err?.message ?? '';
  const head = message.split(':')[0].trim();
  if (known.has(head)) {
    const detail = message.includes(':') ? message.slice(message.indexOf(':') + 1).trim() : undefined;
    return new ApiError(head as ErrorCode, detail ? { reason: detail } : undefined);
  }
  if (err?.code && byPgCode[err.code]) {
    return new ApiError(byPgCode[err.code]);
  }
  return new Error(`db error ${err?.code ?? ''}: ${message}`);
}

/** Throws if a supabase-js result has an error; returns data otherwise. */
export function unwrap<T>(result: { data: T | null; error: { message?: string; code?: string } | null }): T {
  if (result.error) throw toApiError(result.error);
  return result.data as T;
}
