# Real Estate Iraq — System Architecture

Status: Phase 1 design (v0.1, 2026-11-19)

## 1. High-level topology

```
 ┌──────────────────────────┐        ┌───────────────────────────┐
 │ Flutter app (Android/iOS)│        │ Admin dashboard (Next.js) │
 │ Riverpod · GoRouter · Dio│        │ hosted on Vercel          │
 └──────┬─────────┬─────────┘        └─────────────┬─────────────┘
        │         │ (1) public reads + realtime     │
        │         ▼     via Supabase anon key + RLS │
        │   ┌──────────────────────────────────┐    │
        │   │ Supabase                          │◄──┤
        │   │  Postgres + PostGIS + pg_trgm     │    │
        │   │  Auth (phone OTP)  Storage  RT    │    │
        │   └──────────────▲───────────────────┘    │
        │ (2) all writes   │ service role (server only)
        ▼     that matter  │                         ▼
 ┌─────────────────────────┴──────────────────────────────────┐
 │ Backend API — Next.js route handlers on Vercel (/api/v1/*) │
 │  auth guard · zod validation · rate limit · idempotency    │
 │  payments engine │ AI orchestration │ moderation │ admin   │
 └───┬──────────────┬───────────────┬────────────────┬────────┘
     │              │               │                │
  FIB API     Qi Card gateway   AI providers     Render worker
 (OAuth2)     (REST, 3DS form)  (image/video)    (ffmpeg fallback,
                                                  queue-driven)
                                    FCM (push)
```

### Rule of the two paths
1. **Direct to Supabase (anon key + user JWT, RLS enforced):** read published listings, search RPCs, geography, own profile reads, favorites, messaging (Realtime), uploading media into the user's own storage prefix.
2. **Through the Vercel API (service role, server-side):** anything involving money, status transitions, roles, moderation, AI jobs, verification decisions, notifications fan-out. RLS denies these writes to clients at the DB level, so bypassing the API is impossible, not just discouraged.

## 2. Key technical decisions

| Area | Decision | Why |
|---|---|---|
| Backend runtime | Next.js (App Router route handlers, Node runtime, TypeScript) on Vercel | Typed, first-class on Vercel, same stack as admin |
| Admin | Separate Next.js app (`admin/`) + shadcn/ui | Isolated deploy & auth, can be IP/SSO restricted |
| Validation | zod schemas shared in `packages/contracts` | One source of typed request/response models |
| DB access | supabase-js with service role in backend; SQL functions for multi-step transactional ops | Atomic status changes inside Postgres |
| Money | `bigint` amounts in the currency's minor unit + `currency_code`; IQD exponent 0 | No floating point anywhere |
| Search | Postgres: btree/GIN indexes, `pg_trgm` for keyword, `tsvector` multilingual, PostGIS `geography` for map/nearby; `search_properties()` RPC with keyset pagination | No extra search vendor needed at launch; swap to Meilisearch/Typesense later behind the same RPC |
| Jobs | `jobs` table + Vercel Cron/Queues trigger; heavy video rendering on a container worker (ffmpeg) | Vercel functions are not suited to long ffmpeg renders |
| Maps | `flutter_map` with configurable tile provider (MapTiler/Mapbox/Google via config) | Provider-independent as required |
| Push | Firebase Cloud Messaging; history in `notifications` table | Standard on Android/iOS |
| SMS OTP | Supabase phone auth with a provider that delivers to +964 (Twilio Verify recommended; alternatively Supabase "Send SMS" hook to a local Iraqi SMS gateway) | Supabase-native session handling |
| i18n | Flutter `gen_l10n` ARB files (ckb default, ar, en); server returns error **codes**, client localizes | Language switch never touches data |
| Currency | IQD primary, USD secondary; listings store original currency; optional conversion via `exchange_rates` table fed by a configurable service | No hardcoded rates |

## 3. Monorepo layout

```
real_estate_iraq/
  mobile/                 Flutter app (feature-first clean architecture)
  backend/                Next.js API on Vercel (/api/v1/...)
  admin/                  Next.js admin dashboard
  packages/contracts/     zod schemas + generated TS types (shared)
  supabase/
    migrations/           ordered SQL migrations (source of truth)
    seed/                 geography + categories + settings seed
    functions/            edge functions (only where justified)
    tests/                pgTAP RLS & function tests
  workers/render/         ffmpeg slideshow renderer (Docker)
  docs/
  DEVELOPMENT_PROGRESS.md
```

### Flutter internal structure (per feature)
```
features/<feature>/
  data/         dto (freezed/json_serializable), datasources (supabase / api), repositories impl
  domain/       entities, repository interfaces, use cases
  presentation/ screens, widgets, riverpod providers/controllers
```
`core/` holds: Dio client (auth interceptor, retry w/ backoff, idempotency header), Supabase client, error model, result type, logger, connectivity. `theme/` holds the design system tokens.

## 4. Modules (backend)

| Module | Endpoints (v1) | Notes |
|---|---|---|
| auth | `/auth/session`, `/auth/account` (DELETE) | Supabase does OTP; backend handles account deletion & role onboarding |
| users | `/users/me`, `/users/:id/public` | profile update with validation |
| properties | CRUD, `/properties/:id/submit`, `/pause`, `/reactivate`, `/mark-sold`, `/mark-rented`, `/archive` | state machine enforced in SQL |
| media | `/media/upload-url`, `/media/confirm`, reorder, cover | signed upload URLs, MIME sniffing on confirm |
| search | `/search` (also exposed as RPC), saved searches, alerts | |
| companies | profile, members, invitations, assignment, leads | company-scoped permissions |
| messages | `/conversations` create/block/report | messages themselves via Supabase Realtime + RLS |
| favorites / comparisons | | |
| notifications | list, mark read, register device token | |
| verification | submit request, admin decide | |
| payments | `/payments/orders`, `/payments/orders/:id`, `/payments/fib/*`, `/payments/qi/*`, `/payments/webhooks/{fib,qi}` | see payments.md |
| ai | `/ai/assistant/query`, `/ai/text/*`, `/ai/image/enhance`, `/ai/video/orders` | see ai_integrations.md |
| admin | users, properties moderation, categories, locations, payments, refunds, prices, AI config, settings | requires admin role, audit-logged |

## 5. Roles & authorization

Platform roles (table `user_roles`, granted only by backend/super admin):
`user` (default) · `moderator` · `admin` · `finance_admin` · `super_admin`.

Account type (profile attribute, user-selectable at onboarding, not a privilege): `individual`, `owner`, `agent`, `company`, `developer`.

Company roles (table `company_members.role`): `owner`, `manager`, `agent`, `viewer`.

JWT custom claims are added through a Supabase **custom access token hook** reading `user_roles`, so RLS can check `auth.jwt()->'app_roles'` without extra lookups; critical admin checks also re-verify in the DB.

## 6. Core workflows

### 6.1 Property publication (sale listing, fee required)
```
draft ──submit──► pending_payment ──order created──► payment_processing
                      ▲                                   │
                      └──── payment_failed ◄──fail────────┤
                                                          │ verified by backend
                                                          ▼
                                                    payment_paid ─► pending_approval
                                                                       │
                                     rejected ◄──admin reject──────────┤
                                                                       │ admin approve
                                                                       ▼
                                                     approved ─► published ─► expired
                                                                    │  ▲
                                                           suspended ◄──┘ (admin)
```
- If fee is not required for the category/transaction type (admin-configurable in `payment_settings`), `submit` jumps to `pending_approval`.
- Edits to a published listing that touch material fields re-enter `pending_approval` without a new fee.
- Owner actions on published listings: pause/reactivate, mark sold/rented, archive (separate `listing_state` flags so moderation status stays intact).

### 6.2 AI video order
`draft → pending_payment → payment_processing → payment_paid → queued → processing → completed`
failure branches: `failed` (retry ≤ N, free regeneration), `cancelled`, `refund_pending → refunded`.
A job can only be enqueued by the SQL function that also checks the linked order is `paid`.

### 6.3 Messaging
Buyer taps "Message" → backend `POST /conversations` (dedup per property+pair, checks block list) → both members subscribe to `messages` filtered by conversation via Realtime → insert allowed by RLS only for members not blocked → trigger updates `unread_count`, enqueues push.

## 7. Infrastructure & environments

| Env | Supabase | Vercel | Payments |
|---|---|---|---|
| local | `supabase start` (Docker) | `next dev` | provider adapters in `unconfigured` mode |
| staging | project `rei-staging` | preview + staging domain | FIB stage, Qi UAT sandbox |
| production | project `rei-prod` (eu-central-1 or nearest) | production | live credentials |

Backups: Supabase PITR on prod; weekly logical dump to off-site bucket. Monitoring: Vercel logs + Sentry (mobile, backend, admin); payment reconciliation job daily.

## 8. Added features (CTO judgment)
Listing expiry & renewal (90 days default), duplicate listing detection (perceptual image hash + address/price similarity), basic fraud signals (velocity limits, reused images across accounts), view analytics, user reviews (post-contact only), lead tracking for companies, payment reconciliation job, storage quotas, AI cost caps, accessibility (text scale, contrast, screen reader labels in 3 languages).
