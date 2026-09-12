# TNYX-199 — N4B Manual MealLog selected-day Diary sections & read-only cards

**Status:** In progress
**Primary owner:** `apps/features/nutrition`
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Approval status:** Approved
**Approval evidence:** Owner approved the N4B selected-day read-only Diary slice and the source-aware `Quick Add` display-only fallback for unnamed Quick Add history.

**In scope:** selected-day canonical MealLog reads, dynamic Meal Category sections, compact read-only cards, N14 display preferences, loading/empty/error states, category-label freshness for already-mounted Diary history, focused tests, and Meal Diary documentation reconciliation.

**Explicit non-goals:** no Quick Add create/save activation, edit/delete/move, card-to-editor navigation, item-level detail/photos, N3 daily summary/calendar rings, Supabase schema/RLS/migration, Meal Category management-rule changes, or Meal Plan.

## Active Handoff

**Planning owner:** Current AI session
**Implementation owner:** None — review remediation is pending
**Review owner:** Current AI session + PR/owner review
**Implementation ownership state:** Reopened by final review
**Branch:** `tnyx/tnyx-199-n4b-manual-meallog-selected-day-diary-sections-read-only`
**PR / tracker:** PR #258 Draft; Linear TNYX-199 `In Progress`
**Observed working-tree state:** API-only session; no local checkout modified.

**Last validated implementation source:** `c3546a48bf72cb4a9a69ae5d84663ae3c0f2b109`
**Validation:** Flutter CI #2414 / run `34670534055` / job `103490968392` passed bootstrap, Flutter/Dart analyze, Flutter tests, and Dart tests.
**Validated source scope:** `main == 7a96e382d36d295f821826cb9d49fd38b0f533a9`; source was `30 ahead / 0 behind`, exact merge base, 14 TNYX-199-owned changed files.

**Current blocker:** `T199-R5` only.
**Open review finding IDs:** `T199-R5`.
**Next exact action:** close the conflict-reload freshness gap, add a focused regression test, rerun full CI, perform final scope/review audit, then return PR/Linear to review. Merge still requires explicit owner authorization.

**Repository note:** accidental unused sibling branch `tnyx/tnyx-199-n4b-manual-meallog-selected-day-diary-sections-read-only-check` remains untouched because deletion was not authorized.

## Global UI / Design-System Guardrail

Reuse existing `package:tio_core/core.dart` components and governed theme roles. No new Core component/token family or feature-local design-token catalog is introduced.

## 1. User Outcome / Success Criteria

The selected Diary date shows canonical persisted manual meals grouped under the current resolvable Meal Category label, ordered by latest actual activity, with compact read-only nutrition/time/note presentation.

Required behavior:

- selected date reads `MealLogRepository.listByLocalDate`;
- latest activity section first; newest entry first;
- retained archived category identity remains resolvable;
- persisted category rename/archive/reactivate refreshes already-mounted Diary section labels;
- conflict recovery that reloads a newer persisted category configuration must refresh that same Diary read model too;
- zero-entry day resolves to stable empty history without requiring Meal Categories;
- missing nutrients remain unknown rather than fabricated zero/partial authoritative totals;
- `Quick Add` fallback is source-aware and presentation-only;
- N14 preferences affect presentation only;
- loading/empty/retryable error and stale selected-date responses are handled.

## 2. Architecture

The selected-day history is a feature `FutureProvider.autoDispose.family` keyed by repository identity + persisted local date. It reads MealLog history first. If entries are empty, it returns immutable empty history immediately. Non-empty history reads retained Meal Categories and, when the repository implements `MealCategoriesChangeSource`, listens for confirmed category-change signals and self-invalidates.

```text
MealLogRepository.listByLocalDate(...)
        ↓
entries empty? ── yes ──→ stable empty history
        │ no
        ↓
MealCategoriesChangeSource (when supported)
        ↓
MealCategoriesRepository.read()
        ↓
resolve sections + current display labels
```

### T199-R5 gap

`SupabaseMealCategoriesRepository` currently emits `changes` only after its own successful `upsert`, which correctly avoids treating rejected/failed writes as persisted success. However, `MealCategoriesController` handles `MealCategoriesWriteConflict` by performing a successful repository `read()` and replacing its confirmed Settings state with the newer configuration already persisted by another writer. That successful conflict reload emits no change signal, so an already-mounted non-empty Diary provider can keep its cached old `MealCategory.displayName` while Settings shows the newer canonical label.

The remediation must notify/invalidate only after the conflict reload successfully observes newer canonical configuration; it must **not** emit merely because the rejected write failed.

## 3. Locked Semantics

| Decision | Status |
|---|---|
| Unnamed Quick Add displays `Quick Add` | Owner-approved |
| Unnamed non-Quick-Add has no fabricated Quick Add title | Locked |
| Missing nutrients stay unknown | Locked |
| Diary ordering ignores configured category order | Locked |
| Historical visible time does not use current-device `toLocal()` | Locked |
| Empty MealLog day does not require Meal Categories | Resolved |
| Successful local category persistence refreshes active Diary history | Resolved |
| Conflict reload of newer persisted category config refreshes active Diary history | Open — T199-R5 |

## 4. Implementation / Review Checklist

- [x] Selected-day immutable history request/read model and race-safe family provider.
- [x] Dynamic grouping/order and nutrition aggregates.
- [x] Source-aware title fallback and stored-offset historical time reconstruction.
- [x] Read-only governed card rendering + N14 presentation preferences.
- [x] Loading/empty/retryable error states.
- [x] T199-R3 successful category-write freshness signal + provider self-invalidation.
- [x] Supabase successful-write / failed-write notification tests.
- [x] T199-R4 stable empty-day short-circuit before category dependency.
- [x] Empty-day regression proving Meal Categories are not read.
- [ ] T199-R5 successful conflict-reload freshness signal/invalidation.
- [ ] Regression: Diary old label → write conflict → controller reloads newer config → same selected date shows newer label.
- [ ] Full CI and final scope/review audit after T199-R5.

## 5. Validation History

```text
Initial source: a25d53e5b6e857d737327fde94295c23a1b2be52
Flutter CI #2395 — PASS

T199-R3 source: 539d85e06b674c1aff847cd71c4edbc1fc0f544c
Flutter CI #2410 — PASS

T199-R4 source: c3546a48bf72cb4a9a69ae5d84663ae3c0f2b109
Flutter CI #2414 — PASS
Bootstrap PASS
Flutter analyze PASS
Dart analyze PASS
Flutter tests PASS
Dart tests PASS
```

CI #2414 remains valid for the R4 source, but it does not cover T199-R5. A fresh exact-source CI run is required after remediation.

## 6. Review Findings

| ID | Severity | Status | Finding |
|---|---|---|---|
| T199-R1 | Medium | Resolved | Test notifiers were manually disposed in addition to ProviderScope ownership |
| T199-R2 | Low | Resolved | Retry closure needed explicit nullable request narrowing |
| T199-R3 | Medium | Resolved | Successful confirmed Meal Category changes did not invalidate already-mounted selected-day history |
| T199-R4 | P2 | Resolved | Meal Categories availability could override a day already known to have zero MealLog entries |
| T199-R5 | P2 | Open | Conflict recovery can load a newer persisted Meal Categories config into Settings without invalidating the already-mounted Diary history, leaving section labels stale |

GitHub inline review for T199-R5 is open on PR #258. The PR was returned to Draft and Linear TNYX-199 returned to `In Progress`.

## 7. Known Limitations / Final State

Quick Add create/save, edit/delete/move, card-to-editor navigation, detailed item/photo rendering, daily summary/rings and broader offline mutation/replay behavior remain deferred.

**Final status:** `PARTIAL` until T199-R5 is resolved and revalidated.
