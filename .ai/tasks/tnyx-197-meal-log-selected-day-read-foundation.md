# TNYX-197 — Manual MealLog selected-day read model foundation

**Status:** In progress — source implementation validated; Draft PR final handoff review remains  
**Primary owner:** `apps/features/nutrition`  
**Affected platforms:** Flutter mobile + Supabase-backed Nutrition repository

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice  
**Approval status:** Approved  
**Approval evidence:** Owner approved the bounded TNYX-57A audit outcome on 2026-09-11 with `go`.  
**Approved product/UI/data-shape boundaries:** Selected-local-date MealLog repository/gateway reads plus deterministic in-memory parity only. No visible UI and no Supabase table/column shape change.  
**Explicit non-changes:** No Quick Add activation, Diary cards/sections/controller, N14 display preferences, edit/delete, detailed items, daily summary/calendar decoration, schema/RLS/grant changes, `services/api`, ads, membership, or entitlements.

## Active Handoff

**Planning owner:** ChatGPT  
**Implementation owner:** ChatGPT  
**Review owner:** ChatGPT  
**Implementation ownership state:** Complete  
**Ownership transition:** Not applicable  
**Repository state last verified:** Base `main` = `66f03c33f4fbffc0639333e1f1bd9ff075a0d4aa`; source-validation head = `7bba235a10d13b810566f3de1f80c53dfb38f59b`; base is exact merge base; source branch was 6 ahead / 0 behind with six TNYX-197-owned files.  
**Branch:** `tnyx/tnyx-197-n4a-manual-meallog-selected-day-read-model-foundation`  
**HEAD SHA:** `7bba235a10d13b810566f3de1f80c53dfb38f59b` is the validated source head immediately before this docs-only handoff reconciliation commit.  
**Observed working-tree state:** GitHub/API-based execution; parent-to-head ancestry, commit count and complete changed-file list were inspected through repository API per `docs/PUSH_TEMPLATE.md`.  
**Observed uncommitted/dirty files:** Not applicable to connector-backed branch writes; no unrelated committed files found.  
**PR / tracker:** Draft PR #256; Linear TNYX-197 `In Progress`.  
**Current implementation state:** Repository contract, Supabase gateway/adapter, in-memory parity and focused tests implemented. No UI/schema change.  
**Relevant execution surface:** `MealLogRepository`, `InMemoryMealLogRepository`, `MealLogTableGateway`, `SupabaseMealLogRepository`, focused Nutrition repository tests.  
**Validation completed at SHA:** `7bba235a10d13b810566f3de1f80c53dfb38f59b` — Flutter CI #2381 / run `34621964823` / job `103337867111`: bootstrap ✅, Flutter analyze ✅, Dart analyze ✅, Flutter tests ✅, Dart tests ✅.  
**Validation remaining:** Current PR head after this docs-only reconciliation must be checked; final PR scope/review state then reconciled before Ready-for-review.  
**Current blocker:** None.  
**Open review finding IDs:** None.  
**Next exact action:** Verify docs-only head delta and current-head CI; then reconcile PR body + Linear to `In Review` and mark PR Ready only if review stays clean.

## Global UI / Design-System Guardrail

No production UI was changed. `apps/features/AGENTS.md` and the core design-system README were audited during readiness; no visible implementation was needed.

## 1. Discovery

### User Outcome

Provide the canonical durable read path that lets Nutrition retrieve actual manual MealLog history for one stored Diary local date before Quick Add is enabled.

### Success Criteria

- one repository call reads the authenticated user's actual logs for one `MealLogLocalDate`;
- grouping uses persisted `consumed_local_date`, never current-device timezone recomputation;
- results are deterministic newest-first;
- Supabase and in-memory implementations expose the same behavior;
- historical logs remain readable when their Meal Category is archived;
- no second MealLog owner/store is introduced.

### Scope

- `MealLogRepository.listByLocalDate(MealLogLocalDate)`;
- owner/date-scoped Supabase gateway query;
- strict canonical row decoding through the existing decoder;
- deterministic in-memory filtering/ordering parity;
- focused read-contract tests.

### Non-Goals

Diary UI/controller/cards, Quick Add submit wiring, N14 preferences, update/delete/concurrency, detailed items, Supabase schema/RLS/grants/RPC, full TNYX-57 completion.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md`, `apps/features/AGENTS.md`, TNYX-66, TNYX-197, workflow/task governance and push/PR templates were audited.
- Existing `meal_log_entries` owner RLS and `(user_id, consumed_local_date, consumed_at DESC)` index already support this read; no migration is required.
- `MealLogRepository` previously exposed only `createManual()` and `readById()`.
- Supabase adapter already owned authenticated identity and strict row decoding.
- Quick Add remains disabled and Meal Diary still has no durable list consumer; both remain intentionally untouched.
- `.ai/CURRENT.md` and parts of `docs/DEVELOPMENT_SETUP.md`, `docs/MODULE_OWNERSHIP.md`, and `docs/SUPABASE_STRATEGY.md` contain older context; runtime/root architecture remains authoritative. This slice does not bundle broad docs cleanup.

### Existing Pattern Followed

Domain repository contract → feature data adapters → injectable table gateway; no database shape in presentation and no app-shell business logic.

### Validation Baseline

Existing MealLog repository tests were extended rather than creating a parallel test/store path.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Read key is `MealLogLocalDate` | Locked | Stored local date is durable Diary grouping identity. |
| API is `Future<List<MealLogEntry>> listByLocalDate(...)` | Implemented | Smallest repository-neutral selected-day contract. |
| Order is `consumedAt DESC`, then opaque row id ascending | Implemented | Newest activity first plus deterministic ties. |
| Historical category activity is not revalidated | Implemented | Archived categories remain valid historical identity. |
| Schema/RLS change | Not required | Existing physical shape/policies/index are sufficient. |

## 4. Architecture Design

### Chosen Approach

`SupabaseMealLogTableGateway.listRowsByLocalDate` filters by authenticated `user_id` plus canonical `consumed_local_date`, requests `consumed_at DESC` and `id ASC`, and returns existing row shape. `SupabaseMealLogRepository` decodes every row through `_decodeManualRow` and enforces the same deterministic ordering at the repository boundary. `InMemoryMealLogRepository` filters persisted entry local-date identity and applies the same comparator.

### Ownership and Data Flow

```text
future Diary controller
        ↓
MealLogRepository.listByLocalDate(MealLogLocalDate)
        ↓
SupabaseMealLogRepository / InMemoryMealLogRepository
        ↓
MealLogTableGateway (Supabase only)
        ↓
meal_log_entries + existing owner RLS
```

### Alternative Rejected

Direct table reads from `MealDiaryPage` and recomputing Diary date from `consumedAt` were rejected because they violate persistence ownership and timezone-stable historical grouping.

### Failure and Accessibility States

- signed-out Supabase read fails before gateway access;
- malformed/unsupported rows fail closed rather than being silently skipped;
- empty date returns an empty list;
- no accessibility surface changed because no UI changed.

## 5. Implementation Plan

- [x] Recheck exact branch/base and scope before source edits.
- [x] Move Linear TNYX-197 to `In Progress`.
- [x] Add `listByLocalDate(MealLogLocalDate)` to `MealLogRepository`.
- [x] Add owner/date-scoped list method to `MealLogTableGateway` and Supabase implementation.
- [x] Reuse the canonical strict decoder for every row.
- [x] Add deterministic in-memory filtering/ordering parity.
- [x] Cover empty/multiple dates, newest-first/ties, signed-out failure, archived category history, query arguments and malformed-row failure.
- [x] Audit base-to-head scope and open Draft PR #256.
- [x] Validate the exact source head in Flutter CI #2381.
- [ ] Verify current docs-only reconciliation head and finish review handoff.

## 6. Quality Review

### Validation Run

```text
Source head: 7bba235a10d13b810566f3de1f80c53dfb38f59b
Flutter CI #2381
Run: 34621964823
Job: 103337867111

Bootstrap workspace         PASS
Analyze Flutter packages    PASS
Analyze Dart packages       PASS
Test Flutter packages       PASS
Test Dart packages          PASS
```

No Supabase Database CI is expected because this slice changes no `supabase/**` file or live schema.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| — | — | — | No P1/P2 implementation finding after source/diff review | `7bba235a...` | Exact-source CI #2381 green; final current-head review remains. |

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/tnyx-197-meal-log-selected-day-read-foundation.md
apps/features/nutrition/lib/src/domain/repositories/meal_log_repository.dart
apps/features/nutrition/lib/src/data/in_memory_meal_log_repository.dart
apps/features/nutrition/lib/src/data/repositories/supabase_meal_log_repository.dart
apps/features/nutrition/test/data/in_memory_meal_log_repository_test.dart
apps/features/nutrition/test/data/supabase_meal_log_repository_test.dart
```

### Actual Behavior

Nutrition can now request canonical manual MealLog history for one stored local date through the repository boundary. Supabase reads are owner/date scoped, historical category activity is not revalidated, malformed rows fail closed, and results are deterministic newest-first. The in-memory fallback mirrors those semantics.

### Known Limitations

- no Diary consumer/rendering yet;
- no Quick Add save wiring/enablement;
- no edit/delete lifecycle;
- no detailed MealLog items;
- broader N14 display preferences remain separate.

### Final Status

`REVIEW` — implementation source validated; current docs-only PR head still requires exact-head CI/review reconciliation before Ready-for-review.
