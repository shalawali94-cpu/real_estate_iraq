import 'server-only';
import type { User } from '@supabase/supabase-js';

import { ApiError, ErrorCode } from '../http/errors';
import { supabaseAdmin } from '../supabase/admin';

/** Verifies the Supabase access token from `Authorization: Bearer <jwt>`. */
export async function requireUser(req: Request): Promise<User> {
  const header = req.headers.get('authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) throw new ApiError(ErrorCode.UNAUTHENTICATED);

  const { data, error } = await supabaseAdmin().auth.getUser(token);
  if (error || !data.user) throw new ApiError(ErrorCode.UNAUTHENTICATED);
  return data.user;
}
