# DEVELOPMENT_PROGRESS — Real Estate Iraq

Local path: `C:\dev\real_estate_iraq` · GitHub: shalawali94-cpu/real_estate_iraq (private)
Supabase (Free, Frankfurt): project ref `mvwaajcucfforwymmogn` — linked, migrations pushed
Last updated: 2026-11-21

## Current phase
Phase 5 — Flutter app: **in progress** (Phase 4 backend core done, see below)

### Phase 5 — Flutter app
- [x] Design system, l10n (ckb/ar/en, RTL), theme light/dark, 5-tab shell (640px max width on wide screens)
- [x] Accounts: phone OTP login, guest browsing ("binar"), onboarding profile, edit profile, roles shown, sign-out, account deletion (migration 013 `account_anonymize` + POST /account/delete, test supabase/tests/account.sql 6/6; pushed to cloud)
- [x] Home, Explore (server-side search, paging), property details, favorites
- [x] Add property: type -> photos (up to 20, chosen on device, cover choice) -> details; nothing is uploaded until final save, then draft + photo upload (cover first)
- [x] Review and pay screen: submit, 30,000 IQD fee (from payment_settings, sale only by default), FIB/Qi choice; shows "awaiting setup" until merchant credentials exist; never fakes payment
- [x] My properties (status per listing)
- [x] Messaging: Message button on listing, live inbox (Realtime), chat (Realtime), unread counters, online (presence) + typing (broadcast) indicators
- [ ] Messaging extras: image attachments, block/report UI, push notifications (FCM)
- [ ] Companies/business profiles, verification requests UI, saved searches/alerts UI, comparison, map search/location picker, notifications screen
- [ ] AI Studio (Phase 7)
Local-only helpers: `dev.bat` (start everything), `check.bat`, `save.bat "msg"`, `step.bat "msg"` (check + commit + push), `supabase/dev/publish_drafts.sql` (publishes local drafts, skipping payment).

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
- [x] admin web dropped (decision: admin works inside the mobile app, email+password login)
- [x] supabase/ init + local stack (Docker)
- [ ] CI (GitHub Actions)

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

## Pre-publish checklist (deferred until just before release)
Decision 2026-11-21: finish all app work first; do these right before publishing. Local dev uses test OTP numbers (supabase/config.toml `[auth.sms.test_otp]`, code 123456).
- [ ] SMS provider for OTP (Twilio or Iraqi gateway) + cloud Supabase phone auth settings
- [ ] FIB merchant credentials (sandbox, then production)
- [ ] Qi Card merchant credentials (sandbox, then production)
- [ ] Firebase / FCM project for push notifications
- [ ] Map tiles provider key
- [ ] AI provider keys (image enhancement, video)
- [ ] Video render worker host (fallback slideshow renderer)
- [ ] Apple Developer + Google Play accounts
- [ ] Production Supabase + Vercel environments, backups, monitoring
- [ ] Remove test OTP numbers from any production config
