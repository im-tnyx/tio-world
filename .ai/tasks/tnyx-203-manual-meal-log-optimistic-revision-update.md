# TNYX-203 — Manual MealLog optimistic revision & update foundation

## Status

`REVIEW`

## Approval status

Approved by owner on 2026-09-12 for this bounded backend/data foundation, including exactly:

```text
public.meal_log_entries.revision
bigint NOT NULL DEFAULT 1
```

No UI edit/delete work is included.

## Outcome

Provide production-safe optimistic manual MealLog updates before any edit-mode UI is activated:

- one durable monotonic `revision` concurrency identity;
- same-ID manual updates using `expectedRevision`;
- stale writes never overwrite newer rows;
- ambiguous transport outcomes reconcile without blind overwrite;
- existing manual-mode identity/provenance stays immutable;
- no schema widening beyond the approved revision column.

## Current repository anchor

- Branch: `tnyx/tnyx-203-n20d-2-manual-meallog-optimistic-revision-update-foundation`
- Base `main`: `9eb22692a31dbad030d67ead77e5dd2bd67dd0de`
- Validated source/review-fix SHA: `2c0852a4fe210cf95c33db84d492d89fba211d12`
- Current governance handoff HEAD: `27f789584dc222a37090e7e0460fd3cb660d6d90`
- PR: #262
- Ahead / behind: `34 / 0`
- Changed files: 14
- No production UI/card/editor files are in scope.

## Implemented

### Canonical revision

- `MealLogEntry.revision` is canonical and validated with initial/default revision `1`.
- Supabase row mapping reads durable revision.
- Existing create/read/list behavior remains source-compatible.

### Manual update contract

`ManualMealLogUpdate` carries:

- `id`
- `expectedRevision`
- `mealCategoryId`
- `mealName`
- `note`
- `consumedAt`
- `consumedLocalDate`
- timezone ID and/or UTC offset
- manual nutrition snapshot

Immutable/preserved facts:

- authenticated owner / `userId`
- `id`
- `mode = manual`
- `captureSource`
- `createdAt`
- create mutation identity

### Update semantics

- owner + ID + expected revision conditional update;
- successful durable update returns same ID and `revision + 1`;
- stale revision surfaces `MealLogUpdateConflict`;
- missing/not-visible row surfaces `MealLogUpdateNotFound`;
- ambiguous update response reconciles from canonical state;
- if a prior call committed `N+1` but response/reconciliation was lost, a same-input retry recognizes exact canonical `N+1` facts as success before stale-conflict classification and issues no second update;
- unrelated archived category may be retained; moving categories requires currently active destination.

### Create-idempotency compatibility after edits

TNYX-196 requires one mutation key to identify one logical create payload.

A row at `revision 2+` no longer durably proves every mutable original create fact. Without a separately approved immutable create fingerprint, create reconciliation for any edited row therefore fails closed with `MealLogCreateMutationConflict`, even if current edited facts happen to equal a later incoming create. Revision `1` reconciliation still requires full create-fact equality.

In-memory behavior mirrors the production observable rule.

### Database

Production migration lineage:

```text
20260912064635_add_meal_log_revision.sql
```

Live `tio-world` Supabase verification already completed:

- `revision bigint NOT NULL DEFAULT 1`;
- existing rows backfilled/non-null at revision `1`;
- INSERT server-forces revision `1`;
- UPDATE increments exactly once from `OLD.revision + 1`;
- revision must remain >= 1;
- immutable identity/provenance guards present;
- RLS remains enabled with the same four owner CRUD policies;
- no new TNYX-203 / `meal_log_entries` security or performance advisor finding.

The final-review fixes did not change schema, migration, RLS, trigger, or live database state.

## Final review findings

### T203-R5 — P2 cross-call ambiguous-update recovery

`Resolved`

Observed at handoff SHA `64d3257eaae8aed56ef0915e941c7f07800aaa40`.

Fix at validated source SHA `2c0852a4fe210cf95c33db84d492d89fba211d12`:

- exact canonical `expectedRevision + 1` + exact intended editable facts reconcile as success before stale-conflict classification;
- regression covers `OutcomeUnknown -> same input retry -> canonical N+1 success`;
- asserts only one durable update call.

GitHub review thread resolved with source + CI evidence.

### T203-R6 — P2 edited-row create-key fail-closed safety

`Resolved`

Observed at handoff SHA `64d3257eaae8aed56ef0915e941c7f07800aaa40`.

Fix at validated source SHA `2c0852a4fe210cf95c33db84d492d89fba211d12`:

- revision `2+` create reconciliation always fails closed because original mutable create payload cannot be proven from the edited row;
- no new fingerprint/schema column introduced;
- revision `1` still requires complete create-fact equality;
- in-memory matches production semantics;
- regression covers revision `2+` where current edited facts even match a later incoming create and still requires conflict.

GitHub review thread resolved with source + CI evidence.

## Validation

Validated review-fix source SHA `2c0852a4fe210cf95c33db84d492d89fba211d12`:

- Flutter CI #2443 — PASS
  - bootstrap
  - Flutter analyze
  - Dart analyze
  - Flutter tests
  - Dart tests
- Supabase Database CI #43 — PASS
  - full migration replay
  - migration ledger
  - existing SQL matrices
  - TNYX-203 revision matrix
  - real two-session concurrency test
  - lint delta

Current governance handoff HEAD `27f789584dc222a37090e7e0460fd3cb660d6d90`:

- Flutter CI #2444 — PASS
- Supabase Database CI #44 — PASS
- branch compare to `main`: 34 ahead / 0 behind
- both T203-R5 / T203-R6 review threads resolved
- no new unresolved review finding observed at handoff.

Historical validation remains recorded in PR #262 for earlier source/lineage heads.

## Explicit non-goals

- no Meal Diary card navigation or visual changes;
- no `Quick Edit` / Quick Add edit-mode UI;
- no `Save Changes` CTA wiring;
- no overflow menu implementation;
- no card spacing/alignment change;
- no note UI/preference change;
- no delete method/UI;
- no detailed MealLog/items persistence;
- no offline mutation queue;
- no Daily Nutrition Summary/calendar progress;
- no second MealLog table.

Later owner-approved Meal Diary card + `Quick Edit` work remains TNYX-204 / TNYX-115 / TNYX-58.

## Active Handoff

- Previous Implementation owner: review-fix implementation session
- Current state: implementation complete; final review blockers resolved; exact source and governance-head CI green.
- Implementation ownership: `Handoff pending / REVIEW`
- Validated source SHA: `2c0852a4fe210cf95c33db84d492d89fba211d12`
- Current governance HEAD: `27f789584dc222a37090e7e0460fd3cb660d6d90`
- Open review findings: none known; T203-R5 and T203-R6 resolved.
- Blocker: none for review handoff.
- Next exact action: mark PR #262 Ready for Review and tracker In Review after fresh read-back; do not merge without separate explicit owner authorization.
- Live production migration: already applied and verified; no further production DB write required for this slice.

## Readiness result

`READY`
