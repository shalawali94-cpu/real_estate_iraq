# Real Estate Iraq — AI Integrations

All AI calls run in the backend. Provider keys never reach Flutter. Every feature sits behind an adapter so providers can be swapped from the admin "AI Management" screen (`ai_provider_config`).

## 1. Features
| Feature | Paid? | Provider type (initial pick, swappable) | Output labeling |
|---|---|---|---|
| AI assistant search (NL → filters) | free, rate-limited | LLM with JSON/tool output (Claude via AI SDK / AI Gateway) | n/a — results are always real DB rows |
| Description / title / tags / captions | free, quota | LLM | "AI-assisted" marker in editor only |
| Image enhancement (light, color, sharpness, denoise, perspective, exposure) | free quota, then limits | image-to-image enhancement API (e.g. Replicate-hosted models / Cloudinary AI / Claid) | "Enhanced" badge |
| Object removal | quota | inpainting model | "Edited with AI" badge |
| Virtual staging | quota | staging model | **"Virtually staged"** watermark + badge, always |
| AI Video Maker | **30,000 IQD per order** | AI video provider (image-to-video, e.g. Runway / Luma / Kling via API) | "AI-generated video" |
| Template video (fallback) | same order, user informed | our ffmpeg render worker | "Template video" — never called AI |

Originals are never overwritten: AI outputs are new `property_images` rows with `ai_variant_of` → before/after slider in app.

## 2. Assistant: safe NL search
1. LLM receives the user text + a JSON schema of allowed filters (governorate/district ids from a lookup list, category slugs, price range, currency, bedrooms…), returns **only filters** via structured output.
2. Backend validates with zod, maps names → ids from DB, calls `search_properties()`.
3. LLM never writes listing content in answers; the response is the filter chips + real result cards. If nothing matches, the app says so.
Prompt-injection guard: listing text is never fed back into the assistant prompt.

## 3. AI Video Maker pipeline
```
order created (draft) → payment (see payments.md) → ai_job_enqueue (requires paid)
  → worker picks job (SKIP LOCKED)
     1 analyze images (vision LLM: room type, quality score, exterior/interior)
     2 order sequence: exterior → living → kitchen → bedrooms → bath → extras
     3 render mode = 'ai'  : provider image-to-video clips per shot → stitched + overlays (ffmpeg)
       render mode = 'template' (provider down/over budget): Ken Burns motion + transitions in ffmpeg
     4 overlays: price, location, specs, contact (localized ckb/ar/en, RTL-correct with HarfBuzz fonts)
     5 optional licensed music track from our library
     6 encode H.264/AAC: 9:16 1080x1920 · 16:9 1920x1080 · 1:1 1080x1080 ; 15/30/60 s
     7 upload to ai-outputs, create property_videos (source = ai_generated | template_slideshow)
     8 notify user (push + in-app)
  failures: retry up to max_attempts with backoff → free regenerate offered → if still failing
            → refund_pending (finance admin) — payment never silently kept
```
If the AI provider is unavailable **before** payment, the order screen states that a template video will be produced and lets the user decide. If it fails **after** payment, the user is asked to accept a template video or request a refund.

Progress: worker updates `ai_jobs.status` + `progress` (0–100); app listens via Realtime on its own job row.

## 4. Cost control
- `ai_usage` per user/day; quotas in `application_settings`.
- `daily_budget_usd_micros` per provider; when exceeded, features degrade (template video, queue enhancement).
- Admin dashboard: cost per feature, per day, per provider; failed jobs with retry button.

## 5. Credentials needed later
LLM key (or Vercel AI Gateway), image-enhancement provider key, AI video provider key, render worker host (container platform), music library license.
