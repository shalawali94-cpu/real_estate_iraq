# DEVELOPMENT_PROGRESS — Real Estate Iraq

Local path: `C:\dev\real_estate_iraq` · GitHub: shalawali94-cpu/real_estate_iraq (private)
Supabase (Free, Frankfurt): project ref `mvwaajcucfforwymmogn` — linked, migrations pushed
Last updated: 2026-11-19

## Current phase
Phase 4 — Backend: **in progress**

### Phase 4 — Backend
- [x] Vercel project `real-estate-iraq-api` (Hobby, root = backend/), auto-deploys on push to main
- [x] Prod URL: https://real-estate-iraq-api.vercel.app — /api/v1/health returns database: ok
- [x] Vercel env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, CRON_SECRET
- [x] Functions run in fra1 (backend/vercel.json) next to the database
- [x] Typed Supabase client (`npm run gen:types` after every migration)
- [x] POST /properties/{id}/submit · POST /media/upload-url · POST /media/confirm (magic-byte MIME sniffing, size, ≤20 photos)
- [x] POST /payments/orders (Idempotency-Key, server price, provider must be configured) · GET /payments/orders/{id}
- [x] Admin: GET /admin/properties (queue) · POST /admin/properties/{id}/moderate (approve/reject/suspend/unsuspend, audited, owner notified)
- [x] Cron GET /cron/daily (Bearer CRON_SECRET, 01:00 UTC): expires listings after 90 days, closes stale orders
- [x] Migration 012 moderation + maintenance (tests 9/9); backend unit tests 19/19
- [ ] payment webhooks + reconciler (with real FIB/Qi adapters, Phase 6)
- [ ] companies/members invites, messaging helpers, push notifications sender (FCM), verification decisions
- [ ] admin API: users, roles, prices, refunds, reports; rate limiting (Upstash or Vercel WAF)
- [ ] AI endpoints (Phase 7)

## Done
### Phase 1 — Architecture ✅
docs/ (architecture, database, payments, ai_integrations, security, screens, credentials, roadmap)

### Phase 2 — Foundation (partial)
- [x] mobile/ Flutter 3.44: Riverpod, GoRouter, ckb (default, RTL) / ar / en, light/dark, 5-tab shell,
      working language + theme settings. `flutter analyze` clean, 3 widget tests pass.
      Home/Explore/Add/Favorites are placeholders until Phase 5.
- [x] backend/ Next.js 16: /api/v1/health, typed error codes, request ids, Supabase admin client,
      auth guard, payment adapter interface (FIB/QI = unconfigured, never fake success). 5 vitest tests pass, build OK.
- [x] admin/ created with create-next-app (no app code yet)
- [x] supabase/ init + local stack (Docker)
- [ ] admin skeleton, CI (GitHub Actions)

### Phase 3 — Database (migrations pushed to cloud)
- [x] 001 core roles: user_roles, has_role(), is_staff()
- [x] 002 geography: 19 governorates, 121 districts, 31 neighborhoods (Erbil, Sulaymaniyah);
      users suggest missing neighborhoods (pending → staff approves), dedupe + 5/day limit
- [x] 003 profiles, devices, blocks, avatars bucket (tests: 7/7)
- [x] 004 categories (17), features (12), properties, images (max 20), favorites, status history,
      property-media bucket (tests: 15/15). Fixes: protect triggers use current_user; anon can run is_staff()
- [x] 005 payment engine: settings (30,000 IQD each), orders, transactions, provider events, refunds,
      append-only audit; service_role-only functions (submit, create order, attach tx, mark paid/failed)
- [x] 006 public_profiles view → get_public_profiles(ids) function (linter CRITICAL fixed)
- [x] 007 companies, members (owner/manager/agent/viewer), company listings, leads (tests 17/17)
- [x] 008 conversations, messages (Realtime), message reports, notifications, blocking
- [x] 009 strict privileges: local stack now matches cloud (no auto-grant)
- [x] 010 search_properties() RPC (filters, keyword, GPS radius, map bbox, sorts), views, recently viewed,
      saved searches (≤20), comparisons (≤4), property reports, verification requests + private bucket (tests 18/18)
- [x] 011 AI jobs (paid video orders → queued only after payment, 3 attempts, 1 free regeneration, refunds),
      property_videos (ai/template labeled), ai usage/cost/provider config, admin audit, app settings, banners,
      jobs queue (tests 16/16; payments 21/21)
- [ ] pgTAP test suite + CI (current tests are SQL scripts in supabase/tests)

## How to test locally
```
supabase db reset
docker exec -i supabase_db_real_estate_iraq psql -U postgres -d postgres < supabase\tests\<file>.sql
```
Push to cloud: `supabase db push --remote` (add `--include-seed` when seed files change)

## External services
Created: GitHub repo, Supabase project, Vercel project (backend). Not yet: Vercel, SMS provider, Firebase, map tiles, FIB, Qi Card, AI providers.

## Open questions
- FIB/Qi Card merchant onboarding (start early)
- Full neighborhood list per governorate (official CSV if available)
