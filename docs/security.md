# Real Estate Iraq — Security Model

## Trust boundaries
- Flutter app = untrusted. Holds only the Supabase **anon** key and the user's session (Flutter Secure Storage).
- Backend (Vercel) = trusted. Holds service-role key, provider secrets, AI keys in Vercel encrypted env vars.
- Database = final enforcer. RLS on every table; status/role/money columns are locked by triggers even for row owners.

## Controls
| Threat | Control |
|---|---|
| Privilege escalation | roles only in `user_roles`, writable by service role; JWT claims via access-token hook; admin endpoints re-check role in DB |
| Unauthorized publish | publication_status changes only through SQL functions called by backend; trigger rejects client updates to status columns |
| Fake payment confirmation | server-to-server status verification; `payment_mark_paid` service-role only; webhook signature check (Qi) + always re-query |
| Duplicate transactions | idempotency keys, unique partial indexes, row locks |
| Unpaid AI generation | `ai_job_enqueue` checks paid order inside the same transaction |
| Data exposure | `public_profiles` view hides phone unless `show_phone`; private buckets for docs/verification; signed URLs with short TTL |
| Malicious uploads | signed upload URLs scoped to `{uid}/{property}/`; size limits per bucket; magic-byte MIME sniff on confirm; EXIF GPS stripped from public images; images re-encoded |
| Account takeover | Supabase OTP with rate limits, short OTP expiry, refresh-token rotation; session list & sign-out-all |
| Spam/fraud | per-user/IP rate limits (Upstash Redis or Vercel WAF), listing velocity limits, duplicate image hashing, report pipeline |
| Injection | parameterized queries only (supabase-js / SQL functions), zod validation, no dynamic SQL from input |
| Secrets | none in git; `.env.example` only; separate staging/prod projects |
| Audit | admin_audit_logs + payment_audit_logs append-only |
| Privacy | account deletion = anonymize profile, remove media, keep financial records as legally required |

## Testing
pgTAP RLS tests impersonating anon / user A / user B / company agent / moderator / finance_admin / super_admin; API authorization tests; webhook forgery tests.
