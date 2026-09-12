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
**Ownership transition:** Implementation ownership released after T199-R4 remediation and exact-source validation at `c3546a48bf72cb4a9a69ae5d84663ae3c0f2b109`.
**Repository state last verified:** `main == 7a96e382d36d295f821826cb9d49fd38b0f533a9`; validated source is `30 ahead / 0 behind` with exact merge base and 14 TNYX-199-owned changed files.
**Branch:** `tnyx/tnyx-199-n4b-manual-meallog-selected-day-diary-sections-read-only`
**Observed working-tree state:** API-only session; no local checkout modified.
**PR / tracker:** PR #258 ready to return to review; Linear TNYX-199 should return to `In Review`.
**Current implementation state:** Approved selected-day read/render behavior, category-label freshness, and stable empty-day behavior are complete.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_diary/**`, Meal Categories repository change notification, focused tests, app composition, docs/task brief.
**Validation completed at SHA:** `c3546a48bf72cb4a9a69ae5d84663ae3c0f2b109` — Flutter CI #2414 passed bootstrap, both analyzers, Flutter tests, and Dart tests.
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
- a selected day with zero MealLog entries resolves to the stable empty state without depending on Meal Categories availability;
- missing nutrients remain unknown rather than zero/partial authoritative totals;
- `Quick Add` fallback is source-aware and presentation-only;
- N14 preferences change presentation only;
- loading/empty/retryable error and stale selected-date responses are handled.

### Non-Goals

No mutation/edit flow, daily summary/rings, schema change, category-management rule change, or Meal Plan work.

## 2. Codebase Exploration

Verified runtime contracts: `MealLogRepository.listByLocalDate`, `MealCategoriesRepository.read/upsert`, retained `MealCategoriesConfig.findById`, `MealDiaryDisplayPreferences`, `MealDiaryDateController`, canonical app repository providers, and Core `TioCard`.

T199-R3 closed category-label freshness with an optional confirmed-write change source. Codex-style review then found T199-R4: a `Future.wait` made Meal Categories availability gate a day already known to contain zero MealLog entries. The provider now establishes MealLog history first and returns the stable empty model before category resolution when no entries exist.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Unnamed Quick Add displays `Quick Add` | Owner-approved | Source is persisted; fallback stays presentation-only |
| Unnamed non-Quick-Add has no fabricated Quick Add title | Locked | Do not invent identity |
| Missing nutrients stay unknown | Locked | `NutritionSnapshot` distinguishes absent from zero |
| Diary ordering ignores category configured order | Locked | N4 is latest-actual-activity ordered |
| Category persistence refreshes active Diary history | Resolved | Section labels reflect current resolvable `displayName` while Diary remains mounted |
| Empty MealLog day does not require Meal Categories | Resolved | Category identity is only needed to render non-empty sections; N4 requires a stable empty-day state |
| Historical visible time does not use current-device `toLocal()` | Locked | Preserve logging context |

## 4. Architecture Design

### Chosen Approach

The selected-day history remains a feature `FutureProvider.autoDispose.family`. It first reads canonical MealLog entries for the requested persisted local date. An empty result returns immutable empty history immediately. Only a non-empty result subscribes to the optional `MealCategoriesChangeSource` and reads the retained Meal Categories configuration for section labels.

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

Confirmed category writes still self-invalidate non-empty active history. Failed writes emit no signal. There is no second category cache/store and no navigation dependency in Nutrition.

## 5. Implementation Plan

- [x] Selected-day immutable history request/read model and race-safe family provider.
- [x] Dynamic category grouping/order and nutrition aggregates.
- [x] Source-aware title fallback and historical offset-based time reconstruction.
- [x] Read-only governed card rendering + N14 presentation preferences.
- [x] Loading/empty/retryable error states.
- [x] Initial focused provider/widget tests and docs reconciliation.
- [x] T199-R3: emit confirmed category-write notification from canonical adapters and self-invalidate active Diary history.
- [x] Add focused category freshness and Supabase notification tests.
- [x] T199-R4: short-circuit known-empty MealLog history before category read/subscription.
- [x] Add regression test proving Meal Categories are not read for an empty day.
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

T199-R3 validated source: 539d85e06b674c1aff847cd71c4edbc1fc0f544c
Flutter CI #2410 / run 34663987536 / job 103472072070
Bootstrap PASS
Flutter analyze PASS
Dart analyze PASS
Flutter tests PASS
Dart tests PASS

Final validated source after T199-R4: c3546a48bf72cb4a9a69ae5d84663ae3c0f2b109
Flutter CI #2414 / run 34670534055 / job 103490968392
Bootstrap PASS
Flutter analyze PASS
Dart analyze PASS
Flutter tests PASS
Dart tests PASS

Final source scope audit:
main/base: 7a96e382d36d295f821826cb9d49fd38b0f533a9
merge base: exact base
branch: 30 ahead / 0 behind
changed files: 14, all within TNYX-199 scope
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Evidence / follow-up |
|---|---|---|---|---|
| T199-R1 | Medium | Resolved | Test notifiers were manually disposed in addition to ProviderScope ownership | fixed before CI #2395 |
| T199-R2 | Low | Resolved | Retry closure needed explicit nullable request narrowing | fixed before CI #2395 |
| T199-R3 | Medium | Resolved | Confirmed Meal Category changes did not invalidate already-mounted selected-day history, so section labels could remain stale | optional confirmed-write change source + provider self-invalidation + focused regression tests; CI #2410 green |
| T199-R4 | P2 | Resolved | Meal Categories availability could override a known-empty MealLog day | provider now returns empty before category read/subscription; focused regression asserts throwing categories repository is never read; CI #2414 green; inline review thread resolved |

## 7. Final Handoff

### Changed Files

The final source scope contains:

- TNYX-199 task brief and Meal Diary screen documentation;
- app composition for the canonical MealLog repository;
- Meal Diary selected-day history provider/read models;
- read-only history rendering/page integration;
- optional Meal Categories confirmed-write change-source contract;
- Supabase and in-memory change-source implementations;
- focused provider, widget, category-refresh, empty-day and change-source tests.

### Known Limitations

Quick Add create/save, edit/delete/move, card-to-editor navigation, detailed item/photo rendering, daily summary/rings and broader offline mutation/replay behavior remain deferred.

### Final Status

`REVIEW`
