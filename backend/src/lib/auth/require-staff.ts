import 'server-only';
import type { User } from '@supabase/supabase-js';

import { ApiError, ErrorCode } from '../http/errors';
import { supabaseAdmin } from '../supabase/admin';
import type { Database } from '../supabase/database.types';
import { requireUser } from './require-user';

type AppRole = Database['public']['Enums']['app_role'];

/** Signed-in user who holds one of `roles` (super_admin always passes). Checked in the DB every time. */
export async function requireStaff(req: Request, roles: AppRole[]): Promise<User> {
  const user = await requireUser(req);
  const { data, error } = await supabaseAdmin()
    .from('user_roles')
    .select('role')
    .eq('user_id', user.id);
  if (error) throw new Error(`role lookup failed: ${error.message}`);
  const held = new Set((data ?? []).map((r) => r.role));
  if (!held.has('super_admin') && !roles.some((r) => held.has(r))) {
    throw new ApiError(ErrorCode.FORBIDDEN);
  }
  return user;
}
