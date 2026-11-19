import { z } from 'zod';

import { requireUser } from '@/lib/auth/require-user';
import { unwrap } from '@/lib/db/rpc-error';
import { ApiError, ErrorCode } from '@/lib/http/errors';
import { json, route } from '@/lib/http/handler';
import { extensionFor, MEDIA_RULES, mediaPath, type SniffedType } from '@/lib/media/sniff';
import { supabaseAdmin } from '@/lib/supabase/admin';

const body = z.object({
  property_id: z.string().uuid(),
  kind: z.enum(['image', 'video']),
  content_type: z.string(),
  bytes: z.number().int().positive(),
});

/** Step 1 of an upload: check the rules, return a one-time signed upload URL. */
export const POST = route(async (req) => {
  const user = await requireUser(req);
  const input = body.parse(await req.json());
  const rules = MEDIA_RULES[input.kind];

  if (!rules.mimes.includes(input.content_type as SniffedType)) {
    throw new ApiError(ErrorCode.MEDIA_INVALID, { reason: 'type' });
  }
  if (input.bytes > rules.maxBytes) {
    throw new ApiError(ErrorCode.MEDIA_INVALID, { reason: 'size', max_bytes: rules.maxBytes });
  }

  const db = supabaseAdmin();
  const property = unwrap(
    await db
      .from('properties')
      .select('id, owner_id, publication_status, deleted_at')
      .eq('id', input.property_id)
      .maybeSingle<{ id: string; owner_id: string; publication_status: string; deleted_at: string | null }>(),
  );
  if (!property || property.owner_id !== user.id || property.deleted_at) {
    throw new ApiError(ErrorCode.NOT_FOUND);
  }
  if (!['draft', 'rejected', 'payment_failed'].includes(property.publication_status)) {
    throw new ApiError(ErrorCode.PROPERTY_NOT_EDITABLE);
  }

  const table = input.kind === 'image' ? 'property_images' : 'property_videos';
  let countQuery = db.from(table).select('id', { count: 'exact', head: true }).eq('property_id', input.property_id);
  if (input.kind === 'image') countQuery = countQuery.is('ai_variant_of', null);
  const { count } = await countQuery;
  if ((count ?? 0) >= rules.maxPerProperty) {
    throw new ApiError(ErrorCode.MEDIA_LIMIT, { max: rules.maxPerProperty });
  }

  const path = mediaPath(user.id, input.property_id, extensionFor[input.content_type as SniffedType]);
  const signed = unwrap(await db.storage.from('property-media').createSignedUploadUrl(path));
  return json({ path, token: signed.token, signed_url: signed.signedUrl, max_bytes: rules.maxBytes });
});
