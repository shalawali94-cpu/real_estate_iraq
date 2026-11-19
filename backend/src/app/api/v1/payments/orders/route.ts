import { z } from 'zod';

import { requireUser } from '@/lib/auth/require-user';
import { unwrap } from '@/lib/db/rpc-error';
import { ApiError, ErrorCode } from '@/lib/http/errors';
import { json, route } from '@/lib/http/handler';
import { supabaseAdmin } from '@/lib/supabase/admin';
import { getProvider } from '@/payments/registry';

const body = z
  .object({
    service_type: z.enum(['PROPERTY_PUBLISHING', 'AI_VIDEO_GENERATION']),
    property_id: z.string().uuid().optional(),
    ai_job_id: z.string().uuid().optional(),
    provider: z.enum(['FIB', 'QI_CARD']),
    locale: z.enum(['ckb', 'ar', 'en']).default('ckb'),
  })
  .refine((b) => (b.service_type === 'PROPERTY_PUBLISHING' ? !!b.property_id : !!b.ai_job_id), {
    message: 'property_id or ai_job_id required',
  });

/**
 * Create (or reuse) a payment order and start the payment with the provider.
 * The price always comes from the database, never from the client.
 */
export const POST = route(async (req) => {
  const user = await requireUser(req);
  const idempotencyKey = req.headers.get('idempotency-key') ?? '';
  if (idempotencyKey.length < 8 || idempotencyKey.length > 100) {
    throw new ApiError(ErrorCode.IDEMPOTENCY_KEY_REQUIRED);
  }
  const input = body.parse(await req.json());

  // Refuse before creating anything if the provider has no credentials yet.
  const provider = getProvider(input.provider);
  if (provider.mode() === 'unconfigured') {
    throw new ApiError(ErrorCode.PAYMENT_PROVIDER_NOT_CONFIGURED, { provider: input.provider });
  }

  const db = supabaseAdmin();
  const order = unwrap(
    await db
      .rpc('payment_create_order', {
        p_user: user.id,
        p_service: input.service_type,
        p_property: input.property_id ?? null,
        p_ai_job: input.ai_job_id ?? null,
        p_provider: input.provider,
        p_idempotency_key: idempotencyKey,
      })
      .single<{ id: string; amount: number; currency: 'IQD'; internal_reference: string; status: string }>(),
  );

  // Reuse an existing provider payment for this order (retry / same key).
  const existing = unwrap(
    await db
      .from('payment_transactions')
      .select('provider_payment_id, provider_payload, valid_until, status')
      .eq('order_id', order.id)
      .eq('status', 'pending')
      .maybeSingle<{
        provider_payment_id: string;
        provider_payload: Record<string, unknown>;
        valid_until: string | null;
        status: string;
      }>(),
  );
  if (existing) {
    return json({ order, payment: { ...existing.provider_payload, providerPaymentId: existing.provider_payment_id } });
  }

  const base = process.env.PUBLIC_API_BASE_URL ?? new URL(req.url).origin;
  try {
    const created = await provider.createPayment({
      orderId: order.id,
      reference: order.internal_reference,
      amount: BigInt(order.amount),
      currency: 'IQD',
      description: input.service_type === 'PROPERTY_PUBLISHING' ? 'Property listing fee' : 'AI property video',
      callbackUrl: `${base}/api/v1/payments/webhooks/${input.provider.toLowerCase()}`,
      redirectUrl: `realestateiraq://payments/${order.id}`,
      locale: input.locale,
    });
    unwrap(
      await db.rpc('payment_attach_transaction', {
        p_order: order.id,
        p_provider_payment_id: created.providerPaymentId,
        p_payload: created,
        p_valid_until: created.validUntil ?? null,
      }),
    );
    return json({ order, payment: created }, { status: 201 });
  } catch (err) {
    await db.rpc('payment_mark_failed', { p_order: order.id, p_status: 'failed', p_reason: 'PROVIDER_CREATE_FAILED' });
    if (err instanceof ApiError) throw err;
    throw new ApiError(ErrorCode.PAYMENT_PROVIDER_ERROR);
  }
});
