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
**Implementation ownership state:** Active — reopened for review remediation
**Ownership transition:** Review handoff was reopened after Codex-style review found T199-R4.
**Repository state last verified:** `main == 7a96e382d36d295f821826cb9d49fd38b0f533a9`; previous validated source `539d85e06b674c1aff847cd71c4edbc1fc0f544c` passed Flutter CI #2410. PR #258 is back in Draft for T199-R4 remediation.
**Branch:** `tnyx/tnyx-199-n4b-manual-meallog-selected-day-diary-sections-read-only`
**Observed working-tree state:** API-only session; no local checkout modified.
**PR / tracker:** Draft PR #258; Linear TNYX-199 returned to `In Progress`.
**Current implementation state:** Core selected-day read/render and category-label freshness are implemented; one stable-empty-day correctness finding is open.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_diary/meal_diary_history_providers.dart`, focused provider tests, docs/task brief.
**Validation completed at SHA:** `539d85e06b674c1aff847cd71c4edbc1fc0f544c` — Flutter CI #2410 passed bootstrap, both analyzers, Flutter tests, and Dart tests before T199-R4 remediation.
**Validation remaining:** Focused empty-day regression + full Flutter CI after the fix + final scope audit.
**Current blocker:** T199-R4 only.
**Open review finding IDs:** T199-R4.
**Next exact action:** Make Meal Categories resolution irrelevant for a known-empty MealLog day, add a regression test, rerun full CI, then return PR/Linear to review.

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
- a selected day with zero MealLog entries resolves to the stable empty state without depending on Meal Categories availability;
- missing nutrients remain unknown rather than zero/partial authoritative totals;
- `Quick Add` fallback is source-aware and presentation-only;
- N14 preferences change presentation only;
- loading/empty/retryable error and stale selected-date responses are handled.

### Non-Goals

No mutation/edit flow, daily summary/rings, schema change, category-management rule change, or Meal Plan work.

## 2. Codebase Exploration

Verified runtime contracts: `MealLogRepository.listByLocalDate`, `MealCategoriesRepository.read/upsert`, retained `MealCategoriesConfig.findById`, `MealDiaryDisplayPreferences`, `MealDiaryDateController`, canonical app repository providers, and Core `TioCard`.

T199-R3 closed the category-label freshness gap with an optional confirmed-write change source. A later Codex-style review found T199-R4: the provider currently `Future.wait`s MealLog and Meal Categories reads, so a category read failure can turn a day already known to have zero MealLog entries into an error instead of the parent N4 stable empty-day state.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Unnamed Quick Add displays `Quick Add` | Owner-approved | Source is persisted; fallback stays presentation-only |
| Unnamed non-Quick-Add has no fabricated Quick Add title | Locked | Do not invent identity |
| Missing nutrients stay unknown | Locked | `NutritionSnapshot` distinguishes absent from zero |
| Diary ordering ignores category configured order | Locked | N4 is latest-actual-activity ordered |
| Category persistence refreshes active Diary history | Resolved | Section labels must reflect current resolvable `displayName` even while Diary remains mounted |
| Empty MealLog day does not require Meal Categories | Required by review | Category identity is only needed to render non-empty sections; N4 requires a stable empty-day state |
| Historical visible time does not use current-device `toLocal()` | Locked | Preserve logging context |

## 4. Architecture Design

### Chosen Approach

The selected-day history remains a feature `FutureProvider.autoDispose.family`. `MealCategoriesRepository` stays the canonical category boundary. The provider must establish selected-day MealLog entries first; when the result is empty it returns the immutable empty history immediately. Category change subscription and category resolution are required only for non-empty history, where section labels actually exist.

For non-empty history, repositories that implement `MealCategoriesChangeSource` continue to invalidate the active provider only after confirmed category writes. Failed writes still emit no change event.

```text
MealLogRepository.listByLocalDate(...)
        ↓
entries empty? ── yes ──→ stable empty history
        │ no
        ↓
optional MealCategoriesChangeSource subscription
        ↓
MealCategoriesRepository.read()
        ↓
resolve sections + current display labels
```

### Alternatives Rejected

- Do not keep `Future.wait` and let an unrelated category error override a known-empty MealLog result.
- Do not introduce a second category cache/store.
- Do not add route knowledge to Nutrition.

## 5. Implementation Plan

- [x] Selected-day immutable history request/read model and race-safe family provider.
- [x] Dynamic category grouping/order and nutrition aggregates.
- [x] Source-aware title fallback and historical offset-based time reconstruction.
- [x] Read-only governed card rendering + N14 presentation preferences.
- [x] Loading/empty/retryable error states.
- [x] Initial focused provider/widget tests and docs reconciliation.
- [x] T199-R3: emit confirmed category-write notification from canonical adapters and self-invalidate active Diary history.
- [x] Add focused category freshness and Supabase notification tests.
- [ ] T199-R4: short-circuit known-empty MealLog history before category read/subscription.
- [ ] Add regression test proving category read failure is irrelevant for an empty day.
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

Previous validated source after T199-R3: 539d85e06b674c1aff847cd71c4edbc1fc0f544c
Flutter CI #2410 / run 34663987536 / job 103472072070
Bootstrap PASS
Flutter analyze PASS
Dart analyze PASS
Flutter tests PASS
Dart tests PASS

Revalidation required after T199-R4 remediation.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Evidence / follow-up |
|---|---|---|---|---|
| T199-R1 | Medium | Resolved | Test notifiers were manually disposed in addition to ProviderScope ownership | fixed before CI #2395 |
| T199-R2 | Low | Resolved | Retry closure needed explicit nullable request narrowing | fixed before CI #2395 |
| T199-R3 | Medium | Resolved | Confirmed Meal Category changes did not invalidate already-mounted selected-day history, so section labels could remain stale | optional confirmed-write change source + provider self-invalidation + focused regression tests; CI #2410 green |
| T199-R4 | P2 | Open | `Future.wait` makes Meal Categories availability gate a day already known to contain zero MealLog entries, violating N4 stable empty-day behavior | short-circuit empty MealLog result before category dependency and add regression coverage |

## 7. Final Handoff

### Changed Files

Current PR owns the TNYX-199 task brief, app MealLog composition seam, Meal Diary selected-day history provider/read models, read-only history rendering/page integration, optional Meal Categories confirmed-write change source, focused tests, and Meal Diary screen documentation. T199-R4 changes only the selected-day provider sequencing plus focused regression coverage.

### Known Limitations

Quick Add create/save, edit/delete/move, card-to-editor navigation, detailed item/photo rendering, daily summary/rings and broader offline mutation/replay behavior remain deferred.

### Final Status

`PARTIAL` until T199-R4 is fixed and revalidated.
