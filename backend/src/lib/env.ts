import 'server-only';
import { z } from 'zod';

const serverEnvSchema = z.object({
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(20),
});

export type ServerEnv = z.infer<typeof serverEnvSchema>;

let cached: ServerEnv | undefined;

/** Parsed lazily so routes that don't need the DB (health) still work. */
export function serverEnv(): ServerEnv {
  cached ??= serverEnvSchema.parse(process.env);
  return cached;
}
