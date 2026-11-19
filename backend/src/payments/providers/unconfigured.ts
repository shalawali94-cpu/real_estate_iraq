import { ApiError, ErrorCode } from '@/lib/http/errors';

import type {
  CreatedPayment,
  PaymentProviderAdapter,
  ProviderId,
  ProviderMode,
  ProviderStatusResult,
} from '../types';

/**
 * Honest placeholder used until merchant credentials exist (Phase 6).
 * It never reports success: every money operation fails with
 * PAYMENT_PROVIDER_NOT_CONFIGURED.
 */
export class UnconfiguredProvider implements PaymentProviderAdapter {
  constructor(readonly id: ProviderId) {}

  mode(): ProviderMode {
    return 'unconfigured';
  }

  async createPayment(): Promise<CreatedPayment> {
    throw new ApiError(ErrorCode.PAYMENT_PROVIDER_NOT_CONFIGURED, { provider: this.id });
  }

  async getStatus(): Promise<ProviderStatusResult> {
    throw new ApiError(ErrorCode.PAYMENT_PROVIDER_NOT_CONFIGURED, { provider: this.id });
  }
}
