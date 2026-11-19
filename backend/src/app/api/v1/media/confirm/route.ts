import { z } from 'zod';

import { requireUser } from '@/lib/auth/require-user';
import { unwrap } from '@/lib/db/rpc-error';
import { ApiError, ErrorCode } from '@/lib/http/errors';
import { json, route } from '@/lib/http/handler';
import { isOwnMediaPath, MEDIA_RULES, sniffMime } from '@/lib/media/sniff';
import { supabaseAdmin } from '@/lib/supabase/admin';

const body = z.object({
  property_id: z.string().uuid(),
  kind: z.enum(['image', 'video']),
  path: z.string().max(200),
});

/**
 * Step 2 of an upload: read the first bytes of the stored file, check the real type
 * and size, then register it. Anything that fails the check is deleted.
 */
export const POST = route(async (req) => {
  const user = await requireUser(req);
  const input = body.parse(await req.json());
  if (!isOwnMediaPath(input.path, user.id, input.property_id)) {
    throw new ApiError(ErrorCode.FORBIDDEN);
  }

  const db = supabaseAdmin();
  const bucket = db.storage.from('property-media');
  const rules = MEDIA_RULES[input.kind];

  const reject = async (reason: string): Promise<never> => {
    await bucket.remove([input.path]);
    throw new ApiError(ErrorCode.MEDIA_INVALID, { reason });
  };

  const signed = unwrap(await bucket.createSignedUrl(input.path, 60));
  const head = await fetch(signed.signedUrl, { headers: { Range: 'bytes=0-63' } });
  if (!head.ok) throw new ApiError(ErrorCode.NOT_FOUND);

  const first = new Uint8Array(await head.arrayBuffer());
  const total = Number(head.headers.get('content-range')?.split('/')[1] ?? head.headers.get('content-length') ?? 0);
  const mime = sniffMime(first);

  if (!mime || !(rules.mimes as readonly string[]).includes(mime)) await reject('type');
  if (!total || total > rules.maxBytes) await reject('size');

  if (input.kind === 'image') {
    const { count } = await db
      .from('property_images')
      .select('id', { count: 'exact', head: true })
      .eq('property_id', input.property_id);
    const row = unwrap(
      await db
        .from('property_images')
        .insert({
          property_id: input.property_id,
          owner_id: user.id,
          storage_path: input.path,
          bytes: total,
          mime,
          sort_order: count ?? 0,
          is_cover: (count ?? 0) === 0,
          status: 'verified',
        })
        .select()
        .single(),
    );
    return json({ image: row }, { status: 201 });
  }

  const row = unwrap(
    await db
      .from('property_videos')
      .insert({ property_id: input.property_id, owner_id: user.id, storage_path: input.path, source: 'user_upload' })
      .select()
      .single(),
  );
  return json({ video: row }, { status: 201 });
});
