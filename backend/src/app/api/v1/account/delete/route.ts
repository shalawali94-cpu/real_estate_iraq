import { requireUser } from '@/lib/auth/require-user';
import { toApiError } from '@/lib/db/rpc-error';
import { ApiError, ErrorCode } from '@/lib/http/errors';
import { json, route } from '@/lib/http/handler';
import { supabaseAdmin } from '@/lib/supabase/admin';

// Typed after `npm run gen:types` is re-run for migration 013.
type LooseRpc = {
  rpc: (fn: string, args: object) => PromiseLike<{ error: { message?: string; code?: string } | null }>;
};

/**
 * Deletes the caller's account: personal data is anonymized, listings are retired,
 * financial records are kept, and the auth user is soft-deleted so the phone number
 * can register again. Safe to retry (both steps are idempotent).
 */
export const POST = route(async (req) => {
  const user = await requireUser(req);
  const db = supabaseAdmin();

  const { error } = await (db as unknown as LooseRpc).rpc('account_anonymize', { p_user: user.id });
  if (error) throw toApiError(error);

  const { error: authError } = await db.auth.admin.deleteUser(user.id, true);
  if (authError) throw new ApiError(ErrorCode.INTERNAL);

  return json({ deleted: true });
});
