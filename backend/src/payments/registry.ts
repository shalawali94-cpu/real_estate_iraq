import { UnconfiguredProvider } from './providers/unconfigured';
import type { PaymentProviderAdapter, ProviderId } from './types';

/**
 * Real FIB / Qi Card adapters are registered here in Phase 6, only when
 * their credentials and FIB_MODE / QI_MODE (sandbox|live) are set.
 */
export function getProvider(id: ProviderId): PaymentProviderAdapter {
  switch (id) {
    case 'FIB':
    case 'QI_CARD':
      return new UnconfiguredProvider(id);
  }
}

export function providerModes(): Record<ProviderId, string> {
  return { FIB: getProvider('FIB').mode(), QI_CARD: getProvider('QI_CARD').mode() };
}
