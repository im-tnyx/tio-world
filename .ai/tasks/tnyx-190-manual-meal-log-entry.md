# TNYX-190 — N20A-3 Manual-mode MealLogEntry core aggregate

**Status:** In progress
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
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-11
**Branch:** `tnyx/tnyx-190-n20a-3-manual-mode-meallogentry-core-aggregate-contract`
**HEAD SHA:** `cc558d70633834bd69a8ba35d7f9f5acfd651ac2` before this task-brief commit
**Observed working-tree state:** GitHub API execution. No local checkout is available, so local `git status` cannot be inspected.
**Observed uncommitted/dirty files:** Not observable through GitHub API. No unrelated repository files will be modified.
**PR / tracker:** Linear TNYX-190 In Progress under TNYX-113. TNYX-66 readiness merged in PR #246.
**Current implementation state:** No runtime `MealLogEntry` or `MealLogItemSnapshot` exists. Shared Nutrition exports `NutritionSnapshot`, `MealLogCaptureSource`, `MealLogMode`, `NutrientId`.
**Relevant execution surface:** `apps/shared/lib/src/nutrition`, `apps/shared/test/nutrition`, shared Nutrition barrel export
**Validation completed at SHA:** Readiness evidence at `cc558d70`; implementation validation not run yet.
**Validation remaining:** Focused tests / package CI, diff scope review, exact-head checks.
**Current blocker:** None inside approved manual-mode slice.
**Open review finding IDs:** None
**Next exact action:** Add bounded date-only value representation + `MealLogEntry.manual`, export them, add focused tests, then open PR and use CI/review as the executable validation gate.

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

Create a Nutrition-bounded date-only value object if needed, create `MealLogEntry.manual`, export the contract, add focused tests.

### Non-Goals

Detailed food item model, provider provenance, repository/DTO/schema, Quick Add save wiring, date/time picker, DST resolution, SQL, RLS, ads or entitlement logic.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `.ai/workflow.md`, TNYX-66 readiness record, Linear TNYX-113/TNYX-114/TNYX-190, current `apps/shared/lib/src/nutrition` inventory.
- Existing pattern to follow: pure Dart shared value/domain contracts; `MealLogMode` and `MealLogCaptureSource` stable identities, `NutritionSnapshot` immutable value, plain `String id` entity convention in shared workout models.
- Tests or validation already present: focused tests exist per current Nutrition contract. No `MealLogEntry` test exists yet.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Manual mode only | Locked | Detailed mode depends on unresolved item/serving/provenance contracts | TNYX-66 / TNYX-190 |
| Keep local date separate from instant | Locked | TNYX-114 historical Diary identity must not move with device timezone | TNYX-114 |
| Aggregate receives resolved time facts | Locked | DST/timezone resolution belongs outside this aggregate | TNYX-114 |
| Nutrition-bounded date-only type | Chosen | Avoid treating a calendar date as an instant and avoid speculative cross-domain abstraction | Implementation |
| No JSON/storage codec on `MealLogEntry` yet | Chosen | Physical persistence/DTO layout is deliberately out of scope | Implementation |
| `manualNutritionSnapshot` exposed as nullable aggregate field | Chosen | Future detailed mode must share the same canonical aggregate while manual factory guarantees non-null today | Implementation |

## 4. Architecture Design

### Chosen Approach

Add `MealLogLocalDate` as a small immutable Nutrition-domain value object (`year`, `month`, `day`) with validation, ISO date parsing/formatting, equality/hash. Add one canonical `MealLogEntry` final class with a private constructor and a public `MealLogEntry.manual` factory. The factory pins `mode = MealLogMode.manual`, requires `manualNutritionSnapshot`, stores no detailed items, and normalizes whitespace-only `mealName` to null.

`consumedAt` remains a `DateTime` instant supplied by the caller. The aggregate stores the separately supplied `MealLogLocalDate` and optional timezone/offset context without deriving one from another.

### Ownership and Data Flow

```text
Feature draft / future resolver
        ↓ already-resolved time facts
apps/shared MealLogEntry.manual
        ↓ later slice
Repository / Supabase persistence
```

### Alternative Rejected

- `DateTime` at midnight for `consumedLocalDate`: rejected because it falsely models a calendar identity as an instant and can be shifted by timezone conversions.
- `String consumedLocalDate`: rejected because malformed dates would become representable throughout the domain.
- provider/item placeholder fields: rejected because they would pre-empt unresolved detailed-mode contracts.
- sealed manual/detailed subclasses: rejected for this slice because the readiness gate calls for one canonical aggregate that future detailed support extends rather than parallel aggregate identities.

### Failure and Accessibility States

Non-UI domain slice. Invalid local calendar dates fail synchronously with `ArgumentError`; malformed ISO date strings fail with `FormatException`. No user-visible accessibility state changes.

## 5. Implementation Plan

- [ ] Add `MealLogLocalDate` immutable value object.
- [ ] Add `MealLogEntry.manual` canonical aggregate factory.
- [ ] Export new contracts from Nutrition barrel.
- [ ] Add focused unit tests.
- [ ] Open PR from exact current base and run/review CI.
- [ ] Update this handoff only after validation/review evidence exists.

## 6. Quality Review

### Validation Run

```text
Not run yet. GitHub API environment has no local Dart/Flutter runner; PR CI will be used for executable validation.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | — | Resolved | No finding yet | `cc558d70` | Pre-implementation audit |

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

Detailed-mode aggregate, persistence and feature integration remain intentionally unavailable.

### Final Status

`PARTIAL`
