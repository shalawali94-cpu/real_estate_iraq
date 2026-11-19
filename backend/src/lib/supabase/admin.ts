import 'server-only';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

import { serverEnv } from '../env';
import type { Database } from './database.types';

export type AdminClient = SupabaseClient<Database>;

let client: AdminClient | undefined;

/** Service-role client. Bypasses RLS — server code only, never exported to clients. */
export function supabaseAdmin(): AdminClient {
  if (!client) {
    const env = serverEnv();
    client = createClient<Database>(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }
  return client;
}
