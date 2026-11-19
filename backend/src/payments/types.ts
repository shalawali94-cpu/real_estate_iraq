export type ProviderId = 'FIB' | 'QI_CARD';
export type ProviderMode = 'unconfigured' | 'sandbox' | 'live';
export type ServiceType = 'PROPERTY_PUBLISHING' | 'AI_VIDEO_GENERATION';

/** Amounts are always integers in the currency's minor unit (IQD exponent 0). */
export interface CreatePaymentInput {
  orderId: string;
  reference: string;
  amount: bigint;
  currency: 'IQD';
  description: string;
  callbackUrl: string;
  redirectUrl: string;
  locale: 'ckb' | 'ar' | 'en';
}

export interface CreatedPayment {
  providerPaymentId: string;
  formUrl?: string; // Qi Card hosted page
  appLinks?: { personal?: string; business?: string; corporate?: string }; // FIB
  qrCode?: string;
  readableCode?: string;
  validUntil?: string;
}

export type ProviderStatus = 'PAID' | 'UNPAID' | 'DECLINED' | 'EXPIRED' | 'REFUNDED' | 'UNKNOWN';

export interface ProviderStatusResult {
  status: ProviderStatus;
  amount?: bigint;
  currency?: string;
  raw: unknown;
}

export interface PaymentProviderAdapter {
  readonly id: ProviderId;
  mode(): ProviderMode;
  createPayment(input: CreatePaymentInput): Promise<CreatedPayment>;
  getStatus(providerPaymentId: string): Promise<ProviderStatusResult>;
  cancel?(providerPaymentId: string): Promise<void>;
  refund?(providerPaymentId: string, amount?: bigint): Promise<{ providerRefundId?: string }>;
}
