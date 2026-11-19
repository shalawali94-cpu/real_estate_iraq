# DEVELOPMENT_PROGRESS — Real Estate Iraq

Local path: `C:\dev\real_estate_iraq`
Last updated: 2026-11-19

## Current phase
Phase 1 — Architecture: **done, awaiting review**
Next: Phase 2 — Project foundation

## Completed
- [x] docs/architecture.md — topology, decisions, modules, roles, workflows, environments
- [x] docs/database.md — enums, all tables, indexes, SQL functions, RLS matrix, storage buckets, seed plan
- [x] docs/payments.md — engine, guarantees, adapter interface, FIB + Qi Card notes from public docs, test plan
- [x] docs/ai_integrations.md — features, safe assistant, video pipeline, cost control
- [x] docs/security.md
- [x] docs/screens.md
- [x] docs/credentials.md — external services + env var names
- [x] docs/roadmap.md

## Not started
Phases 2–10 (see docs/roadmap.md). Nothing is implemented yet; no integration is live.

## External services
None created yet (see docs/credentials.md).

## Open questions / to confirm
- FIB: refund rules, callback signing/IPs, payment validity window
- Qi Card: terminal + signing details, status endpoint, refund API
- AI video provider choice (cost per 30/60 s clip vs. 30,000 IQD price)
- SMS provider deliverability to Iraqi carriers (Asiacell, Zain, Korek)
