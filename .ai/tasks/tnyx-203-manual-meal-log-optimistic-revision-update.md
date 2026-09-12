# TNYX-203 — Manual MealLog optimistic revision & update foundation

**Status:** In progress — review blocker resolution
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
- no additional Supabase table/column shape beyond the already-approved `revision` column.

Owner UX decisions remain under TNYX-115/TNYX-58/TNYX-204 and do not widen this backend slice.

## Active Handoff

**Planning owner:** ChatGPT
**Previous implementation owner:** ChatGPT implementation handoff at `64d3257eaae8aed56ef0915e941c7f07800aaa40`
**Receiving implementation owner:** ChatGPT, resumed after owner `Go` on 2026-09-12 to resolve final-review blockers
**Implementation ownership state:** Active
**Review owner:** Previous independent review published two blocking P2 findings on PR #262
**Branch:** `tnyx/tnyx-203-n20d-2-manual-meallog-optimistic-revision-update-foundation`
**Base:** `main` at `9eb22692a31dbad030d67ead77e5dd2bd67dd0de`
**Resume HEAD:** `64d3257eaae8aed56ef0915e941c7f07800aaa40`
**PR:** #262 — converted back to Draft while review fixes are active
**Tracker:** Linear TNYX-203 moved back to `In Progress`
**Working tree:** API-authored branch; no local working-tree claim
**Current blocker:** Two open P2 correctness findings, T203-R5 and T203-R6
**Next exact action:** fix both findings without widening schema/UI scope, add focused regressions, run exact-head Flutter + Supabase DB CI, then re-review before Ready transition

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
- ambiguous mutation outcomes reconcile from canonical source truth;
- TNYX-196 same-key/different-create-payload behavior remains fail closed.

## Implemented Foundation Before Review Re-entry

- `MealLogEntry.revision` added and validated;
- `ManualMealLogUpdate` plus not-found/conflict/outcome-unknown contracts added;
- in-memory optimistic update implementation added;
- Supabase conditional update implementation added;
- revision mapped through create/read/list/update rows;
- production migration `20260912064635_add_meal_log_revision.sql` applied and live-verified;
- database trigger forces INSERT revision `1`, UPDATE `OLD.revision + 1`, and protects immutable provenance;
- owner RLS/grants remain intact;
- focused Flutter and SQL regressions were added;
- validated source/lineage SHA `de8f1e079413a8138f3f05a4056296327d3af7b1` passed Flutter CI #2433 and Supabase DB CI #33;
- governance handoff head `64d3257e...` passed Flutter CI #2434 and Supabase DB CI #34.

Historical green CI is evidence for those exact SHAs only. Any review-fix HEAD requires fresh validation.

## Open Review Findings

| ID | Severity | Status | Observed SHA | Finding | Required resolution |
|---|---|---|---|---|---|
| T203-R5 | P2 | Open | `64d3257e...` | Cross-call retry after `MealLogUpdateOutcomeUnknown` can misclassify an already-committed exact `N+1` row as stale conflict because `updateManual()` checks revision mismatch before exact intended facts. | Before classifying `expectedRevision + 1` as stale, reconcile exact intended facts as success. Add regression: `OutcomeUnknown -> same input retry -> canonical N+1 success`. |
| T203-R6 | P2 | Open | `64d3257e...` | For create reconciliation at `revision > 1`, Supabase compares only `captureSource`, so reuse of the same `clientMutationId` for different meal facts with the same source can return an unrelated edited row as success, violating TNYX-196 fail-closed semantics. | Restore fail-closed payload equivalence without adding unapproved schema. Conservative reconciliation is allowed; add regression for revision `2+` + same mutation key + different create facts. |

PR inline review threads are the external review references for both findings. Do not resolve either thread until its fix and applicable validation are recorded.

## Review-Fix Design Decision

No new schema is authorized or required for T203-R6. Because an edited row no longer retains a durable copy of all original mutable create facts, the production-safe bounded behavior is conservative:

- create reconciliation succeeds only when the current canonical row still matches the incoming create facts;
- if the same mutation key points to a later-edited row whose current facts differ, fail closed with `MealLogCreateMutationConflict` rather than pretending the incoming create succeeded;
- in-memory behavior should mirror the same observable production rule rather than over-promise a capability production cannot prove durably.

For T203-R5:

- if the canonical row is exactly `expectedRevision + 1` and its editable facts exactly match the retry input, return it as reconciled success;
- otherwise preserve normal stale-conflict/outcome-unknown behavior;
- no blind second UPDATE is issued for an already-committed exact result.

## Validation Required After Fixes

- focused in-memory create-retry-after-edit regression;
- focused Supabase create reconciliation regression for same key + different facts after edit;
- focused Supabase update regression for `OutcomeUnknown -> same-input retry -> N+1 success`;
- existing update stale/conflict/immutable/category tests;
- full Flutter CI (`melos analyze`, `melos test` via workflow);
- full Supabase Database CI replay/matrices/lint;
- fresh PR scope/head/thread read-back.

No live Supabase migration/write is required for these review fixes because schema/trigger state is unchanged.

## Known Later Work

TNYX-203 still does not implement:

- Quick Add `Quick Edit` UI;
- Diary card overflow/actions/alignment/padding;
- edit-conflict presentation;
- delete;
- note visibility UI;
- detailed Meal Editor/item persistence;
- broader derived-view invalidation;
- offline mutation queue.

These remain later bounded slices under TNYX-115/TNYX-58/TNYX-116/TNYX-204.

## Exit Gate

`IN PROGRESS`

Return to review only after T203-R5 and T203-R6 are fixed, focused regressions pass, exact-head Flutter + Supabase DB CI are green, review threads are reconciled, and the task brief is refreshed. Merge still requires separate explicit owner authorization.
