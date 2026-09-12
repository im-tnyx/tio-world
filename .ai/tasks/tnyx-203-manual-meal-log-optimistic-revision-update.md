# TNYX-203 — Manual MealLog optimistic revision & update foundation

**Status:** In progress
**Primary owner:** Nutrition + Supabase + shared MealLog contract
**Affected platforms:** Flutter shared/Nutrition domain + Supabase Postgres; no visible UI

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + Supabase table/column shape change
**Approval status:** Approved
**Approval evidence:** Owner explicitly approved TNYX-203 on 2026-09-12 and approved exactly `public.meal_log_entries.revision bigint NOT NULL DEFAULT 1`.
**Approved product/UI/data-shape boundaries:** Add one `revision` column to `public.meal_log_entries`; expose canonical MealLog revision; add manual optimistic update contract/implementations; server increments revision; stale edits cannot overwrite newer data; no visible UI.
**Explicit non-changes:** No Quick Add edit-mode UI, card-tap navigation, `Save Changes` wiring, delete, note UI, detailed MealLog/item persistence, offline mutation queue, Daily Nutrition Summary/calendar work, second MealLog table, or broader Meal Editor body.

Owner clarified the later UX boundary: Quick Add/manual logs reopen in the same Quick Add editor in edit mode. Detailed/source-based flows may use a different future Meal Editor body; only the footer/action-area pattern is currently intended for reuse there. That UI is not part of TNYX-203.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT (current resumed session)
**Review owner:** Unassigned until implementation handoff
**Implementation ownership state:** Active
**Ownership transition:** ChatGPT (interrupted implementation session) → ChatGPT (current resumed session)
**Repository state last verified:** 2026-09-12; remote `main` remains exact SHA `9eb22692a31dbad030d67ead77e5dd2bd67dd0de`; TNYX-203 branch is ahead only and GitHub shows zero open PRs.
**Branch:** `tnyx/tnyx-203-n20d-2-manual-meallog-optimistic-revision-update-foundation`
**HEAD SHA:** `c768aaeb5f0716a6d89b0f6d1eddc8aaa24fb464` before this handoff reconciliation commit.
**Observed working-tree state:** API-authored branch; no local working tree is claimed.
**Observed uncommitted/dirty files:** Not applicable to API-authored branch.
**PR / tracker:** Linear TNYX-203 = In Progress; no PR yet.
**Current implementation state:** Partial implementation exists. `ManualMealLogUpdate` + update error/capability contracts are added/exported and canonical `MealLogEntry` exposes validated `revision` with default `1`. Migration, repository implementations, row mapping, database/live migration, and validation remain incomplete.
**Relevant execution surface:** `apps/shared` MealLog aggregate; `apps/features/nutrition` repository contracts/adapters/tests; `supabase/migrations` + database tests.
**Validation completed at SHA:** None yet for TNYX-203.
**Validation remaining:** focused Dart/Flutter tests, full Flutter CI, migration/RLS/security verification, live schema check after approved migration application, security/performance advisors.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Implement the approved migration and deterministic in-memory/Supabase update owners from the verified partial contracts, then add focused tests before applying the migration live.

## Global UI / Design-System Guardrail

No production Flutter UI change is authorized or planned in this slice. If implementation exposes a UI need, record it as a follow-up and preserve current rendering.

## 1. Discovery

### User Outcome

Prepare safe editing of existing manual/Quick Add MealLogs so a later edit-mode UI can update the same `MealLogEntry.id` without silently overwriting a newer edit from another session/device.

### Success Criteria

- existing rows have durable revision `1` after migration;
- every successful manual MealLog update increments revision exactly once server-side;
- update requires `id + expectedRevision` and returns same `id` with next revision;
- stale revision never overwrites a newer durable row;
- ambiguous transport outcome is reconciled by canonical read rather than blind retry;
- immutable facts remain preserved (`userId`, `id`, `mode`, `captureSource`, `createdAt`);
- retaining an existing archived category is allowed, but moving to a different category requires an active destination;
- current create/read/list behavior remains compatible;
- no UI or delete scope leaks into this foundation.

### Scope

- `revision bigint NOT NULL DEFAULT 1` with `revision >= 1` invariant;
- server-owned revision increment on update;
- canonical `MealLogEntry.revision` mapping;
- `ManualMealLogUpdate`, deterministic conflict/outcome errors, `MealLogRepository.updateManual`;
- Supabase gateway/repository and in-memory implementations;
- focused shared/repository/database tests;
- migration/RLS/security verification.

### Non-Goals

See approved explicit non-changes above.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/workflow.md`, `.ai/tasks/README.md`, `.ai/tasks/TEMPLATE.md`, `docs/ARCHITECTURE.md`, `docs/MODULE_OWNERSHIP.md`, `docs/SUPABASE_STRATEGY.md`, current `MealLogEntry`, `MealLogRepository`, in-memory/Supabase adapters, current MealLog migrations, live table columns/policies/trigger, TNYX-115/TNYX-116/TNYX-203 tracker state.
- Existing pattern to follow: Nutrition repository owns domain mutation semantics; shared owns provider-independent aggregate; Supabase gateway owns row transport; app/UI does not call database directly.
- Tests or validation already present: create idempotency/reconciliation repository tests and database RLS tests provide the nearest patterns.
- Current live table has own-row SELECT/UPDATE RLS and authenticated UPDATE grant; update therefore already has the required SELECT-policy prerequisite.
- Current `updated_at` trigger uses transaction `now()` and remains audit metadata; no current revision/version field exists.
- Supabase migration history currently ends at `20260911143309_add_meal_log_client_mutation_id`.
- Current Supabase docs continue to require SELECT policy for UPDATE and support row-level BEFORE UPDATE triggers; no relevant breaking change was identified in the current documentation pass.

Known stale doc: `docs/MODULE_OWNERSHIP.md` still labels Supabase as future and names old `backend/*` paths; root `AGENTS.md` and `docs/ARCHITECTURE.md` are newer/current and win. TNYX-203 does not widen backend scope.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Use explicit `revision bigint` instead of `updated_at` as concurrency token | Approved | deterministic integer stale-write identity; keep timestamps for audit/presentation | Owner |
| Initial revision | Approved | existing/new rows start at `1` | Owner |
| Revision increment ownership | Locked | server/database owns `+1`; client supplies only `expectedRevision` | Engineering inside approved scope |
| Update identity | Locked | update same `MealLogEntry.id`; no replacement insert | TNYX-115/TNYX-203 |
| Manual-mode preservation | Locked | no silent detailed-mode conversion | TNYX-115 |
| V1 offline behavior | Locked | online-required final mutation; preserve caller draft at future UI layer | TNYX-116/TNYX-196 |
| Archived category behavior | Locked | unchanged retained category allowed; moving requires active destination | TNYX-203 |

## 4. Architecture Design

### Chosen Approach

Use optimistic concurrency on the canonical row:

```text
caller reads MealLogEntry(revision = N)
        ↓
ManualMealLogUpdate(id, expectedRevision = N, intended manual facts)
        ↓
Nutrition MealLogRepository.updateManual
        ↓
owner-scoped conditional Supabase UPDATE where id + user_id + revision = N
        ↓
BEFORE UPDATE trigger sets revision = OLD.revision + 1
        ↓
canonical updated MealLogEntry(revision = N + 1)
```

If no conditional row matches, read the canonical row. Missing/not-visible target is distinct from stale revision. If a transport failure leaves outcome ambiguous, read the canonical row: exact intended facts at `N + 1` reconcile success; otherwise return conflict/unknown rather than blindly replaying an overwrite.

### Ownership and Data Flow

```text
future Quick Add edit controller
  -> MealLogRepository.updateManual
  -> SupabaseMealLogRepository / InMemoryMealLogRepository
  -> public.meal_log_entries
```

No UI is changed in this task.

### Alternative Rejected

Use `updated_at` as the optimistic token: rejected because it couples concurrency identity to timestamp precision/serialization/transaction-time semantics and mixes audit metadata with version identity.

Client-provided next revision: rejected because a client must not be able to forge the durable version transition.

### Failure and Accessibility States

No visible accessibility state is introduced. Repository failures distinguish invalid input, missing/not-visible row, stale conflict, and ambiguous outcome. Future UI owns user-facing conflict/retry presentation.

## 5. Implementation Plan

- [ ] Add migration + database assertions for `revision`, check, and server-owned increment.
- [x] Add `revision` to canonical `MealLogEntry` construction contract.
- [x] Add `ManualMealLogUpdate` and update outcome/conflict contracts.
- [ ] Map `revision` through Supabase rows and focused shared/repository tests.
- [ ] Implement deterministic in-memory update semantics.
- [ ] Extend Supabase gateway for conditional update and canonical reconciliation.
- [ ] Preserve create/read/list compatibility and category retention semantics.
- [ ] Add focused repository/database regressions for success, stale conflict, missing target, archived-category retention, active destination, ambiguous reconciliation, immutable facts, and revision increments.
- [ ] Apply approved migration to live project and verify schema/RLS/trigger plus security/performance advisors.
- [ ] Run focused/full Flutter/Dart validation and final review.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | — | — | No review pass yet | — | — |

## 7. Final Handoff

### Changed Files

Partial only; final list not yet frozen.

### Actual Behavior

Partial contract foundation only; no durable update path is complete yet.

### Known Limitations

Quick Add edit-mode UI, delete, detailed Meal Editor, broader derived-view invalidation and offline queue remain later slices.

### Final Status

`PARTIAL`
