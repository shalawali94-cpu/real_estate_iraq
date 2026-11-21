import { createClient } from '@supabase/supabase-js';
import { z } from 'zod';

import { ApiError, ErrorCode } from '@/lib/http/errors';
import { json, route } from '@/lib/http/handler';
import { serverEnv } from '@/lib/env';
import { supabaseAdmin } from '@/lib/supabase/admin';

const body = z.object({
  phone: z.string().regex(/^\+9647[0-9]{9}$/),
  password: z.string().min(6).max(72),
});

// Best-effort throttle (per server instance). Production: add Vercel Firewall rate limit too.
const attempts = new Map<string, { n: number; reset: number }>();
function throttle(key: string) {
  const now = Date.now();
  const a = attempts.get(key);
  if (!a || a.reset < now) {
    attempts.set(key, { n: 1, reset: now + 10 * 60_000 });
    return;
  }
  if (++a.n > 8) throw new ApiError(ErrorCode.RATE_LIMITED);
}

/**
 * Sign in with mobile number + password. The number is matched against profiles.phone
 * (stored at sign-up, not yet SMS-verified); the password is what proves identity.
 * Every failure returns the same UNAUTHENTICATED so numbers cannot be enumerated.
 */
export const POST = route(async (req) => {
  const { phone, password } = body.parse(await req.json());
  const ip = req.headers.get('x-forwarded-for') ?? 'local';
  throttle(`${ip}:${phone}`);

  const db = supabaseAdmin();
  const { data: rows } = await db
    .from('profiles')
    .select('id')
    .eq('phone', phone)
    .is('deleted_at', null)
    .limit(2);
  if (!rows || rows.length !== 1) throw new ApiError(ErrorCode.UNAUTHENTICATED);

  const { data: u } = await db.auth.admin.getUserById(rows[0].id);
  const email = u?.user?.email;
  if (!email) throw new ApiError(ErrorCode.UNAUTHENTICATED);

  const env = serverEnv();
  const client = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.signInWithPassword({ email, password });
  if (error || !data.session) throw new ApiError(ErrorCode.UNAUTHENTICATED);

  return json({ refresh_token: data.session.refresh_token });
});
