# TNYX-194 — N20A-5 Manual MealLog physical persistence foundation

**Status:** In progress
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
**Implementation ownership state:** Active
**Repository state last verified:** 2026-09-11
**Branch:** `tnyx/tnyx-194-n20a-5-manual-meallog-physical-persistence-foundation`
**HEAD SHA:** branch created from `c7cb15b63a9ef6502fb0aa71b9682d8265eb7f92`
**Observed working-tree state:** Connector-managed branch; local working tree unavailable
**Observed uncommitted/dirty files:** Not observable through GitHub connector
**PR / tracker:** TNYX-194 `In Progress`; no PR at implementation start
**Current implementation state:** Fresh audit complete; physical migration/tests being implemented
**Relevant execution surface:** `supabase/migrations`, `supabase/tests/database`, `.github/workflows/supabase-db-ci.yml`
**Validation completed at SHA:** Not yet
**Validation remaining:** migration replay, focused SQL matrix, lint diff, hosted advisor comparison after any eventual apply
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Add the bounded migration, focused DB test matrix, and explicit CI test step without enabling app save UI.

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
- Existing pattern to follow: `body_weight_logs` for UUID ownership/FK/index/trigger/RLS and `private.is_valid_meal_categories_config_v1(jsonb)` for hardened private JSON validation.
- Tests or validation already present: SQL transactional database tests under `supabase/tests/database`; DB CI replays the complete migration ledger from scratch.
- Supabase current docs re-verified: grants and RLS are separate controls; revoke client defaults before granting only intended operations; use `(select auth.uid())` in owner policies.
- Current Supabase breaking-change feed has no change that alters this table/RLS pattern.

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
| Serving + serving size | Deferred | Belong to detailed `MealLogItemSnapshot`, not manual/coarse persistence | Owner / TNYX-113 |
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
- [ ] Add `meal_log_entries` migration
- [ ] Add focused SQL test matrix
- [ ] Wire SQL matrix into Supabase DB CI
- [ ] Verify branch diff and migration semantics
- [ ] Open draft PR with exact scope/validation state
- [ ] Do not apply hosted migration or enable Quick Add UI as part of an unreviewed branch

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

No production behavior change until migration is reviewed/applied. This branch only defines the durable DB contract and its validation.

### Known Limitations

Serving/serving-size, meal image, detailed items, idempotency, repository wiring, and Quick Add lifecycle remain intentionally deferred.

### Final Status

`PARTIAL` — implementation in progress.
