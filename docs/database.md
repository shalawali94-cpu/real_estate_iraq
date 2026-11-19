# Real Estate Iraq — Database Design (Supabase Postgres)

Extensions: `pgcrypto`, `postgis`, `pg_trgm`, `unaccent`, `pg_cron` (optional), `pgtap` (tests).
Conventions: `uuid` PKs (`gen_random_uuid()`), `created_at/updated_at timestamptz` with `set_updated_at` trigger, soft delete via `deleted_at` where noted, all money as `bigint` minor units + `char(3)` currency.

## 1. Enums
```
account_type        individual | owner | agent | company | developer
app_role            user | moderator | admin | finance_admin | super_admin
transaction_type    sale | rent | short_term_rent | investment
category_group      residential | commercial | land
publication_status  draft | pending_payment | payment_processing | payment_failed | payment_paid
                    | pending_approval | approved | rejected | published | suspended | expired
listing_state       active | paused | sold | rented | archived
ai_job_status       draft | pending_payment | payment_processing | payment_failed | payment_paid
                    | queued | processing | completed | failed | cancelled | refund_pending | refunded
service_type        PROPERTY_PUBLISHING | AI_VIDEO_GENERATION
payment_provider    FIB | QI_CARD
payment_status      created | pending | processing | paid | failed | cancelled | expired | refunded | partially_refunded
refund_status       none | requested | processing | completed | failed
verification_kind   phone | identity | agency | company | property_document
verification_state  pending | approved | rejected
company_role        owner | manager | agent | viewer
```

## 2. Tables

### Identity
| table | key columns |
|---|---|
| profiles | id (=auth.users.id), full_name, avatar_path, phone, email, governorate_id, district_id, account_type, preferred_locale (ckb/ar/en), phone_verified, identity_verified, rating_avg numeric(3,2), rating_count, is_suspended, deleted_at |
| user_roles | user_id, role app_role, granted_by, granted_at — PK(user_id, role) |
| user_devices | id, user_id, fcm_token unique, platform, locale, last_seen_at |
| user_blocks | blocker_id, blocked_id — PK pair |
| reviews | id, reviewer_id, subject_user_id, property_id?, rating 1–5 check, body, status; unique(reviewer, subject, property) |

### Geography (seeded, admin-editable)
| table | key columns |
|---|---|
| governorates | id, code unique, name_ckb, name_ar, name_en, center geography(Point), sort_order, is_active |
| districts | id, governorate_id FK, name_ckb/ar/en, center, is_active |
| subdistricts | id, district_id FK, names, is_active |
| neighborhoods | id, district_id FK, subdistrict_id?, names, center, is_active |

### Catalog
| table | key columns |
|---|---|
| property_categories | id, slug unique, group category_group, name_ckb/ar/en, icon, field_schema jsonb (which fields apply), allowed_transaction_types[], sort_order, is_active |
| property_features | id, slug, names, category_ids[] (amenities: elevator, generator, garden…) |

### Properties
| table | key columns |
|---|---|
| properties | id, owner_id FK profiles, company_id?, assigned_agent_id?, category_id, transaction_type, title, description, title_i18n jsonb?, price_amount bigint, price_currency, price_negotiable, governorate_id, district_id, neighborhood_id?, address_text, location geography(Point), area_sqm numeric(10,2), bedrooms, bathrooms, floors, property_age_years, building_condition, furnishing, parking, heating, cooling, electricity, water, internet, ownership_doc_status, availability_date, contact_phone, show_phone bool, attributes jsonb (category-specific extras), publication_status, listing_state, is_featured, featured_until, published_at, expires_at, views_count, favorites_count, search_tsv tsvector (generated), image_phash_set bigint[], deleted_at |
| property_feature_links | property_id, feature_id |
| property_images | id, property_id, owner_id, storage_path, thumb_path, width, height, bytes, mime, sort_order, is_cover, phash bigint, ai_variant_of uuid?, ai_label (enhanced/virtual_staging/null), status (uploaded/verified/rejected) |
| property_videos | id, property_id, owner_id, storage_path, poster_path, duration_s, source (user_upload/ai_generated/template_slideshow), ai_job_id? |
| property_documents | id, property_id, owner_id, storage_path (private bucket), doc_type, review_state |
| property_status_history | id, property_id, from_status, to_status, actor_id, reason, created_at (immutable) |
| property_favorites | user_id, property_id, folder text?, created_at — PK pair |
| property_views | id, property_id, viewer_id?, session_hash, created_at (rolled up nightly into views_count) |
| property_reports | id, property_id, reporter_id, reason, details, status, handled_by |
| property_comparisons | id, user_id, property_ids uuid[] check (cardinality ≤ 4) |
| recently_viewed | user_id, property_id, viewed_at — PK pair |
| saved_searches | id, user_id, name, filters jsonb, alert_enabled, last_alerted_at |
| search_alerts | id, saved_search_id, property_id, sent_at — unique pair |

### Companies
| table | key columns |
|---|---|
| companies | id, owner_id, name, slug, logo_path, description_i18n jsonb, office_address, office_location, phones text[], socials jsonb, verified bool, deleted_at |
| company_members | company_id, user_id, role company_role, invited_by, status (invited/active/removed) |
| company_verifications | id, company_id, documents (storage paths), state, reviewed_by |
| leads | id, company_id?, property_id, owner_id, customer_id, source (call/whatsapp/message), status, assigned_to |

### Messaging & notifications
| table | key columns |
|---|---|
| conversations | id, property_id?, company_id?, kind, created_by, last_message_at; unique(property_id, pair_key) |
| conversation_members | conversation_id, user_id, last_read_at, unread_count, muted |
| messages | id, conversation_id, sender_id, body, attachment_path?, created_at, deleted_at |
| message_reports | id, message_id, reporter_id, reason |
| notifications | id, user_id, type, title_key, body_key, params jsonb, data jsonb, read_at, created_at |

### Verification
| verification_requests | id, user_id, kind, subject_id (user/company/property), documents, state, decided_by, decided_at, notes |

### Payments (see payments.md)
| table | key columns |
|---|---|
| payment_settings | service_type PK, price_amount bigint, currency, is_enabled, applies_to jsonb (transaction types / category ids), updated_by |
| payment_providers_config | provider PK, mode (unconfigured/sandbox/live), is_enabled — **no secrets here**; secrets live in Vercel env |
| payment_orders | id, user_id, service_type, property_id?, ai_job_id?, amount bigint, currency, status payment_status, idempotency_key unique, internal_reference unique (e.g. `REI-20261119-7K3Q9`), paid_at, failure_reason, refund_status; partial unique index: one non-terminal/paid order per (service_type, property_id) and per ai_job_id |
| payment_transactions | id, order_id, provider, provider_payment_id unique(provider, id), amount, currency, status, provider_payload jsonb, valid_until, created_at |
| payment_provider_events | id, provider, event_id/dedup_key unique, payload jsonb, signature_valid, processed_at, processing_error |
| payment_refunds | id, order_id, transaction_id, amount, reason, status, provider_refund_id, requested_by |
| payment_audit_logs | id, order_id, actor (user/system/admin id), action, from_status, to_status, details jsonb, created_at — append-only (UPDATE/DELETE revoked + trigger) |
| exchange_rates | base, quote, rate numeric(18,8), source, fetched_at |

### AI
| table | key columns |
|---|---|
| ai_jobs | id, user_id, property_id, kind (video/image_enhance/staging/text), status ai_job_status, options jsonb (duration, aspect, style, music, overlays), input_image_ids uuid[], provider, render_mode (ai/template), attempts, max_attempts, error, output_video_id?, payment_order_id? |
| ai_generations | id, job_id, provider, model, input_ref, output_path, cost_usd_micros bigint, latency_ms, status |
| ai_usage | id, user_id, feature, units, cost_usd_micros, day — for quotas & cost monitoring |
| ai_provider_config | provider, feature, model, is_enabled, priority, daily_budget_usd_micros |

### Admin & platform
| admin_audit_logs | id, admin_id, action, target_table, target_id, before jsonb, after jsonb, ip, created_at (append-only) |
| application_settings | key PK, value jsonb, updated_by (listing expiry days, max images=20, upload limits…) |
| banners | id, image_path, link, locale, starts_at, ends_at |
| jobs | id, type, payload, run_at, attempts, locked_at, status (generic background queue) |

## 3. Key indexes
- properties: `(publication_status, listing_state, published_at desc)` partial `WHERE publication_status='published' AND listing_state='active' AND deleted_at IS NULL`; `(governorate_id, district_id)`; `(category_id, transaction_type)`; `(price_currency, price_amount)`; `(area_sqm)`; GIST(location); GIN(search_tsv); GIN(title gin_trgm_ops).
- messages `(conversation_id, created_at desc)`; notifications `(user_id, created_at desc)`; payment_orders `(user_id, created_at desc)`, `(status, created_at)`.

## 4. Database functions (security definer, called by backend or RLS-safe RPC)
- `search_properties(filters jsonb, cursor, limit)` — public, returns only published/active.
- `property_submit(property_id, actor)` — validates completeness & ownership, decides fee requirement, moves status.
- `payment_mark_paid(order_id, provider_tx_id, amount, currency)` — locks order `FOR UPDATE`, checks amount/currency match, idempotent, moves linked property to `pending_approval` or AI job to `queued`, writes audit log. **Executable only by service_role.**
- `property_moderate(property_id, decision, admin_id, reason)`.
- `ai_job_enqueue(job_id)` — refuses unless linked order is paid.
- `conversation_open(property_id, other_user)`.
- Triggers: updated_at, status history, favorites/views counters, unread counters, search_tsv, notification fan-out to `jobs`.

## 5. RLS summary
| table | select | insert/update/delete (client) |
|---|---|---|
| profiles | public columns via `public_profiles` view; own row full | own row update, but `phone_verified, identity_verified, rating_*, is_suspended` locked by trigger |
| user_roles | own rows | **none** (service role only) |
| geography, categories, features, banners | everyone | none |
| properties | published&active for all; own (any status); company members for company listings; admins | insert/update own while status in (draft, rejected, published*) and only non-status columns; status columns locked by trigger |
| property_images/videos | follows parent visibility | owner, only while parent editable; storage path must start with `{uid}/{property_id}/` |
| property_documents | owner + admins | owner insert |
| favorites, saved_searches, recently_viewed, comparisons | own | own |
| conversations/members/messages | members only | messages insert by non-blocked members; no update except soft delete own |
| notifications | own | update `read_at` only |
| payment_* | orders/transactions/refunds: owner + finance/admin | **none** (service role only) |
| ai_jobs/generations | owner + admins | none (via API) |
| admin_audit_logs, payment_audit_logs | admins only | none; append-only |

## 6. Storage buckets
| bucket | public | path | limits |
|---|---|---|---|
| property-media | public read (published only via signed CDN path for drafts) | `{user_id}/{property_id}/{uuid}.{ext}` | images ≤ 15 MB (jpeg/png/webp/heic), video ≤ 200 MB (mp4/mov) |
| property-docs | private | `{user_id}/{property_id}/...` | pdf/jpeg/png ≤ 20 MB |
| avatars | public | `{user_id}/...` | ≤ 5 MB |
| company-assets | public | `{company_id}/...` | |
| ai-outputs | private → copied to property-media on save | `{user_id}/{job_id}/...` | |
| verification | private | `{user_id}/...` | |

MIME is verified server-side on `/media/confirm` by magic-byte sniffing; files failing are deleted and the row is marked rejected.

## 7. Seed data
19 governorates (incl. Halabja) with all three names; districts for every governorate; neighborhoods seeded first for Erbil, Sulaymaniyah, Duhok, Baghdad, Basra and expanded via admin "Manage Locations". Categories: the 17 from the spec. Settings: both fees 30,000 IQD.
