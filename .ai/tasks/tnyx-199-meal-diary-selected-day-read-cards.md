# TNYX-199 — N4B Manual MealLog selected-day Diary sections & read-only cards

**Status:** In review
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
**Implementation owner:** None — implementation complete and awaiting review
**Review owner:** PR/owner review
**Implementation ownership state:** Review handoff
**Ownership transition:** Implementation ownership released after exact-source validation at `539d85e06b674c1aff847cd71c4edbc1fc0f544c`.
**Repository state last verified:** `main == 7a96e382d36d295f821826cb9d49fd38b0f533a9`; source head `539d85e06b674c1aff847cd71c4edbc1fc0f544c` is `26 ahead / 0 behind` with exact merge base and 14 TNYX-199-owned changed files.
**Branch:** `tnyx/tnyx-199-n4b-manual-meallog-selected-day-diary-sections-read-only`
**Observed working-tree state:** API-only session; no local checkout modified.
**PR / tracker:** PR #258 ready for review; Linear TNYX-199 should be `In Review`.
**Current implementation state:** Approved selected-day read/render behavior and T199-R3 category-label freshness remediation are complete.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_diary/**`, Meal Categories repository change notification, focused tests, app composition, docs/task brief.
**Validation completed at SHA:** `539d85e06b674c1aff847cd71c4edbc1fc0f544c` — Flutter CI #2410 passed bootstrap, both analyzers, Flutter tests, and Dart tests.
**Validation remaining:** Owner/PR review only. This handoff file update is governance-only and does not alter validated source behavior.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Review PR #258. Merge still requires explicit owner authorization.

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

Final behavior review found one freshness gap: category-management writes could complete while the stateful Diary remained mounted, but the already-watched selected-day history request had no reason to re-read the canonical category configuration. T199-R3 closed that gap without adding navigation knowledge to Nutrition.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Unnamed Quick Add displays `Quick Add` | Owner-approved | Source is persisted; fallback stays presentation-only |
| Unnamed non-Quick-Add has no fabricated Quick Add title | Locked | Do not invent identity |
| Missing nutrients stay unknown | Locked | `NutritionSnapshot` distinguishes absent from zero |
| Diary ordering ignores category configured order | Locked | N4 is latest-actual-activity ordered |
| Category persistence refreshes active Diary history | Resolved | Section labels must reflect current resolvable `displayName` even while Diary remains mounted |
| Historical visible time does not use current-device `toLocal()` | Locked | Preserve logging context |

## 4. Architecture Design

### Chosen Approach

The selected-day history remains a feature `FutureProvider.autoDispose.family`. `MealCategoriesRepository` stays the canonical read/write boundary. Repositories that can report confirmed local writes may additionally implement the optional `MealCategoriesChangeSource` contract.

Production Supabase and in-memory adapters emit a change event only after a successful `upsert`. The selected-day history provider subscribes when the supplied repository supports that optional contract and calls `ref.invalidateSelf()` on a confirmed change, causing the same selected local-date request to re-read both MealLog history and the current retained Meal Categories config.

```text
MealCategoriesRepository.upsert(...)
        ↓ confirmed persistence
optional MealCategoriesChangeSource event
        ↓
mealDiaryHistoryProvider(request).invalidateSelf()
        ↓
MealLogRepository.listByLocalDate(...) + MealCategoriesRepository.read()
        ↓
current section display labels
```

Failed writes emit no change event. Repository implementations/fakes that do not support change notifications keep the original read contract unchanged.

### Alternatives Rejected

- Do not introduce a second globally cached Meal Categories config/revision store just for Diary freshness.
- Do not make `MealDiaryPage` observe `GoRouter` route transitions. That experimental route-observer approach coupled feature state to app navigation, failed its harness during review, and was fully removed before the final implementation.
- Do not move category-management semantics into the Diary. The repository remains canonical; an optional post-write signal is sufficient.

## 5. Implementation Plan

- [x] Selected-day immutable history request/read model and race-safe family provider.
- [x] Dynamic category grouping/order and nutrition aggregates.
- [x] Source-aware title fallback and historical offset-based time reconstruction.
- [x] Read-only governed card rendering + N14 presentation preferences.
- [x] Loading/empty/retryable error states.
- [x] Initial focused provider/widget tests and docs reconciliation.
- [x] T199-R3: emit confirmed category-write notification from canonical adapters and self-invalidate active Diary history.
- [x] Add focused freshness regression test.
- [x] Add Supabase success/failure notification contract test.
- [x] Rerun full CI and final scope audit.

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

Final validated source after T199-R3: 539d85e06b674c1aff847cd71c4edbc1fc0f544c
Flutter CI #2410 / run 34663987536 / job 103472072070
Bootstrap PASS
Flutter analyze PASS
Dart analyze PASS
Flutter tests PASS
Dart tests PASS

Final scope audit at validated source:
main/base: 7a96e382d36d295f821826cb9d49fd38b0f533a9
merge base: exact base
branch: 26 ahead / 0 behind
changed files: 14, all within TNYX-199 scope
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Evidence / follow-up |
|---|---|---|---|---|
| T199-R1 | Medium | Resolved | Test notifiers were manually disposed in addition to ProviderScope ownership | fixed before CI #2395 |
| T199-R2 | Low | Resolved | Retry closure needed explicit nullable request narrowing | fixed before CI #2395 |
| T199-R3 | Medium | Resolved | Confirmed Meal Category changes did not invalidate already-mounted selected-day history, so section labels could remain stale | optional confirmed-write change source + provider self-invalidation + focused regression tests; final CI #2410 green |

### Failed Review Experiments Kept Out Of Final Source

A route-observer prototype was tried while investigating T199-R3. CI exposed a harness/runtime mismatch before handoff, so that approach and its test were removed. The final source contains no `GoRouter` dependency in `MealDiaryPage` for freshness.

## 7. Final Handoff

### Changed Files

The final source scope contains:

- TNYX-199 task brief and Meal Diary screen documentation;
- app composition for the canonical MealLog repository;
- Meal Diary selected-day history provider/read models;
- read-only history rendering/page integration;
- optional Meal Categories confirmed-write change-source contract;
- Supabase and in-memory change-source implementations;
- focused provider, widget, category-refresh, and change-source tests.

### Known Limitations

Quick Add create/save, edit/delete/move, card-to-editor navigation, detailed item/photo rendering, daily summary/rings and broader offline mutation/replay behavior remain deferred.

### Final Status

`REVIEW`
