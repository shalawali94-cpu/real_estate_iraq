# Real Estate Iraq — Development Roadmap

Each phase ends with: files listed, tests run, results recorded in DEVELOPMENT_PROGRESS.md, git commit + push.

| Phase | Deliverable | Exit criteria |
|---|---|---|
| 1 Architecture | docs/ (this set) | reviewed by Shalaw |
| 2 Foundation | monorepo skeleton: Flutter app boots with theme + 3 locales + router; backend & admin Next.js apps with health route; supabase CLI init; lint/format; CI (GitHub Actions) | `flutter analyze`, `flutter test`, `npm run build` all green; pushed to GitHub |
| 3 Database | migrations for all tables, enums, functions, triggers, RLS, storage buckets; geography + categories seed | `supabase db reset` clean; pgTAP RLS suite green |
| 4 Backend | API modules (auth, users, properties, media, search, companies, messaging, notifications, verification, payments engine w/ adapters in unconfigured mode, admin) | API tests green; deployed to Vercel staging |
| 5 Flutter | design system + all screens wired to real staging backend | widget + integration tests; RTL golden tests |
| 6 Payments | FIB sandbox + Qi UAT adapters, webhooks, reconciler | payment test plan green in sandbox |
| 7 AI | assistant, text tools, image enhance, video maker + render worker | AI test plan green; cost dashboard |
| 8 Admin | all modules, role permissions, payment analytics | admin e2e tests |
| 9 QA | full 20-step workflow test, security tests, device matrix | all green, issues closed |
| 10 Deploy | prod Supabase/Vercel, store builds, monitoring, backups, runbooks | release candidate |

Parallel track (your side, start now): FIB + Qi Card merchant applications.
