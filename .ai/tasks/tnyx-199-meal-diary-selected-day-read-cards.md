# TNYX-199 — N4B Manual MealLog selected-day Diary sections & read-only cards

**Status:** In review
**Primary owner:** `apps/features/nutrition`
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Approval status:** Approved
**Approval evidence:** Owner approved the N4B selected-day read-only Diary slice and the source-aware `Quick Add` display-only fallback for unnamed Quick Add history.

**In scope:** selected-day canonical MealLog reads, dynamic Meal Category sections, compact read-only cards, N14 display preferences, loading/empty/error states, category-label freshness for already-mounted Diary history, focused tests, and Meal Diary documentation reconciliation.

**Explicit non-goals:** no Quick Add create/save activation, edit/delete/move, card-to-editor navigation, item-level detail/photos, N3 daily summary/calendar rings, Supabase schema/RLS/migration, Meal Category management-rule changes, or Meal Plan.

## Active Handoff

**Planning owner:** Current AI session
**Implementation owner:** None — implementation and review remediation complete
**Review owner:** PR/owner review
**Implementation ownership state:** Review handoff
**Branch:** `tnyx/tnyx-199-n4b-manual-meallog-selected-day-diary-sections-read-only`
**PR / tracker:** PR #258 ready for review; Linear TNYX-199 should be `In Review`
**Observed working-tree state:** API-only session; no local checkout modified.

**Final validated source:** `8f885db9ce9d5b21d6b636be3ba03726a433f19b`
**Behavior implementation source:** `ec6bb88d615639dc4dc01a09fa1961ab5cfe7a5a`
**Validation:** Flutter CI #2420 / run `34671967867` / job `103494920451` passed bootstrap, Flutter/Dart analyze, Flutter tests, and Dart tests.
**Validated source scope:** `main == 7a96e382d36d295f821826cb9d49fd38b0f533a9`; source is `36 ahead / 0 behind`, exact merge base, 14 TNYX-199-owned changed files.

**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** final PR/owner review. Merge still requires explicit owner authorization.

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
- conflict recovery that reloads a newer persisted category configuration refreshes that same Diary read model;
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

### Conflict-reload freshness

`SupabaseMealCategoriesRepository` emits immediately only after its own successful confirmed `upsert`. An integrity/concurrency rejection itself emits nothing. Instead, the adapter records that canonical state moved elsewhere; the next successful authenticated `read()` clears that pending observation and publishes a freshness event only after the newer canonical configuration has actually been decoded and confirmed.

This matches the existing `MealCategoriesController` conflict flow: rejected write → successful canonical reload → Settings adopts the newer configuration → the same mounted Diary provider self-invalidates and re-resolves current section labels. If conflict reload fails, no false freshness event is emitted. A later successful local upsert supersedes any pending conflict observation and publishes its normal single change event.

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
| Conflict reload of newer persisted category config refreshes active Diary history | Resolved — T199-R5 |

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
- [x] T199-R5 successful conflict-reload freshness signal/invalidation.
- [x] Regression: Diary `Lunch` → write conflict → controller reloads canonical `Midday` → same selected date shows `Midday`.
- [x] Direct adapter contract: rejected conflict emits zero events, successful recovery read emits exactly one, later ordinary read stays quiet.
- [x] Full CI and final scope audit after final coverage hardening.

## 5. Validation History

```text
Initial source: a25d53e5b6e857d737327fde94295c23a1b2be52
Flutter CI #2395 — PASS

T199-R3 source: 539d85e06b674c1aff847cd71c4edbc1fc0f544c
Flutter CI #2410 — PASS

T199-R4 source: c3546a48bf72cb4a9a69ae5d84663ae3c0f2b109
Flutter CI #2414 — PASS

T199-R5 behavior source: ec6bb88d615639dc4dc01a09fa1961ab5cfe7a5a
Flutter CI #2418 — PASS

Final validated source after direct signal-timing contract coverage:
8f885db9ce9d5b21d6b636be3ba03726a433f19b
Flutter CI #2420 / run 34671967867 / job 103494920451
Bootstrap PASS
Flutter analyze PASS
Dart analyze PASS
Flutter tests PASS
Dart tests PASS

Final source scope audit:
main/base: 7a96e382d36d295f821826cb9d49fd38b0f533a9
merge base: exact base
branch: 36 ahead / 0 behind
changed files: 14, all within TNYX-199 scope
```

## 6. Review Findings

| ID | Severity | Status | Finding |
|---|---|---|---|
| T199-R1 | Medium | Resolved | Test notifiers were manually disposed in addition to ProviderScope ownership |
| T199-R2 | Low | Resolved | Retry closure needed explicit nullable request narrowing |
| T199-R3 | Medium | Resolved | Successful confirmed Meal Category changes did not invalidate already-mounted selected-day history |
| T199-R4 | P2 | Resolved | Meal Categories availability could override a day already known to have zero MealLog entries |
| T199-R5 | P2 | Resolved | Conflict recovery could load a newer persisted Meal Categories config into Settings without invalidating already-mounted Diary history |

Both P2 inline review threads are resolved. The final review additionally hardened R5 with an explicit production-adapter signal-timing unit contract; this introduced no new behavior finding and passed full CI #2420.

## 7. Known Limitations / Final State

Quick Add create/save, edit/delete/move, card-to-editor navigation, detailed item/photo rendering, daily summary/rings and broader offline mutation/replay behavior remain deferred.

**Final status:** `REVIEW`.
