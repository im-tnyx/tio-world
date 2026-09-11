# TNYX-194 — N20A-5 Manual MealLog physical persistence foundation

**Status:** In Review
**Primary owner:** Supabase persistence / Nutrition
**Affected platforms:** Supabase database only; CI database validation

## Owner Approval and Scope Boundary

**Trigger:** Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** Owner approved the proposed TNYX-194 physical shape after the 2026-09-11 fresh readiness audit and then instructed implementation to proceed.
**Approved product/UI/data-shape boundaries:** One canonical `public.meal_log_entries` table for manual-mode actual history, canonical `NutritionSnapshot` JSON, consumed instant + durable local date + timezone context, capture source, own-row CRUD RLS, explicit grants, Diary index, `updated_at` trigger, focused SQL tests.
**Explicit non-changes:** No detailed items, serving/serving-size persistence, meal image/media, provider IDs, idempotency/version fields, offline queue, repository adapter, Quick Add submit/edit/delete wiring, visible UI, membership/ads, or `services/api` work.

## Active Handoff

**Planning owner:** TNYX-113 / TNYX-194
**Implementation owner:** ChatGPT
**Review owner:** Owner / manual PR review
**Implementation ownership state:** Handoff pending
**Repository state last verified:** 2026-09-11
**Branch:** `tnyx/tnyx-194-n20a-5-manual-meallog-physical-persistence-foundation`
**HEAD SHA:** validated implementation head `8f70cf4ad4aaf79c44aebe3493f0828211194455`; this handoff reconciliation is docs-only
**Observed working-tree state:** Connector-managed branch; local working tree unavailable
**Observed uncommitted/dirty files:** Not observable through GitHub connector
**PR / tracker:** Draft PR #253; TNYX-194 transitioning to `In Review`
**Current implementation state:** Bounded migration, focused SQL matrix, and DB CI hook implemented. No hosted migration has been durably applied.
**Relevant execution surface:** `supabase/migrations`, `supabase/tests/database`, `.github/workflows/supabase-db-ci.yml`
**Validation completed at SHA:** `8f70cf4ad4aaf79c44aebe3493f0828211194455`
**Validation remaining:** Owner review/merge authorization; hosted apply + post-apply advisors belong only after the approved merge/apply gate.
**Current blocker:** None in implementation. Hosted production apply remains intentionally gated.
**Open review finding IDs:** None
**Next exact action:** Owner/manual review of draft PR #253. Do not apply the hosted migration or enable Quick Add save UI from this handoff.

## Global UI / Design-System Guardrail

No Flutter UI or visible product behavior changes in this task.

## 1. Discovery

### User Outcome

Establish the first durable, secure persistence owner for manual MealLog history so a later repository/reliability slice can safely wire Quick Add without inventing a competing storage model.

### Success Criteria

- `public.meal_log_entries` exists as the one canonical future MealLog table.
- V1 is constrained to `mode = 'manual'` and requires `manual_nutrition_snapshot`.
- `consumed_at` and `consumed_local_date` remain separate durable facts.
- At least one meaningful consumed timezone context value is retained.
- The current `NutritionSnapshot` JSON contract is preserved without duplicate macro columns.
- `anon` gets no table access; authenticated users get own-row CRUD only; `service_role` gets explicit DML grants.
- SQL tests prove schema, checks, grants, RLS, index, trigger, and validator behavior.

### Scope

Database migration + database test + CI hook only.

### Non-Goals

Serving/serving-size, `MealLogItemSnapshot`, meal images, detailed mode, provider provenance, repository/DTO wiring, idempotency/concurrency, offline behavior, Quick Add submit/edit/delete, Diary read models, UI changes.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `MealLogEntry`, `NutritionSnapshot`, `NutrientId`, `MealLogCaptureSource`, current migrations, DB CI workflow, hosted table/migration/advisor state.
- Existing pattern followed: `body_weight_logs` for UUID ownership/FK/index/trigger/RLS and `private.is_valid_meal_categories_config_v1(jsonb)` for hardened private JSON validation.
- Checked-in Supabase Postgres guidance requires FK indexing; the Diary composite index starts with `user_id`, satisfying the ownership FK/CASCADE access path.
- Supabase current guidance was re-verified: grants and RLS are separate controls; client defaults are narrowed; owner policies use `(select auth.uid())`.
- Hosted `private` schema ACL was checked: `authenticated` and `service_role` have USAGE; `anon` does not, matching the existing private-helper pattern.
- Hosted rollback dry-runs validated the proposed table/validator/grants/RLS behavior without leaving durable schema objects.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| One canonical `meal_log_entries` table | Locked | Avoid manual/detailed competing history owners | TNYX-113 / owner |
| Manual-only V1 constraint | Locked | Detailed item/serving contract is intentionally unresolved | TNYX-194 / owner |
| DB `id` is UUID; domain identity stays opaque `String` | Locked for this slice | Matches existing multi-row owner pattern without coupling shared domain API to UUID parsing | Implementation audit |
| Snapshot uses canonical JSON only | Locked | Avoid duplicate authoritative macro columns | TNYX-187 / TNYX-194 |
| Unknown future nutrient keys remain forward-compatible | Locked | Current `NutritionSnapshot.fromJson` ignores unknown identities rather than remapping/failing unrelated known data | Existing shared codec |
| Known nutrient values must be numeric and non-negative | Locked | Mirrors domain validation for currently known nutrients | Existing shared codec |
| `anon` table privileges are explicitly revoked | Locked | Current project defaults are broad; grants must be narrowed separately from RLS | Supabase current guidance |
| Serving + serving size | Deferred | Both will be durable detailed-item facts, but belong to `MealLogItemSnapshot`, not manual/coarse persistence | Owner / TNYX-113 |
| Meal image | Deferred | Requires separate media/storage lifecycle contract | Owner / later media slice |

## 4. Architecture Design

### Chosen Approach

```text
MealLogEntry.manual (shared domain, already merged)
        ↓ later repository codec
public.meal_log_entries
        ├─ manual scalar/time facts
        └─ manual_nutrition_snapshot jsonb
             ↓ CHECK
private.is_valid_nutrition_snapshot_v1(jsonb)
```

The validator requires the current envelope fields and integer `schemaVersion`, validates known current nutrient amounts, and deliberately tolerates unknown nutrient identities so future registry additions do not corrupt older clients.

### Ownership and Data Flow

```text
Future UI -> Nutrition controller -> MealLogRepository -> Supabase adapter -> public.meal_log_entries
```

This task stops at the database boundary.

### Alternative Rejected

- Separate `manual_meal_logs` table: creates competing history ownership and makes detailed-mode migration harder.
- Separate calorie/protein/carb/fat columns as truth: duplicates `NutritionSnapshot` and risks drift.
- `auth.users` as domain FK: repository governance uses `public.users` as application/domain root.
- Broad default grants plus RLS only: unnecessarily exposes operations at the grant layer.

### Failure and Accessibility States

No UI states are introduced. Invalid physical rows fail at CHECK/FK/grant/RLS boundaries.

## 5. Implementation Plan

- [x] Fresh GitHub/Linear/Supabase audit
- [x] Owner implementation approval
- [x] Create bounded branch and mark TNYX-194 In Progress
- [x] Add `meal_log_entries` migration
- [x] Add focused SQL test matrix
- [x] Wire SQL matrix into Supabase DB CI
- [x] Verify branch diff and migration semantics
- [x] Open draft PR #253 with exact scope/validation state
- [x] Transactionally dry-run proposed schema on hosted Postgres and verify rollback leaves no durable objects
- [x] Full Supabase Database CI passes at implementation head
- [x] Manual exhaustive review completed; review/test findings resolved
- [x] Hosted migration remains unapplied and Quick Add save UI remains disabled

## 6. Quality Review

### Validation Run

Validated implementation head: `8f70cf4ad4aaf79c44aebe3493f0828211194455`.

Supabase Database CI run #23 / `34596216772` passed all gates:

```text
Start disposable local Postgres                 PASS
Replay baseline + capture lint baseline        PASS
Reinitialize disposable database               PASS
Replay all migrations from scratch             PASS
Verify complete migration ledger               PASS
Verify private helpers outside Data API        PASS
TNYX-67 existing SQL matrix                    PASS
TNYX-186 existing SQL matrix                   PASS
TNYX-194 manual MealLog SQL matrix             PASS
Real two-session concurrency test              PASS
Reject newly introduced DB lint errors         PASS
```

Hosted validation was rollback-only. The proposed schema/validator/grants/RLS were created inside transactions and exercised, then rollback was separately verified to leave both `public.meal_log_entries` and `private.is_valid_nutrition_snapshot_v1(jsonb)` absent.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| R1 | P3 | Resolved | Offset-only valid test fixture initially omitted its offset and therefore correctly tripped the time-context CHECK | pre-`88beaf32` | Fixture corrected before PR validation; hosted offset-only dry-run passed |
| R2 | P3 | Resolved | SQL matrix compared `information_schema.sql_identifier[]` directly with `text[]`, causing CI type-resolution failure | `88beaf32d639cbdc1c1e624c9bb97d2a733a70a8` | Cast `column_name::text`; exact-head CI run #23 passed all DB gates at `8f70cf4a` |

Manual re-review after R2 found no additional schema, RLS, grant, index, scope-leak, or future-serving conflict.

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/tnyx-194-manual-meal-log-persistence.md
.github/workflows/supabase-db-ci.yml
supabase/migrations/20260911114500_create_manual_meal_log_entries.sql
supabase/tests/database/tnyx_194_manual_meal_log_entries.test.sql
```

### Actual Behavior

- Defines one canonical future `public.meal_log_entries` owner, constrained to manual mode in V1.
- Stores provider-independent manual nutrition as canonical `NutritionSnapshot` JSON rather than duplicate macro columns.
- Separately stores chronology instant and durable user-intended local date plus required time context.
- Preserves durable meal-category ID and stable capture-source storage values.
- Enables RLS with explicit authenticated own-row SELECT/INSERT/UPDATE/DELETE policies using optimized auth evaluation.
- Explicitly removes `anon` table DML and narrows authenticated/service-role table grants.
- Adds a user/local-date/chronology index and canonical `updated_at` trigger.
- Adds a focused database matrix wired into complete migration replay CI.
- Does not create or persist serving/serving-size yet; those remain two distinct detailed-item facts for the later `MealLogItemSnapshot` slice.

### Known Limitations

Serving/serving-size, meal image, detailed items, idempotency, repository wiring, Quick Add lifecycle, and hosted migration apply remain intentionally deferred/gated.

### Final Status

`REVIEW` — implementation and validation are complete; draft PR #253 is ready for owner review. Production Supabase is unchanged by this branch.
