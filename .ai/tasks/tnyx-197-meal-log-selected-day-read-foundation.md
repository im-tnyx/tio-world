# TNYX-197 — Manual MealLog selected-day read model foundation

**Status:** Ready
**Primary owner:** `apps/features/nutrition`
**Affected platforms:** Flutter mobile + Supabase-backed Nutrition repository

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner approved the bounded TNYX-57A audit outcome in chat on 2026-09-11 with `go`.
**Approved product/UI/data-shape boundaries:** Add selected-local-date MealLog repository/gateway reads and deterministic in-memory parity only. No visible UI and no Supabase table/column shape change.
**Explicit non-changes:** No Quick Add activation, Diary cards/sections, N14 display preferences, edit/delete, detailed items, daily summary/calendar decoration, schema/RLS/grant changes, `services/api`, ads, membership, or entitlements.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** Not assigned yet
**Review owner:** Not assigned yet
**Implementation ownership state:** Not started
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub `main` at `66f03c33f4fbffc0639333e1f1bd9ff075a0d4aa`; no overlapping open PR/branch found during readiness audit.
**Branch:** `tnyx/tnyx-197-n4a-manual-meallog-selected-day-read-model-foundation`
**HEAD SHA:** branch created from `66f03c33f4fbffc0639333e1f1bd9ff075a0d4aa`; planning commit pending at time this brief was authored.
**Observed working-tree state:** User reported post-merge local sync complete; GitHub connector cannot inspect the user's local filesystem.
**Observed uncommitted/dirty files:** None known; must be rechecked locally before implementation edits.
**PR / tracker:** Linear `TNYX-197`; no PR yet.
**Current implementation state:** Planning/readiness only; production source unchanged.
**Relevant execution surface:** `MealLogRepository`, `InMemoryMealLogRepository`, `SupabaseMealLogRepository` / `MealLogTableGateway`, focused Nutrition tests.
**Validation completed at SHA:** Readiness/source audit only; no implementation validation yet.
**Validation remaining:** focused package tests/analyze, then repository-required CI after implementation.
**Current blocker:** None. Implementation waits for the next explicit execution gate.
**Open review finding IDs:** None.
**Next exact action:** Reconstruct branch/local state, set TNYX-197 `In Progress`, then implement the bounded selected-day read contract and focused tests only.

## Global UI / Design-System Guardrail

This slice makes no production UI change. If implementation unexpectedly requires visible Flutter UI work, stop and return to Owner Approval before changing rendering. `apps/features/AGENTS.md`, `apps/core/lib/src/theme/README.md`, and the validated design-system governance were audited during readiness.

## 1. Discovery

### User Outcome

Provide the canonical durable read path that lets Nutrition retrieve actual manual MealLog history for one stored Diary local date before Quick Add is enabled.

### Success Criteria

- one repository call reads the authenticated user's actual logs for one `MealLogLocalDate`;
- grouping uses persisted `consumed_local_date`, never current-device timezone recomputation;
- results are deterministic newest-first;
- Supabase and in-memory implementations expose the same behavior;
- historical logs remain readable even when their Meal Category is archived;
- no second data owner/store is introduced.

### Scope

- extend `MealLogRepository` with selected-local-date list/read contract;
- extend the Supabase gateway with owner/date-scoped list query;
- add Supabase repository mapping through the existing strict row decoder;
- add deterministic in-memory parity;
- add focused repository/gateway tests;
- preserve existing RLS and physical schema unchanged.

### Non-Goals

- Diary controller/notifier or visible rendering;
- Meal Diary section/card aggregates;
- Quick Add submit wiring or `Log Meal` enablement;
- N14 show-time/note preference persistence or presentation;
- update/delete/concurrency/version work;
- detailed MealLog item persistence;
- schema, migration, RLS, grant or RPC changes;
- full TNYX-57 completion.

## 2. Codebase Exploration

### Verified Evidence

- `AGENTS.md` and `apps/features/AGENTS.md` require bounded slices, source-of-truth reconciliation, repository/business logic outside widgets, and owner approval for a new slice.
- TNYX-66 requires a fresh named readiness result before each Nutrition implementation slice; the 2026-09-11 audit produced the approved TNYX-57A boundary.
- `main` at audit: `66f03c33f4fbffc0639333e1f1bd9ff075a0d4aa` (TNYX-196 merged).
- `MealLogRepository` currently exposes `createManual()` and `readById()` only.
- `SupabaseMealLogRepository` already owns strict manual-row decoding, authenticated owner derivation, and the table gateway seam.
- `meal_log_entries` already has owner RLS plus index `(user_id, consumed_local_date, consumed_at DESC)`; no new schema is required.
- `MealCategoriesConfig.findById()` resolves stored active or archived category identities; reads must not require current active status.
- `MealDiaryPage` still renders a static empty-day state and Quick Add's `Log Meal` remains disabled; those surfaces are intentionally untouched here.
- TNYX-68 is Done at tracker level, but runtime currently exposes only the initial Meal Diary Settings shell; broader N14 display preferences are therefore outside this slice.
- `.ai/CURRENT.md` is stale onboarding-era context and is not runtime truth.
- `docs/DEVELOPMENT_SETUP.md`, `docs/MODULE_OWNERSHIP.md`, and parts of `docs/SUPABASE_STRATEGY.md` retain stale Supabase/backend wording. Root `AGENTS.md`, current README/architecture, and runtime source win; docs cleanup is not bundled here.

### Existing Pattern to Follow

- keep the public persistence boundary in `apps/features/nutrition/lib/src/domain/repositories/meal_log_repository.dart`;
- keep Supabase table details inside `MealLogTableGateway` / `SupabaseMealLogRepository`;
- reuse `_decodeManualRow` for every returned row rather than duplicating mapping logic;
- keep non-durable local/test behavior in `InMemoryMealLogRepository`;
- app shell remains composition only and needs no change for this repository-only slice.

### Tests or Validation Already Present

- focused Supabase MealLog repository tests cover row decoding/auth/create reconciliation;
- focused in-memory MealLog repository tests cover deterministic repository behavior;
- existing Meal Diary widget tests remain regression context but no UI behavior is expected to change.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Read key is `MealLogLocalDate` | Locked | Stored local date is canonical Diary grouping identity from TNYX-114 | Nutrition domain |
| Public API direction: `Future<List<MealLogEntry>> listByLocalDate(MealLogLocalDate localDate)` | Locked for implementation | Smallest repository-neutral selected-day read contract | TNYX-197 |
| Ordering: `consumedAt DESC`, stable row-id tie-breaker | Locked for implementation | Newest actual activity first; deterministic results for equal instants | TNYX-197 |
| Historical category activity is not revalidated | Locked | Archived categories must remain valid for historical reads | TNYX-67 / TNYX-195 contract |
| Schema/RLS change | Not required | Existing index and policies already support the read | Current Supabase schema |

## 4. Architecture Design

### Chosen Approach

Add one domain-level selected-date list method. The Supabase gateway will query `meal_log_entries` with both authenticated `user_id` and stored `consumed_local_date`, ordered by `consumed_at DESC` and a deterministic `id` tie-breaker. Every row is decoded through the existing strict canonical manual decoder. The in-memory repository filters and sorts its owned entries with the same semantics.

### Ownership and Data Flow

```text
future Diary controller/use case
        ↓
MealLogRepository.listByLocalDate(MealLogLocalDate)
        ↓
SupabaseMealLogRepository / InMemoryMealLogRepository
        ↓
MealLogTableGateway (Supabase only)
        ↓
meal_log_entries + existing owner RLS
```

This slice stops at the repository boundary; no Diary presentation consumer is added yet.

### Alternative Rejected

Querying the table directly from `MealDiaryPage` or a widget is rejected because it leaks database shape into presentation and creates a second persistence path. Recomputing local date from `consumedAt` is rejected because historical grouping must remain stable across timezone changes.

### Failure and Accessibility States

- signed-out Supabase reads fail closed before gateway data access;
- malformed/unsupported rows fail through the existing strict decoder rather than being silently skipped;
- empty date returns an empty list, not fabricated zero-history state elsewhere;
- accessibility is unaffected because no visible UI changes in this slice.

## 5. Implementation Plan

- [ ] Recheck branch/local status and exact base before source edits.
- [ ] Move Linear TNYX-197 to `In Progress` when source work starts.
- [ ] Add `listByLocalDate(MealLogLocalDate)` to `MealLogRepository`.
- [ ] Add owner/date-scoped list method to `MealLogTableGateway` and Supabase implementation.
- [ ] Map all rows through the existing canonical decoder.
- [ ] Add deterministic in-memory filtering/ordering parity.
- [ ] Add tests for empty/multiple dates, newest-first/tie behavior, signed-out failure, archived category historical read, owner/date query arguments, and malformed-row fail-closed behavior.
- [ ] Run focused analyze/tests, inspect base-to-head diff, then open Draft PR only after scope validation.

## 6. Quality Review

### Validation Run

```text
Not run yet — implementation has not started.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| — | — | — | No implementation review yet | — | — |

## 7. Final Handoff

### Changed Files

Planning setup only:

```text
.ai/tasks/tnyx-197-meal-log-selected-day-read-foundation.md
```

### Actual Behavior

No runtime behavior change yet.

### Known Limitations

- no Diary consumer/rendering;
- no Quick Add save wiring;
- no edit/delete lifecycle;
- broader N14 preferences remain separate.

### Final Status

`REVIEW` — readiness/planning prepared; implementation not started.
