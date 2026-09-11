# TNYX-199 — N4B Manual MealLog selected-day Diary sections & read-only cards

**Status:** In progress
**Primary owner:** `apps/features/nutrition`
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + product-visible UI change
**Approval status:** Approved
**Approval evidence:** Owner approved the N4B slice after fresh N0/readiness and explicitly approved `Quick Add` as a source-aware display-only title fallback for unnamed Quick Add history.
**Approved product/UI/data-shape boundaries:** Selected-day canonical MealLog reads, dynamic Meal Category sections, compact read-only cards, N14 display preferences, loading/empty/error states, focused tests, and stale Meal Diary documentation reconciliation. No data-shape change.
**Explicit non-changes:** No Quick Add create/save activation, edit/delete/move, card-to-editor navigation, item-level detail/photos, N3 daily summary/calendar rings, Supabase schema/RLS/migration, Meal Category management semantics, or Meal Plan.

## Active Handoff

**Planning owner:** Current AI session
**Implementation owner:** Current AI session
**Review owner:** Current AI session + PR/owner review
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** Base `main` = `7a96e382d36d295f821826cb9d49fd38b0f533a9`. Initial implementation source `a25d53e5b6e857d737327fde94295c23a1b2be52` passed Flutter CI #2395. PR #258 was then returned to Draft after finding T199-R3 during final behavior review.
**Branch:** `tnyx/tnyx-199-n4b-manual-meallog-selected-day-diary-sections-read-only`
**Observed working-tree state:** API-only session; no local checkout modified.
**PR / tracker:** Draft PR #258; Linear TNYX-199 returned to `In Progress` while T199-R3 is fixed.
**Current implementation state:** Core read/render behavior is implemented and previously green; one category-label freshness finding is open.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_diary/**`, category management presentation/controller callbacks, `apps/app/lib/app/router.dart`, focused tests, docs/task brief.
**Validation completed at SHA:** `a25d53e5b6e857d737327fde94295c23a1b2be52` — Flutter CI #2395 passed all analyze/tests before T199-R3 remediation.
**Validation remaining:** Focused test for category-config persistence invalidation + full Flutter CI after the fix + final scope audit.
**Current blocker:** T199-R3 only.
**Open review finding IDs:** T199-R3.
**Next exact action:** Invalidate active Meal Diary history after a confirmed Meal Categories persistence change, test it, rerun CI, then return PR/Linear to review.

**Repository note:** An accidental unused sibling branch `tnyx/tnyx-199-n4b-manual-meallog-selected-day-diary-sections-read-only-check` exists only at the base SHA and is not part of PR #258. It remains untouched because deletion was not authorized.

## Global UI / Design-System Guardrail

Reuse existing `package:tio_core/core.dart` components and governed theme roles. No new Core component/token family or feature-local design token catalog is introduced.

## 1. Discovery

### User Outcome

The selected Diary date shows canonical persisted manual meals grouped under the current resolvable Meal Category label, ordered by latest actual activity, with compact read-only nutrition/time/note presentation.

### Success Criteria

- selected date reads `MealLogRepository.listByLocalDate`;
- latest activity section first; newest entry first;
- retained archived category identity remains resolvable;
- a category rename/archive/reactivate that persists while Diary stays mounted refreshes the section read model;
- missing nutrients remain unknown rather than zero/partial authoritative totals;
- `Quick Add` fallback is source-aware and presentation-only;
- N14 preferences change presentation only;
- loading/empty/retryable error and stale selected-date responses are handled.

### Non-Goals

No mutation/edit flow, daily summary/rings, schema change, category-management rule change, or Meal Plan work.

## 2. Codebase Exploration

Verified runtime contracts: `MealLogRepository.listByLocalDate`, `MealCategoriesRepository.read/upsert`, retained `MealCategoriesConfig.findById`, `MealDiaryDisplayPreferences`, `MealDiaryDateController`, canonical app repository providers, and Core `TioCard`.

Final review additionally verified Meal Categories Settings is pushed on the root navigator while the Diary shell route stays mounted. Current category-management writes do not invalidate `mealDiaryHistoryProvider`, so a confirmed rename can leave an already-watched section label stale until another date/repository request happens.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Unnamed Quick Add displays `Quick Add` | Owner-approved | Source is persisted; fallback stays presentation-only |
| Unnamed non-Quick-Add has no fabricated Quick Add title | Locked | Do not invent identity |
| Missing nutrients stay unknown | Locked | `NutritionSnapshot` distinguishes absent from zero |
| Diary ordering ignores category configured order | Locked | N4 is latest-actual-activity ordered |
| Category persistence refreshes active Diary history | Required by review | Section labels must reflect current resolvable `displayName` even while Diary remains mounted |
| Historical visible time does not use current-device `toLocal()` | Locked | Preserve logging context |

## 4. Architecture Design

### Chosen Approach

The selected-day history remains a feature `FutureProvider.autoDispose.family`. Meal Categories management gains an optional confirmed-persistence callback. App composition uses that callback to invalidate the history family after a successful category write (and after a conflict reload exposes newer stored configuration), so an already-mounted Diary re-reads categories/logs without introducing a second category store.

```text
MealCategoriesController confirmed persistence/reload
        ↓ callback
apps/app composition
        ↓ ref.invalidate(mealDiaryHistoryProvider)
active MealDiary history family
        ↓ fresh MealCategoriesRepository.read()
current section display labels
```

### Alternative Rejected

Do not introduce a second globally-cached Meal Categories config/revision store just for Diary freshness. The repository remains canonical; invalidation is enough.

## 5. Implementation Plan

- [x] Selected-day immutable history request/read model and race-safe family provider.
- [x] Dynamic category grouping/order and nutrition aggregates.
- [x] Source-aware title fallback and historical offset-based time reconstruction.
- [x] Read-only governed card rendering + N14 presentation preferences.
- [x] Loading/empty/retryable error states.
- [x] Initial focused provider/widget tests and docs reconciliation.
- [ ] T199-R3: expose confirmed category-persistence notification and invalidate Meal Diary history family.
- [ ] Add focused freshness test.
- [ ] Rerun full CI and final scope audit.

## 6. Quality Review

### Validation Run

```text
Initial validated source: a25d53e5b6e857d737327fde94295c23a1b2be52
Flutter CI #2395 / run 34634021191 / job 103377445899
Bootstrap PASS
Flutter analyze PASS
Dart analyze PASS
Flutter tests PASS
Dart tests PASS

Revalidation required after T199-R3 remediation.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Evidence / follow-up |
|---|---|---|---|---|
| T199-R1 | Medium | Resolved | Test notifiers were manually disposed in addition to ProviderScope ownership | fixed before CI #2395 |
| T199-R2 | Low | Resolved | Retry closure needed explicit nullable request narrowing | fixed before CI #2395 |
| T199-R3 | Medium | Open | Confirmed Meal Category changes do not invalidate already-mounted selected-day history, so section labels can remain stale | invalidate history family on confirmed category persistence/reload and test |

## 7. Final Handoff

### Changed Files

Current PR owns the TNYX-199 task brief, Meal Diary history provider/view/page integration, app composition seam, focused history tests, and Meal Diary screen documentation. T199-R3 will add only the smallest category-persistence freshness wiring/tests necessary for the approved section-label contract.

### Known Limitations

Quick Add create/save, edit/delete/move, card-to-editor navigation, detailed item/photo rendering, daily summary/rings and broader offline mutation/replay behavior remain deferred.

### Final Status

`REVIEW` after T199-R3 is resolved and revalidated; currently `PARTIAL`.
