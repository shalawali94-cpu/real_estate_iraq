import { z } from 'zod';

import { requireUser } from '@/lib/auth/require-user';
import { unwrap } from '@/lib/db/rpc-error';
import { json, route } from '@/lib/http/handler';
import { supabaseAdmin } from '@/lib/supabase/admin';

type Ctx = { params: Promise<{ id: string }> };

/**
 * Submit a draft / rejected listing.
 * Fee required (sale by default) → pending_payment, otherwise → pending_approval.
 */
export const POST = route<Ctx>(async (req, ctx) => {
  const user = await requireUser(req);
  const { id } = z.object({ id: z.string().uuid() }).parse(await ctx.params);

  const status = unwrap(
    await supabaseAdmin().rpc('property_submit', { p_user: user.id, p_property: id }),
  );
  return json({ id, publication_status: status, payment_required: status === 'pending_payment' });
});
