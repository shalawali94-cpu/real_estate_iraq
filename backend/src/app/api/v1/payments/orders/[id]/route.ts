import { z } from 'zod';

import { requireUser } from '@/lib/auth/require-user';
import { unwrap } from '@/lib/db/rpc-error';
import { ApiError, ErrorCode } from '@/lib/http/errors';
import { json, route } from '@/lib/http/handler';
import { supabaseAdmin } from '@/lib/supabase/admin';

type Ctx = { params: Promise<{ id: string }> };

/** Order status for the payment screen (polled by the app). Owner only. */
export const GET = route<Ctx>(async (req, ctx) => {
  const user = await requireUser(req);
  const { id } = z.object({ id: z.string().uuid() }).parse(await ctx.params);

  const order = unwrap(
    await supabaseAdmin()
      .from('payment_orders')
      .select('id, user_id, service_type, property_id, ai_job_id, provider, amount, currency, status, internal_reference, failure_reason, refund_status, paid_at, expires_at, created_at')
      .eq('id', id)
      .maybeSingle<{ user_id: string } & Record<string, unknown>>(),
  );
  if (!order || order.user_id !== user.id) throw new ApiError(ErrorCode.NOT_FOUND);

  const publicOrder: Record<string, unknown> = { ...order };
  delete publicOrder.user_id;
  return json({ order: publicOrder });
});
