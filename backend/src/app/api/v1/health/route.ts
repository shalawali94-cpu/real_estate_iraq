import { json, route } from '@/lib/http/handler';
import { providerModes } from '@/payments/registry';

export const GET = route(async () =>
  json({
    status: 'ok',
    service: 'real-estate-iraq-api',
    version: 'v1',
    time: new Date().toISOString(),
    payments: providerModes(),
  }),
);
