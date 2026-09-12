# TNYX-203 — Manual MealLog optimistic revision & update foundation

**Status:** Review handoff
**Primary owner:** Nutrition + Supabase + shared MealLog contract
**Affected platforms:** Flutter shared/Nutrition domain + Supabase Postgres; no visible UI

## Owner Approval and Scope Boundary

**Approval status:** Approved
**Approval evidence:** Owner explicitly approved TNYX-203 on 2026-09-12 and approved exactly `public.meal_log_entries.revision bigint NOT NULL DEFAULT 1`.

Approved scope:

- add one durable `revision` column to `public.meal_log_entries`;
- expose canonical `MealLogEntry.revision`;
- add manual optimistic update contracts and repository implementations;
- database owns revision initialization/increment;
- stale edits cannot overwrite newer durable data;
- ambiguous mutation outcomes reconcile from canonical source truth.

Explicit non-changes:

- no Quick Add edit-mode UI or `Save Changes` wiring;
- no Diary card layout/overflow implementation;
- no delete implementation;
- no note UI;
- no detailed MealLog/item persistence;
- no offline mutation queue;
- no Daily Nutrition Summary/calendar work;
- no future detailed Meal Editor body.

Owner UX decisions remain recorded in TNYX-115/TNYX-58: manual/Quick Add logs later reopen in the same Quick Add editor in edit mode; Diary cards later use trailing nutrition alignment + reusable far-right overflow actions. Those UI decisions did not widen this slice.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** Inactive after validated implementation handoff
**Review owner:** Owner / next review agent
**Implementation ownership state:** Review handoff
**Branch:** `tnyx/tnyx-203-n20d-2-manual-meallog-optimistic-revision-update-foundation`
**Base:** `main` at `9eb22692a31dbad030d67ead77e5dd2bd67dd0de`
**Validated source/lineage SHA:** `de8f1e079413a8138f3f05a4056296327d3af7b1`
**PR:** #262 — `feat(nutrition): add optimistic MealLog update foundation`
**Tracker:** Linear TNYX-203 remains In Progress until review handoff sync, then should move to In Review; do not mark Done before merge.
**Working tree:** API-authored branch; no local working-tree claim.
**Current blocker:** None.
**Open review findings:** None after self-review fixes below.
**Next exact action:** fresh review/scope/CI read-back, then mark PR Ready for Review and TNYX-203 In Review. Merge still requires separate explicit owner authorization.

## Global UI / Design-System Guardrail

No production Flutter UI changed in this slice. TNYX-115/TNYX-58 own the later Quick Add edit surface and Diary-card action/layout refinements.

## 1. Discovery

### User Outcome

Prepare safe editing of existing manual/Quick Add MealLogs so a later UI can update the same `MealLogEntry.id` without silently overwriting a newer edit from another session/device.

### Success Criteria

- existing/new rows start with durable revision `1`;
- every successful durable update advances revision exactly once server-side;
- update requires `id + expectedRevision` and returns the same ID at the next revision;
- stale revision matches no update row and cannot overwrite newer data;
- ambiguous transport outcome reconciles by canonical read rather than blind replay;
- immutable identity/provenance remains preserved;
- retaining an archived category is allowed while moving to a different category requires an active destination;
- create/read/list/idempotency behavior remains compatible;
- no UI/delete scope leaks into this foundation.

## 2. Verified Architecture

Canonical flow:

```text
caller reads MealLogEntry(revision = N)
        ↓
ManualMealLogUpdate(id, expectedRevision = N, intended manual facts)
        ↓
Nutrition update capability
        ↓
owner-scoped conditional UPDATE
WHERE user_id + id + revision = N
        ↓
BEFORE UPDATE trigger owns revision = OLD.revision + 1
        ↓
canonical MealLogEntry(id unchanged, revision = N + 1)
```

`updated_at` remains audit/presentation metadata and is not the concurrency token.

Ownership:

- `apps/shared` owns provider-independent `MealLogEntry.revision`;
- Nutrition owns update input/errors/repository behavior;
- Supabase gateway owns row transport;
- Postgres owns revision initialization/increment and durable invariants;
- UI does not call Supabase directly.

## 3. Locked Decisions

| Decision | Result |
|---|---|
| Concurrency token | explicit `revision bigint`, not `updated_at` |
| Initial revision | server forces `1` on INSERT |
| Update revision | server forces `OLD.revision + 1` |
| Update identity | same `MealLogEntry.id`; never replacement insert |
| Manual mode | remains manual |
| Stale write | conflict; no overwrite |
| Ambiguous outcome | canonical read/reconcile; no blind replay |
| Archived category | retain same archived category allowed; moving requires active destination |
| V1 mutation availability | online-required; future UI preserves draft/retry state |

## 4. Implemented Contract

### Domain/shared

- `MealLogEntry.manual(...)` exposes `revision`, defaults to `1`, rejects `< 1`.
- `ManualMealLogUpdate` carries editable manual facts plus `id` and `expectedRevision`.
- deterministic errors distinguish not-found, stale conflict and outcome-unknown.
- update capability is additive so the established create/read/list repository surface remains compatible.

### In-memory owner

- updates the same entry ID;
- checks expected revision;
- increments exactly once;
- preserves immutable provenance;
- applies archived-category retention / active-destination rules;
- create retry after later edits returns current canonical entry rather than a stale cached entry.

### Supabase owner

- decodes/returns `revision` for create/read/list/update rows;
- update is conditional on authenticated owner + ID + expected revision;
- mutable payload excludes owner, mode, capture source, created timestamp and create mutation identity;
- zero-row update reconciles missing vs stale/current state;
- transport ambiguity reads canonical state and recognizes exact successful `N + 1` facts;
- same create mutation can reconcile an entry that was legitimately edited after creation without treating `revision > 1` itself as corruption.

### Database

Production migration lineage:

```text
20260912064635_add_meal_log_revision.sql
```

Migration adds:

```text
revision bigint NOT NULL DEFAULT 1
CHECK (revision >= 1)
```

`private.enforce_meal_log_revision()`:

- is `SECURITY INVOKER` with empty search path;
- is not directly executable by API roles;
- forces INSERT revision to `1`;
- preserves immutable `id`, `mode`, `capture_source`, `created_at`, `client_mutation_id` on UPDATE;
- forces UPDATE revision to `OLD.revision + 1`.

Owner reassignment remains governed by the existing RLS contract so established ownership failure semantics are preserved.

## 5. Implementation Checklist

- [x] Add production migration + database assertions for revision/check/server ownership.
- [x] Add `revision` to canonical `MealLogEntry`.
- [x] Add manual update input/capability/conflict/outcome contracts.
- [x] Map revision through Supabase create/read/list/update rows.
- [x] Implement deterministic in-memory optimistic updates.
- [x] Implement Supabase conditional update + canonical reconciliation.
- [x] Preserve create/read/list/idempotency compatibility.
- [x] Preserve archived category; require active destination when moving.
- [x] Add focused in-memory/Supabase/create-retry regressions.
- [x] Add TNYX-203 database matrix and wire it into Supabase DB CI.
- [x] Apply approved migration to live `tio-world` Supabase project.
- [x] Reconcile repository migration filename to actual production ledger version.
- [x] Verify live schema/RLS/trigger/function and advisor state.
- [x] Run exact source-head Flutter + Supabase DB CI.
- [x] Perform implementation self-review.

## 6. Validation

Validated source/lineage SHA:

```text
de8f1e079413a8138f3f05a4056296327d3af7b1
```

GitHub CI:

- Flutter CI #2433 — PASS
  - bootstrap — PASS
  - Flutter analyze — PASS
  - Dart analyze — PASS
  - Flutter tests — PASS
  - Dart tests — PASS
- Supabase Database CI #33 — PASS
  - baseline/replay — PASS
  - complete migration ledger — PASS
  - private-schema exposure check — PASS
  - existing B1/TNYX-186/TNYX-194 matrices — PASS
  - TNYX-203 revision matrix — PASS
  - real two-session concurrency test — PASS
  - DB lint delta — PASS

Earlier exact implementation head `1fa810ba51b9991caba714e64e668545e3acd91f` also passed Flutter CI #2429 and Supabase Database CI #29 before production-lineage reconciliation.

### Live Supabase verification

Project: `tio-world` (`oykupyiitspujzpwwvuj`).

- production ledger contains `20260912064635_add_meal_log_revision`;
- `revision` is `bigint`, `NOT NULL`, default `1`;
- all existing rows have non-null revision and migration backfill remains `1`;
- RLS remains enabled;
- exact four owner CRUD policies remain present;
- revision trigger and private helper exist;
- no TNYX-203/`meal_log_entries` security or performance advisor finding was introduced.

Existing advisor warnings concern unrelated pre-existing auth/RLS/index areas and were not widened into this task.

## 7. Review Findings and Resolution

| ID | Severity | Status | Finding | Resolution |
|---|---|---|---|---|
| T203-R1 | P1 safety | Resolved | client could otherwise attempt a forged initial revision | INSERT trigger now forces revision `1` |
| T203-R2 | Compatibility | Resolved | trigger-owned `user_id` rejection would change established RLS ownership failure semantics | ownership stays with existing RLS; trigger protects remaining immutable provenance |
| T203-R3 | Compatibility | Resolved | same create mutation lookup after a legitimate edit could reject revision `2+` / return stale in-memory data | reconciliation now returns current canonical edited row while retaining mutation-key conflict protection |
| T203-R4 | Governance | Resolved | Supabase apply generated production ledger `20260912064635` while repository draft filename was `20260912061500` | repository filename + SQL ledger assertions reconciled to production version and exact new head CI passed |

## 8. Changed Files

Final source scope is 14 files:

1. `.ai/tasks/tnyx-203-manual-meal-log-optimistic-revision-update.md`
2. `.github/workflows/supabase-db-ci.yml`
3. `apps/features/nutrition/lib/src/data/in_memory_meal_log_repository.dart`
4. `apps/features/nutrition/lib/src/data/repositories/supabase_meal_log_repository.dart`
5. `apps/features/nutrition/lib/src/domain/repositories/manual_meal_log_update_repository.dart`
6. `apps/features/nutrition/lib/src/domain/repositories/repositories.dart`
7. `apps/features/nutrition/test/data/in_memory_meal_log_update_repository_test.dart`
8. `apps/features/nutrition/test/data/meal_log_create_retry_after_update_test.dart`
9. `apps/features/nutrition/test/data/supabase_meal_log_repository_test.dart`
10. `apps/features/nutrition/test/data/supabase_meal_log_update_repository_test.dart`
11. `apps/shared/lib/src/nutrition/meal_log_entry.dart`
12. `supabase/migrations/20260912064635_add_meal_log_revision.sql`
13. `supabase/tests/database/tnyx_194_manual_meal_log_entries.test.sql`
14. `supabase/tests/database/tnyx_203_meal_log_revision.test.sql`

No production UI/card/editor file is in scope.

## 9. Known Later Work

TNYX-203 does not implement:

- Quick Add editor edit mode;
- Diary card tap/overflow/action popup/layout/padding changes;
- edit conflict presentation;
- delete;
- note-visibility UI;
- detailed Meal Editor/item persistence;
- broader derived-view invalidation;
- offline mutation queue.

These remain later bounded slices under TNYX-115/TNYX-58/TNYX-116 as appropriate.

## 10. Final Status

`REVIEW`
