# TNYX-190 — N20A-3 Manual-mode MealLogEntry core aggregate

**Status:** In progress — implementation complete, exact-head validation pending
**Primary owner:** `apps/shared` Nutrition domain
**Affected platforms:** Shared Dart domain only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product/domain slice
**Approval status:** Approved
**Approval evidence:** Owner instructed the work to continue after the TNYX-66 audit. PR #246 merged the fresh readiness result and explicitly authorises only the manual-mode `MealLogEntry` core slice.
**Approved product/UI/data-shape boundaries:** Pure `apps/shared` domain contract + focused tests + public export. Manual-mode construction only.
**Explicit non-changes:** No detailed-mode construction, `MealLogItemSnapshot`, serving/normalization/provider provenance, Supabase schema/RLS/migration, repository wiring, Quick Add save behavior, UI/navigation, timezone/DST resolver, concurrency/version/idempotency, ads/membership fields.

## Active Handoff

**Planning owner:** TNYX-66 / TNYX-190
**Implementation owner:** ChatGPT
**Review owner:** Owner / PR review
**Implementation ownership state:** Complete; validation/review active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-11
**Branch:** `tnyx/tnyx-190-n20a-3-manual-mode-meallogentry-core-aggregate-contract`
**Implementation code SHA:** `d282c063706b039e8c5ad13b580704109e985ed3`
**Observed working-tree state:** GitHub API execution. No local checkout is available, so local `git status` cannot be inspected.
**Observed uncommitted/dirty files:** Not observable through GitHub API. Parent-to-head API compare showed only this task's intended files.
**PR / tracker:** Draft PR #247; Linear TNYX-190 In Progress under TNYX-113. TNYX-66 readiness merged in PR #246.
**Current implementation state:** `MealLogLocalDate` and manual-only `MealLogEntry` are implemented, publicly exported, and covered by focused tests. No detailed item/persistence/feature integration exists.
**Relevant execution surface:** `apps/shared/lib/src/nutrition`, `apps/shared/test/nutrition`, shared Nutrition barrel export
**Validation completed at implementation SHA:** Flutter CI #2355 on `d282c063` completed workspace bootstrap, Flutter package analysis and Dart package analysis successfully; full tests were still running when this checkpoint was written. Manual full-diff and scope review found no out-of-scope change.
**Validation remaining:** New exact-head CI after this handoff checkpoint commit, including Flutter tests + Dart tests; final ancestry/scope audit and PR review state.
**Current blocker:** None inside approved scope; completion depends only on validation/review gate.
**Open review finding IDs:** None
**Next exact action:** Let PR #247 CI validate the new exact head. If green and no review finding appears, mark the task validated / Linear In Review and make the PR ready for review. Do not merge without a separate owner proceed instruction.

Repository governance currently references `.github/POST_MERGE_SYNC.md`, but that file is absent on current `main`; this is a separate governance discrepancy and is not repaired in TNYX-190.

## Global UI / Design-System Guardrail

No Flutter production UI is changed by this task. Existing UI remains untouched.

## 1. Discovery

### User Outcome

Provide a canonical, provider-independent actual meal-history aggregate for manual/Quick Add nutrition so later persistence and Quick Add save wiring have one stable domain contract.

### Success Criteria

- `MealLogEntry` exists in shared Nutrition.
- Only manual-mode construction is exposed in this slice.
- Manual entries require `NutritionSnapshot` and never fabricate detailed items.
- `consumedAt` and user-intended `consumedLocalDate` remain separate facts.
- Optional timezone ID / UTC offset context can be retained without implementing timezone resolution.
- Blank `mealName` becomes `null`; nonblank input is not otherwise rewritten.
- No persistence/UI/provider/concurrency scope leaks in.
- Focused tests cover construction and invariants.

### Scope

Create a Nutrition-bounded date-only value object, create `MealLogEntry.manual`, export the contract, add focused tests.

### Non-Goals

Detailed food item model, provider provenance, repository/DTO/schema, Quick Add save wiring, date/time picker, DST resolution, SQL, RLS, ads or entitlement logic.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `.ai/workflow.md`, TNYX-66 readiness record, Linear TNYX-113/TNYX-114/TNYX-190, current `apps/shared/lib/src/nutrition` inventory.
- Existing pattern followed: pure Dart shared value/domain contracts; `MealLogMode` and `MealLogCaptureSource` stable identities, immutable `NutritionSnapshot`, plain `String id` entity convention in shared workout models.
- Existing validation pattern: focused `package:test` tests under `apps/shared/test/nutrition`.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Manual mode only | Locked | Detailed mode depends on unresolved item/serving/provenance contracts | TNYX-66 / TNYX-190 |
| Keep local date separate from instant | Locked | TNYX-114 historical Diary identity must not move with device timezone | TNYX-114 |
| Aggregate receives resolved time facts | Locked | DST/timezone resolution belongs outside this aggregate | TNYX-114 |
| Nutrition-bounded date-only type | Implemented | Avoid treating a calendar date as an instant and avoid speculative cross-domain abstraction | Implementation |
| No JSON/storage codec on `MealLogEntry` yet | Implemented | Physical persistence/DTO layout is deliberately out of scope | Implementation |
| `manualNutritionSnapshot` nullable at aggregate field level | Implemented | Future detailed mode can share one aggregate while manual factory guarantees non-null | Implementation |

## 4. Architecture Design

### Chosen Approach

`MealLogLocalDate` is a small immutable Nutrition-domain value object (`year`, `month`, `day`) with Gregorian-date validation, canonical `YYYY-MM-DD` parsing/formatting, equality and hash semantics.

`MealLogEntry` is one canonical final class with a private constructor and public `MealLogEntry.manual` factory. The factory pins `mode = MealLogMode.manual`, requires `manualNutritionSnapshot`, creates no detailed items, preserves optional capture/timezone context, and normalizes whitespace-only `mealName` to null.

`consumedAt` remains an already-resolved `DateTime` instant supplied by the caller. `consumedLocalDate` is stored independently and is never derived from the current device timezone by this aggregate.

### Ownership and Data Flow

```text
Feature draft / future resolver
        ↓ already-resolved time facts
apps/shared MealLogEntry.manual
        ↓ later approved slice
Repository / Supabase persistence
```

### Alternatives Rejected

- `DateTime` at midnight for `consumedLocalDate`: falsely models calendar identity as an instant.
- raw `String` local date: allows malformed calendar dates throughout the domain.
- provider/item placeholder fields: pre-empts unresolved detailed-mode contracts.
- parallel manual/detailed aggregate classes: risks competing actual-history identities instead of one canonical `MealLogEntry`.

### Failure and Accessibility States

Non-UI domain slice. Invalid calendar construction throws `ArgumentError`; malformed/non-canonical ISO date decoding throws `FormatException`. No user-visible accessibility state changes.

## 5. Implementation Plan

- [x] Add `MealLogLocalDate` immutable value object.
- [x] Add `MealLogEntry.manual` canonical aggregate factory.
- [x] Export new contracts from Nutrition barrel.
- [x] Add focused unit tests.
- [x] Open draft PR #247 from current `main` and start CI.
- [ ] Complete exact-head CI + review gate.

## 6. Quality Review

### Validation Run

At implementation SHA `d282c063706b039e8c5ad13b580704109e985ed3`, Flutter CI #2355 recorded:

```text
Workspace bootstrap        PASS
Analyze Flutter packages   PASS
Analyze Dart packages      PASS
Test Flutter packages      IN PROGRESS at checkpoint
Test Dart packages         pending at checkpoint
```

Because this handoff update changes the PR head, final completion requires a fresh exact-head CI result after this commit. No local Dart/Flutter runner is available in this GitHub API execution environment.

Manual review at `d282c063`:

- current `main` is the merge base;
- branch was 2 commits ahead / 0 behind before this checkpoint;
- exactly 5 task-owned files were changed;
- no Supabase, feature UI, provider, detailed item, repository or concurrency code entered the diff;
- no open PR review thread/finding existed at checkpoint.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | — | Resolved | No review finding at implementation checkpoint | `d282c063` | Manual full-diff + PR thread audit |

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/tnyx-190-manual-meal-log-entry.md
apps/shared/lib/src/nutrition/meal_log_entry.dart
apps/shared/lib/src/nutrition/meal_log_local_date.dart
apps/shared/lib/src/nutrition/nutrition.dart
apps/shared/test/nutrition/meal_log_entry_test.dart
```

### Actual Behavior

- Manual actual-history entries have one canonical `MealLogEntry` domain type.
- Manual construction always produces `MealLogMode.manual` and requires canonical `NutritionSnapshot` data.
- No fake detailed food/item identity is created.
- User-intended Diary date is represented independently from the consumed instant and can be preserved across device timezone changes.
- Optional timezone ID, UTC offset and capture-source context can be retained as already-resolved facts.
- Blank/whitespace meal names remain absent rather than persisting the presentation fallback `Quick Log`.

### Known Limitations

Detailed-mode construction, `MealLogItemSnapshot`, provider provenance, physical persistence, repositories, Quick Add save integration and timezone/DST resolution are intentionally unavailable and require later gated slices.

### Final Status

`REVIEW` — implementation complete; new exact-head CI and PR review gate pending.
