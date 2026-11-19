import { describe, expect, it, vi } from 'vitest';

vi.mock('server-only', () => ({}));

import { GET } from '@/app/api/v1/health/route';
import { ApiError, ErrorCode } from '@/lib/http/errors';
import { route } from '@/lib/http/handler';
import { getProvider } from '@/payments/registry';

describe('health', () => {
  it('returns ok and reports providers as unconfigured', async () => {
    const res = await GET(new Request('http://x/api/v1/health'), undefined);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.status).toBe('ok');
    expect(body.payments).toEqual({ FIB: 'unconfigured', QI_CARD: 'unconfigured' });
    expect(res.headers.get('x-request-id')).toBeTruthy();
  });
});

describe('error handling', () => {
  it('maps ApiError to its status and code', async () => {
    const h = route(async () => {
      throw new ApiError(ErrorCode.FORBIDDEN);
    });
    const res = await h(new Request('http://x'), undefined);
    expect(res.status).toBe(403);
    expect((await res.json()).error.code).toBe('FORBIDDEN');
  });

  it('hides unknown errors behind INTERNAL', async () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {});
    const h = route(async () => {
      throw new Error('db password leaked?');
    });
    const res = await h(new Request('http://x'), undefined);
    const body = await res.json();
    expect(res.status).toBe(500);
    expect(body.error.code).toBe('INTERNAL');
    expect(JSON.stringify(body)).not.toContain('password');
    spy.mockRestore();
  });
});

describe('payments without credentials', () => {
  it.each(['FIB', 'QI_CARD'] as const)('%s never fakes success', async (id) => {
    const p = getProvider(id);
    expect(p.mode()).toBe('unconfigured');
    await expect(
      p.createPayment({
        orderId: 'o1',
        reference: 'REI-TEST',
        amount: 30000n,
        currency: 'IQD',
        description: 'test',
        callbackUrl: 'http://x',
        redirectUrl: 'http://x',
        locale: 'ckb',
      }),
    ).rejects.toMatchObject({ code: 'PAYMENT_PROVIDER_NOT_CONFIGURED' });
  });
});
