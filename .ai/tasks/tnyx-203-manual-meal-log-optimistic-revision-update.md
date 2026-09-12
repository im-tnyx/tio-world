# TNYX-203 — Manual MealLog optimistic revision & update foundation

**Status:** Review handoff
**Primary owner:** Nutrition + Supabase + shared MealLog contract
**Affected platforms:** Flutter shared/Nutrition domain + Supabase Postgres; no visible UI

## Owner Approval and Scope Boundary

**Approval status:** Approved
**Approval evidence:** Owner explicitly approved TNYX-203 on 2026-09-12 and approved exactly `public.meal_log_entries.revision bigint NOT NULL DEFAULT 1`.

Approved scope:

- one durable `revision` column on `public.meal_log_entries`;
- canonical `MealLogEntry.revision`;
- manual optimistic update contracts and repository implementations;
- server-owned revision initialization/increment;
- stale-write protection;
- ambiguous update outcome reconciliation;
- create-idempotency compatibility while preserving TNYX-196 fail-closed semantics.

Explicit non-changes:

- no Quick Add edit-mode UI or `Save Changes` wiring;
- no Diary card layout/overflow implementation;
- no delete implementation;
- no note UI;
- no detailed MealLog/item persistence;
- no offline mutation queue;
- no Daily Nutrition Summary/calendar work;
- no future detailed Meal Editor body;
- no additional Supabase table/column shape beyond the approved `revision` column.

Owner UX decisions remain under TNYX-115/TNYX-58/TNYX-204 and did not widen this backend slice.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** Inactive after validated review-fix handoff
**Review owner:** Owner / next review agent
**Implementation ownership state:** Review handoff
**Branch:** `tnyx/tnyx-203-n20d-2-manual-meallog-optimistic-revision-update-foundation`
**Base:** `main` at `9eb22692a31dbad030d67ead77e5dd2bd67dd0de`
**Validated source/review-fix SHA:** `2c0852a4fe210cf95c33db84d492d89fba211d12`
**PR:** #262 — remains Draft until this governance-only handoff head receives exact-head CI
**Tracker:** Linear TNYX-203 remains `In Progress` until Ready-for-Review handoff is re-established
**Working tree:** API-authored branch; no local working-tree claim
**Current blocker:** No source blocker; exact governance-handoff-head CI remains required
**Open review findings:** None; T203-R5 and T203-R6 are resolved and their GitHub threads are resolved
**Next exact action:** verify exact handoff-head Flutter + Supabase DB CI, fresh scope/thread read-back, then return PR to Ready for Review and TNYX-203 to In Review. Merge still requires separate explicit owner authorization.

## Locked Architecture

```text
caller reads MealLogEntry(revision = N)
        ↓
ManualMealLogUpdate(id, expectedRevision = N, intended manual facts)
        ↓
owner-scoped conditional UPDATE
WHERE user_id + id + revision = N
        ↓
BEFORE UPDATE trigger owns revision = OLD.revision + 1
        ↓
canonical same-ID MealLogEntry(revision = N + 1)
```

`updated_at` remains audit/presentation metadata, not the concurrency token.

Rules:

- new rows start at revision `1`;
- clients cannot choose the durable next revision;
- every successful row update increments exactly once;
- a stale edit never overwrites newer durable state;
- retaining the same archived Meal Category is allowed; moving requires an active destination;
- ambiguous update outcomes reconcile from canonical source truth;
- TNYX-196 same-key/different-create-payload behavior remains fail closed.

## Implemented Contract

### Domain/shared

- `MealLogEntry.manual(...)` exposes durable `revision`, defaults to `1`, and rejects `< 1`.
- `ManualMealLogUpdate` carries editable manual facts plus `id` and `expectedRevision`.
- deterministic update failures distinguish not-found, stale conflict, and outcome-unknown.
- update capability is additive so existing create/read/list repository consumers remain source-compatible.

### In-memory owner

- updates the same entry ID;
- requires expected revision and advances exactly once;
- preserves immutable provenance;
- keeps same archived category valid while requiring an active destination for category moves;
- manual-create retry remains fail closed for reused mutation IDs;
- once a canonical row has been edited (`revision > 1`), create reconciliation fails closed because production cannot durably prove the original mutable create payload without another approved immutable fingerprint.

### Supabase owner

- maps `revision` through create/read/list/update rows;
- conditional durable update uses authenticated owner + row ID + expected revision;
- mutable update payload excludes owner, mode, capture source, created timestamp, create mutation identity, and revision;
- zero-row/ambiguous outcomes reconcile via canonical read;
- a cross-call retry recognizes exact canonical `expectedRevision + 1` intended facts before stale-conflict classification, so a committed response-loss edit can converge without a second UPDATE;
- create reconciliation at revision `1` requires complete create-fact equality;
- create reconciliation at revision `2+` always fails closed with `MealLogCreateMutationConflict` because current edited facts are insufficient proof of the original create payload.

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

Ownership remains governed by the established RLS policy contract.

## Review Findings and Resolution

| ID | Severity | Status | Observed SHA | Finding | Resolution evidence |
|---|---|---|---|---|---|
| T203-R1 | P1 safety | Resolved | earlier implementation | client could otherwise attempt a forged initial revision | INSERT trigger forces `1`; DB matrix PASS |
| T203-R2 | Compatibility | Resolved | earlier implementation | trigger-owned `user_id` rejection would alter established RLS failure semantics | ownership remains with RLS; immutable provenance protection stays in revision trigger |
| T203-R3 | Compatibility | Superseded by stricter R6 resolution | earlier implementation | create retry after a later edit needed explicit behavior | final reviewed rule is conservative revision-2+ fail-closed; see T203-R6 |
| T203-R4 | Governance | Resolved | earlier implementation | repository migration filename differed from live Supabase-assigned ledger version | repository filename/assertions reconciled to `20260912064635` and replay CI passed |
| T203-R5 | P2 correctness | Resolved | `64d3257e...` | same-input retry after `MealLogUpdateOutcomeUnknown` could report false stale conflict after the first call durably committed N+1 | source `2c0852a4...` checks exact N+1 intended facts before stale classification; regression proves no second write; GitHub thread resolved |
| T203-R6 | P2 correctness | Resolved | `64d3257e...` | revision-2+ create reconciliation could accept a reused mutation key because original create facts are no longer durably provable | source `2c0852a4...` makes every revision-2+ create reconciliation fail closed with `MealLogCreateMutationConflict`; in-memory parity + focused regression; GitHub thread resolved |

No P1/P2/P3 blocker remains after the review-fix pass at validated source SHA `2c0852a4...`.

## Validation

### Validated review-fix source SHA

```text
2c0852a4fe210cf95c33db84d492d89fba211d12
```

GitHub CI:

- Flutter CI #2443 — PASS
  - bootstrap — PASS
  - Flutter analyze — PASS
  - Dart analyze — PASS
  - Flutter tests — PASS
  - Dart tests — PASS
- Supabase Database CI #43 — PASS
  - baseline/replay — PASS
  - complete migration ledger — PASS
  - private-schema exposure check — PASS
  - existing B1/TNYX-186/TNYX-194 matrices — PASS
  - TNYX-203 revision matrix — PASS
  - real two-session concurrency test — PASS
  - DB lint delta — PASS

Focused regressions now include:

- `OutcomeUnknown -> same-input retry -> canonical N+1 success` with only one update call;
- edited-row create retry fails closed in-memory;
- revision-2+ Supabase create reconciliation fails closed when facts differ;
- revision-2+ Supabase create reconciliation still fails closed when current edited facts happen to exactly match the incoming create.

### Historical evidence

- source/lineage SHA `de8f1e079413a8138f3f05a4056296327d3af7b1`: Flutter #2433 PASS, Supabase DB #33 PASS;
- prior governance handoff `64d3257e...`: Flutter #2434 PASS, Supabase DB #34 PASS.

### Live Supabase verification

Project: `tio-world` (`oykupyiitspujzpwwvuj`).

Already verified before final review:

- production ledger contains `20260912064635_add_meal_log_revision`;
- `revision` is `bigint NOT NULL DEFAULT 1`;
- existing rows were backfilled to revision `1`;
- RLS remains enabled;
- exact four owner CRUD policies remain present;
- revision trigger and private helper exist;
- no TNYX-203/`meal_log_entries` security or performance advisor finding was introduced.

The final-review fixes changed no schema, migration, trigger, RLS, grants, or live database state.

## Final Scope

PR #262 remains bounded to 14 files and contains no production UI/card/editor file. The final review-fix delta from the old handoff `64d3257e...` touched only:

1. this task brief;
2. `apps/features/nutrition/lib/src/data/in_memory_meal_log_repository.dart`;
3. `apps/features/nutrition/lib/src/data/repositories/supabase_meal_log_repository.dart`;
4. `apps/features/nutrition/test/data/meal_log_create_retry_after_update_test.dart`;
5. `apps/features/nutrition/test/data/supabase_meal_log_update_repository_test.dart`.

No migration/UI widening occurred during blocker resolution.

## Known Later Work

TNYX-203 does not implement:

- Quick Add `Quick Edit` UI;
- Diary card overflow/actions/alignment/padding;
- edit-conflict presentation;
- delete;
- note-visibility UI;
- detailed Meal Editor/item persistence;
- broader derived-view invalidation;
- offline mutation queue.

These remain later bounded slices under TNYX-115/TNYX-58/TNYX-116/TNYX-204.

## Final Status

`REVIEW`

Validated source is clean and both final-review P2 findings are resolved. This governance-only handoff commit still requires exact-head CI before PR #262 returns to Ready for Review and TNYX-203 returns to In Review. Merge requires separate explicit owner authorization.
