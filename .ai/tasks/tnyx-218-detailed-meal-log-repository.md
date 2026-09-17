# TNYX-218 — Detailed MealLog Repository + Atomic Create/Read Foundation

**Status:** Ready for review
**Primary owner:** Nutrition persistence / Supabase
**Affected platforms:** Nutrition Dart repository + Supabase/Postgres; no UI change

## Owner Approval and Scope Boundary

**Approval status:** Approved
**Approval evidence:** Owner said `go` on 2026-09-17 and explicitly required following root `AGENTS.md`.
**Approved boundary:** Provider-neutral detailed create inputs/capability, one authenticated atomic detailed-create RPC, canonical detailed parent/item reads, batch item hydration, and same-mutation idempotency/reconciliation.
**Explicit non-changes:** No Meal Editor `Log Meal` activation, parser/provider/API wiring, UI/controller change, detailed update/delete, new parent/child table or column, membership/ads, or `services/api` implementation.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Independent fallback review at handoff
**Implementation ownership state:** Handoff for review
**Repository state last verified:** `main` = `80009fbb55fae50834fb9bab13c89b9f0ac2515b`
**Branch:** `tnyx/tnyx-218-n20a-9-detailed-meallog-repository-atomic-createread`
**Implementation HEAD reviewed:** `3c9547123620c207c372bf0a76df4988fa5a26cf`
**PR / tracker:** GitHub PR #275; Linear TNYX-218
**Current implementation state:** Bounded persistence implementation complete; no Meal Editor/parser activation.
**Validation completed at implementation HEAD:** Flutter CI PASS; Supabase Database CI PASS; changed-file/scope audit PASS; review threads none; live Supabase migration/advisor reconciliation complete.
**Current blocker:** None known.
**Open review finding IDs:** None.
**Next exact action:** Review this handoff-only commit on the same bounded diff, then keep PR in review until owner explicitly authorizes merge.

## 1. Delivered Behavior

- Added Nutrition-owned `DetailedMealLogCreate` and `DetailedMealLogCreateItem` provider-neutral inputs with no caller-owned durable IDs.
- Added optional `DetailedMealLogCreateRepository` capability without widening every manual-only repository double.
- Added in-memory detailed create/idempotency mirror.
- Extended `SupabaseMealLogRepository` with atomic detailed-create RPC seam and batch child-read seam.
- Canonical reads now decode manual and detailed parent modes and fail closed on malformed/missing detailed children.
- Detailed list hydration batches child reads instead of per-parent N+1 requests; range reads use the same canonical decode path.
- Added `public.create_detailed_meal_log(...)` atomic RPC and focused SQL regression matrix.
- Wired the TNYX-218 database matrix into Supabase Database CI.

## 2. Security and Persistence Contract

`public.create_detailed_meal_log(...)` is intentionally a narrow `SECURITY DEFINER` boundary because authenticated direct child INSERT/UPDATE/DELETE remains revoked. It uses `SET search_path = ''`, fully-qualified relations, requires `auth.uid()`, accepts no caller `user_id` or durable IDs, revokes default/public/anon/service-role execute, and grants execute only to `authenticated`.

Same `(user_id, client_mutation_id)` retries reconcile the same aggregate only when parent and ordered item facts match. Materially different facts fail with the canonical mutation conflict. Ambiguous transport outcomes retain the same mutation identity for reconciliation.

## 3. Scope Audit

Implementation diff against `main` remained confined to 9 files before this handoff refresh:

1. `.ai/tasks/tnyx-218-detailed-meal-log-repository.md`
2. `.github/workflows/supabase-db-ci.yml`
3. `apps/features/nutrition/lib/src/data/in_memory_meal_log_repository.dart`
4. `apps/features/nutrition/lib/src/data/repositories/supabase_meal_log_repository.dart`
5. `apps/features/nutrition/lib/src/domain/repositories/detailed_meal_log_create_repository.dart`
6. `apps/features/nutrition/lib/src/domain/repositories/repositories.dart`
7. `apps/features/nutrition/test/data/detailed_meal_log_repository_test.dart`
8. `supabase/migrations/20260917092920_create_detailed_meal_log_rpc.sql`
9. `supabase/tests/database/tnyx_218_detailed_meal_log_repository.test.sql`

No UI/controller/navigation/parser/provider or `services/api` files are in scope.

## 4. Validation and Review

At implementation HEAD `3c9547123620c207c372bf0a76df4988fa5a26cf`:

- Flutter CI run #2608: **PASS**.
- Supabase Database CI run #56: **PASS**.
- Supabase migration `20260917092920_create_detailed_meal_log_rpc` is applied to the live `tio-world` project.
- SQL matrix covers authenticated-only execute, direct-child-write denial, exact retry identity, ordered children, mutation conflict, invalid input rollback, non-owner visibility, and manual compatibility.
- Dart coverage includes detailed create validation, retry/conflict, ambiguous outcome reconciliation, `readById`, selected-day mixed-mode batch hydration, persisted item order, and fail-closed malformed rows.
- Existing range capability uses the shared canonical decoder/batch hydration path. A dedicated TNYX-218 range-only regression test is not present in this focused test file; this is test-hardening follow-up rather than an observed functional defect because the implementation path is shared and exact-head CI is green.
- GitHub review threads: none.
- Submitted GitHub reviews: none at handoff.
- Live Supabase Security Advisor reports the expected additional authenticated `SECURITY DEFINER` warning for this intentionally exposed RPC; baseline count moved from 4 to 5. Performance findings show no TNYX-218-specific regression.

## 5. Implementation Checklist

- [x] Reconcile Linear/GitHub/main/docs/live Supabase state.
- [x] Freeze exact RPC/security/repository boundaries.
- [x] Add detailed create contract/capability.
- [x] Add in-memory detailed create/idempotency mirror.
- [x] Add Supabase RPC + batch child read gateway capabilities.
- [x] Add manual+detailed canonical row decoding.
- [x] Add atomic RPC migration and SQL matrix.
- [x] Wire focused DB matrix into Supabase CI.
- [x] Add focused Dart create/read/idempotency/fail-closed tests.
- [x] Run exact implementation-head CI and scope audit.
- [x] Reconcile active handoff for review.

## 6. Known Deferred Work

Detailed update/delete, Meal Editor final `Log Meal` activation, and TNYX-207 natural-language parser/provider flow remain separate later slices. Do not activate them in TNYX-218.

## 7. Final Status

`READY_FOR_REVIEW` for the bounded TNYX-218 persistence slice. Merge remains owner-gated. After merge, perform a fresh audit before choosing the smallest Meal Editor final-save activation slice.