import { z } from 'zod';

import { requireStaff } from '@/lib/auth/require-staff';
import { unwrap } from '@/lib/db/rpc-error';
import { json, route } from '@/lib/http/handler';
import { supabaseAdmin } from '@/lib/supabase/admin';

const query = z.object({
  status: z
    .enum(['pending_approval', 'published', 'rejected', 'suspended', 'expired', 'pending_payment', 'draft'])
    .default('pending_approval'),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).max(10000).default(0),
});

/** Moderation queue (oldest first for pending, newest first otherwise). */
export const GET = route(async (req) => {
  await requireStaff(req, ['moderator', 'admin']);
  const q = query.parse(Object.fromEntries(new URL(req.url).searchParams));

  const { data, count, error } = await supabaseAdmin()
    .from('properties')
    .select(
      'id, owner_id, title, transaction_type, category_id, price_amount, price_currency, governorate_id, district_id, publication_status, rejection_reason, created_at, updated_at, property_images(storage_path, is_cover, sort_order)',
      { count: 'exact' },
    )
    .eq('publication_status', q.status)
    .is('deleted_at', null)
    .order('updated_at', { ascending: q.status === 'pending_approval' })
    .range(q.offset, q.offset + q.limit - 1);
  unwrap({ data, error });
  return json({ items: data ?? [], total: count ?? 0, limit: q.limit, offset: q.offset });
});
