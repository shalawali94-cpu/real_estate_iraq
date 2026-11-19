import { json, route } from '@/lib/http/handler';
import { supabaseAdmin } from '@/lib/supabase/admin';
import { providerModes } from '@/payments/registry';

/** Never throws: reports each dependency's state so deploy problems are visible. */
async function databaseStatus(): Promise<'ok' | 'not_configured' | 'error'> {
  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) return 'not_configured';
  try {
    const { count, error } = await supabaseAdmin()
      .from('governorates')
      .select('id', { count: 'exact', head: true });
    return !error && count === 19 ? 'ok' : 'error';
  } catch {
    return 'error';
  }
}

export const GET = route(async () => {
  const database = await databaseStatus();
  return json(
    {
      status: database === 'error' ? 'degraded' : 'ok',
      service: 'real-estate-iraq-api',
      version: 'v1',
      time: new Date().toISOString(),
      database,
      payments: providerModes(),
    },
    { status: database === 'error' ? 503 : 200 },
  );
});
