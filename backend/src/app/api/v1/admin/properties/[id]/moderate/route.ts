import { z } from 'zod';

import { requireStaff } from '@/lib/auth/require-staff';
import { unwrap } from '@/lib/db/rpc-error';
import { json, route } from '@/lib/http/handler';
import { supabaseAdmin } from '@/lib/supabase/admin';

type Ctx = { params: Promise<{ id: string }> };

const body = z.object({
  decision: z.enum(['approve', 'reject', 'suspend', 'unsuspend']),
  reason: z.string().trim().max(500).optional(),
});

/** Approve / reject / suspend a listing. Audited and the owner is notified (in SQL). */
export const POST = route<Ctx>(async (req, ctx) => {
  const admin = await requireStaff(req, ['moderator', 'admin']);
  const { id } = z.object({ id: z.string().uuid() }).parse(await ctx.params);
  const input = body.parse(await req.json());

  const property = unwrap(
    await supabaseAdmin()
      .rpc('property_moderate', {
        p_admin: admin.id,
        p_property: id,
        p_decision: input.decision,
        p_reason: input.reason ?? '',
      })
      .single(),
  );
  return json({ property });
});
