# Real Estate Iraq — External Services & Credentials

Nothing below exists yet. We create them step by step; each is marked with the phase that needs it.

| # | Service | Needed for | Phase | Status |
|---|---|---|---|---|
| 1 | GitHub repo | source control | 2 | to create |
| 2 | Supabase project (staging) | DB, auth, storage | 3 | to create |
| 3 | Supabase project (production) | go-live | 10 | later |
| 4 | Vercel account + 2 projects (backend, admin) | API, admin | 4 | to create |
| 5 | SMS provider for OTP to +964 (Twilio Verify recommended) | phone login | 4 | to create |
| 6 | Firebase project (FCM) | push notifications | 5 | to create |
| 7 | Map tiles key (MapTiler/Mapbox) | maps | 5 | to create |
| 8 | FIB sandbox → merchant credentials | publishing + video fees | 6 | apply early (approval takes time) |
| 9 | Qi Card UAT terminal → merchant credentials | publishing + video fees | 6 | apply early |
| 10 | LLM API (Anthropic or Vercel AI Gateway) | assistant, text | 7 | later |
| 11 | Image enhancement provider | AI Studio | 7 | later |
| 12 | AI video provider | AI Video Maker | 7 | later |
| 13 | Container host for render worker (Fly.io / Railway / Cloud Run) | template + stitching | 7 | later |
| 14 | Sentry | error monitoring | 9 | later |
| 15 | Apple Developer + Google Play accounts | store release | 10 | later |
| 16 | Business registration docs | FIB/Qi merchant onboarding | 6 | your side |

Start FIB and Qi Card merchant applications soon — they are the longest lead-time items.

## Environment variables (names only — values go in Vercel / local `.env`, never git)
```
# backend
SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_JWT_SECRET
FIB_BASE_URL, FIB_CLIENT_ID, FIB_CLIENT_SECRET, FIB_MODE
QI_BASE_URL, QI_TERMINAL_ID, QI_USERNAME, QI_PASSWORD, QI_SIGNING_KEY, QI_WEBHOOK_SECRET, QI_MODE
PUBLIC_API_BASE_URL, APP_DEEP_LINK_SCHEME
ANTHROPIC_API_KEY | AI_GATEWAY_API_KEY, IMAGE_AI_KEY, VIDEO_AI_KEY
RENDER_WORKER_URL, RENDER_WORKER_TOKEN
FCM_SERVICE_ACCOUNT_JSON
UPSTASH_REDIS_REST_URL, UPSTASH_REDIS_REST_TOKEN
SENTRY_DSN
# mobile (--dart-define, public values only)
SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL, MAP_TILE_URL, MAP_TILE_KEY, SENTRY_DSN
# admin
NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, API_BASE_URL
```
