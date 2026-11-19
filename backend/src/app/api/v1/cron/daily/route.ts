import { ApiError, ErrorCode } from '@/lib/http/errors';
import { json, route } from '@/lib/http/handler';
import { unwrap } from '@/lib/db/rpc-error';
import { supabaseAdmin } from '@/lib/supabase/admin';

/** Called by Vercel Cron once a day. Vercel sends `Authorization: Bearer $CRON_SECRET`. */
export const GET = route(async (req) => {
  const secret = process.env.CRON_SECRET;
  if (!secret || req.headers.get('authorization') !== `Bearer ${secret}`) {
    throw new ApiError(ErrorCode.UNAUTHENTICATED);
  }
  const report = unwrap(await supabaseAdmin().rpc('run_daily_maintenance'));
  console.log(JSON.stringify({ level: 'info', job: 'daily_maintenance', report }));
  return json({ ok: true, report });
});
