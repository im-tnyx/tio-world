# TNYX-190 — N20A-3 Manual-mode MealLogEntry core aggregate

**Status:** In Review — manual review fixes applied; exact-head validation pending
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
**Review owner:** Owner / manual PR review
**Implementation ownership state:** Implementation complete; manual review fixes applied; validation/re-review active
**Repository state last verified:** 2026-09-11
**Branch:** `tnyx/tnyx-190-n20a-3-manual-mode-meallogentry-core-aggregate-contract`
**PR / tracker:** PR #247 is ready for review; Linear TNYX-190 is `In Review` under TNYX-113.
**Prior validated head:** `66ae125970727151fd6adec492a02c374009e401` passed Flutter CI #2356 before the manual-review fixes.
**Current implementation state:** `MealLogLocalDate` and manual-only `MealLogEntry` are implemented and publicly exported. Manual construction now requires enough consumed-time context for deterministic historical presentation/edit reconstruction: a meaningful timezone ID or a UTC offset must be present.
**Relevant execution surface:** `apps/shared/lib/src/nutrition`, `apps/shared/test/nutrition`, shared Nutrition barrel export
**Validation remaining:** exact-head Flutter CI after review fixes; final ancestry/scope audit; manual re-review; resolve review threads only after verification.
**Current blocker:** P2/P3 fixes require verification before merge.
**Open review finding IDs:** P2 consumed-time context invariant; P3 stale active handoff. Both fixes are applied on the branch and await verification.
**Next exact action:** Run/review exact-head CI, re-read the final diff, resolve P2/P3 only if verified, then merge PR #247 under the owner's current proceed instruction and mark TNYX-190 Done.

Repository governance references `.github/POST_MERGE_SYNC.md`, but that file is absent on the audited base. That separate governance discrepancy is not repaired in TNYX-190.

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
- At least one meaningful consumed-time context value is retained: timezone ID or UTC offset.
- Blank `mealName` becomes `null`; nonblank input is not otherwise rewritten.
- No persistence/UI/provider/concurrency scope leaks in.
- Focused tests cover construction, date identity, name normalization and time-context invariants.

### Scope

Create a Nutrition-bounded date-only value object, create `MealLogEntry.manual`, export the contract, add focused tests, and close review findings inside that same domain boundary.

### Non-Goals

Detailed food item model, provider provenance, repository/DTO/schema, Quick Add save wiring, date/time picker, DST resolution, SQL, RLS, ads or entitlement logic.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md`, `.ai/workflow.md`, TNYX-66 readiness record and current shared Nutrition source were audited before implementation.
- Linear TNYX-113 owns the aggregate direction; TNYX-114 owns consumed instant/local-date/timezone semantics; TNYX-190 is the bounded manual-mode child slice.
- Existing shared convention supports pure Dart contracts and plain string entity identities.
- Focused tests use `package:test` under `apps/shared/test/nutrition`.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Manual mode only | Locked | Detailed mode depends on unresolved item/serving/provenance contracts | TNYX-66 / TNYX-190 |
| Keep local date separate from instant | Locked | Historical Diary identity must not move with device timezone | TNYX-114 |
| Aggregate receives resolved time facts | Locked | DST/timezone resolution belongs outside this aggregate | TNYX-114 |
| Require timezone ID or UTC offset | Implemented after P2 review | Without either, original logged local clock time cannot be deterministically reconstructed | TNYX-114 / manual review |
| Nutrition-bounded date-only type | Implemented | Avoid modeling calendar identity as an instant | Implementation |
| No JSON/storage codec yet | Implemented | Physical persistence is a later audited slice | Implementation |
| `manualNutritionSnapshot` nullable at aggregate field level | Implemented | Future detailed mode can share one aggregate while manual factory guarantees non-null | Implementation |

## 4. Architecture Design

`MealLogLocalDate` is an immutable Nutrition value object with Gregorian validation, canonical `YYYY-MM-DD` parsing/formatting, equality and hash semantics.

`MealLogEntry` is one canonical final class with a private constructor and public `MealLogEntry.manual` factory. The factory pins `mode = MealLogMode.manual`, requires `manualNutritionSnapshot`, creates no detailed items, keeps user-intended local date separate from the chronology instant, and normalizes whitespace-only meal names to null.

Consumed-time context remains already-resolved caller input. The aggregate does not perform DST/timezone resolution. It only rejects the information-losing state where both a meaningful timezone ID and UTC offset are absent.

```text
Feature draft / future time resolver
        ↓ already-resolved instant + local date + time context
apps/shared MealLogEntry.manual
        ↓ later approved slice
Repository / Supabase persistence
```

## 5. Implementation Checklist

- [x] Add `MealLogLocalDate` immutable value object.
- [x] Add `MealLogEntry.manual` canonical aggregate factory.
- [x] Export new contracts from Nutrition barrel.
- [x] Add focused unit tests.
- [x] Open PR #247 from the approved base.
- [x] Initial exact-head CI #2356 passed before manual review fixes.
- [x] Manual exhaustive review performed because Codex review quota was unavailable.
- [x] Apply P2 consumed-time context fix and focused tests.
- [x] Apply P3 active-handoff reconciliation.
- [ ] Validate current exact head and perform final manual re-review.
- [ ] Resolve P2/P3 threads only after verified.
- [ ] Merge and complete Linear handoff.

## 6. Quality Review

### Prior Validation

At head `66ae125970727151fd6adec492a02c374009e401`, Flutter CI #2356 completed successfully:

```text
Workspace bootstrap        PASS
Analyze Flutter packages   PASS
Analyze Dart packages      PASS
Test Flutter packages      PASS
Test Dart packages         PASS
```

A manual exhaustive review then found two issues not caught by CI:

| ID | Severity | Status | Finding | Resolution applied |
|---|---|---|---|---|
| P2 | P2 | Fix applied; verification pending | Both consumed timezone ID and UTC offset could be absent, losing deterministic local-time reconstruction context | Factory now requires at least one meaningful context value; tests cover timezone-only, offset-only, missing and blank-only cases |
| P3 | P3 | Fix applied; verification pending | Active `.ai/tasks` handoff was stale versus PR/Linear/CI state | This handoff now reflects PR ready, Linear In Review, prior CI success and current review-fix validation state |

### Current Validation Gate

The review-fix commits changed the PR head after CI #2356, so completion requires fresh exact-head CI plus final diff/review-thread verification. No finding is considered resolved merely because a fix was written.

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

- Manual actual-history entries use one canonical `MealLogEntry` domain type.
- Manual construction always produces `MealLogMode.manual` and requires `NutritionSnapshot`.
- No fake detailed food/item identity is created.
- User-intended Diary date remains independent from the canonical consumed instant.
- A meaningful timezone ID or UTC offset is required so consumed-time context is not lost.
- Timezone ID and UTC offset remain individually optional; this slice does not resolve DST or timezone rules.
- Blank/whitespace meal names remain absent instead of persisting a presentation fallback.

### Known Limitations

Detailed-mode construction, `MealLogItemSnapshot`, provider provenance, physical persistence, repositories, Quick Add save integration, edit/delete behavior and timezone/DST resolution remain intentionally deferred to later gated slices.

### Final Status

`REVIEW` — P2/P3 fixes applied; exact-head validation and manual re-review pending.
