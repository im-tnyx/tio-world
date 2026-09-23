# GitHub #321 Slice A — Core calendar selected-date fill

**Status:** In progress
**Primary owner:** `apps/core` reusable calendar (`TioDateCalendar`)
**Affected platforms:** Android + iOS phone (every `TioDateCalendar` consumer: Meal Diary, Workout Home shell)

## Owner Approval and Scope Boundary

**Trigger:** Unapproved product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:** Owner chat 2026-09-23 approved #321 Slice A for local implementation and validation only, after
the read-only readiness audit (`READY AFTER OWNER DECISION`). Owner decisions from the same session:

- D1: `TioDateFill` is not redesigned, recoloured, repurposed or removed. Selected + no feature fill renders the
  filled selection; selected + feature fill keeps the feature fill authoritative with the existing thin selection
  outline as the secondary cue.
- Fill colour (owner answer, supersedes the brief's "primary filled disk"/D2 `onPrimary` wording): the selected
  fill is a **gray tone only**, matching the owner's reference screenshot (`#212121` disk on black); **no other
  colour changes**, so numeral colours stay exactly as today (selected Sunday keeps full `danger`).
- D3: normal selected disk outer radius 13.0dp, zero gap to the progress band, independent of progress.
- Pixel-identity limitation accepted as a recorded known limitation (see Known Limitations).

**Active slice:** Slice A only.
**Slice B (anchored compact ↔ expanded transition):** deferred, not authorized.
**#317 (Meal Diary no-log progress ring):** separate, out of scope.

**Approved product/UI/data-shape boundaries:** selected-date visual treatment inside `_DateCirclePainter` only.
**Explicit non-changes:** cell size, progress radius/stroke/colour/track, `progress: null` vs `0`, numeral colours
and weights, marker row, weekday header, paging, expand/collapse, handle, visible-range reporting, `jumpToDate()`,
selected-date ownership, semantics, `TioDateFill` roles/geometry, Nutrition and Workout code. No Supabase change.

## Active Handoff

**Planning owner:** Owner (decisions above)
**Implementation owner:** Claude Code session on branch `tnyx/321-selected-date-fill`
**Review owner:** Owner visual review
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-23
**Branch:** `tnyx/321-selected-date-fill` (parent `main` @ `e5211e70480735ab839237653fc230fb0df5c15e`)
**HEAD SHA:** implementation commit `b08dc1a8cbc9aee741e8166692999df7b1345578`, followed by this handoff sync
**Observed working-tree state:** clean after commit
**Observed uncommitted/dirty files:** none
**PR / tracker:** PR #322 (Refs #321, Slice A only; #321 stays open for deferred Slice B). Linear not readable or
updatable programmatically here (only the Linear desktop GUI exists locally); TNYX-79 live state not re-read
**Current implementation state:** Slice A committed and pushed; owner visually approved the selected fill
(2026-09-23) — Slice A is UI-locked
**Relevant execution surface:** `apps/core/lib/src/ui/components/calendar/`
**Validation completed at SHA:** local suites on the `b08dc1a8` tree (see Validation Run)
**Validation remaining:** exact-head GitHub CI on PR #322
**Current blocker:** none
**Open review finding IDs:** none
**Next exact action:** watch PR #322 CI; merge only on explicit owner instruction; Slice B stays deferred

Process note: the painter edit was made before this brief existed, contrary to `AGENTS.md` ordering; the brief was
created before any further source change.

## Global UI / Design-System Guardrail

Read `apps/core/lib/src/theme/README.md` and `.ai/tasks/design-system-token-consolidation.md`. No new token,
role or palette access: the disk reuses `colors.primary` with `TioOpacity.opacity12`, both already consumed by this
component. Rendering outside the approved selected-date treatment stays pixel-identical.

## 1. Discovery

### User Outcome

A selected date reads as a filled gray-tone disk instead of a thin 0.5dp ring.

### Success Criteria

- selected + enabled + no feature fill → tonal disk r13, no 0.5dp ring, numeral colour unchanged;
- disk unchanged by `progress` null / `0` / positive; progress band 13–15 unchanged;
- selected + `TioDateFill` → feature fill r12.5 + 0.5dp ring exactly as before;
- disabled or neighbour-month selected cell → no disk, no ring, semantics still excluded;
- selected semantics unchanged.

### Scope

`tio_date_calendar.dart` painter + doc comments, `tio_date_decoration.dart` doc, Core calendar tests, theme
README calendar contract, `docs/screens/meal-diary.md` selection-ring wording, this brief.

### Non-Goals

Slice B, #317, `TioDateFill` redesign, numeral colour changes, unrelated stale-doc cleanup.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `tio_date_calendar.dart` (`_DateCell`, `_DateCirclePainter`), `tio_date_decoration.dart`,
  `tio_theme.dart` (`dark` → `TioColors.oled`, `tioDark` → `TioColors.dark`), `tio_colors.dart`, consumers
  `meal_diary_page.dart` (progress only) and `workout_home_page.dart` (no decorations).
- Existing pattern to follow: `TioDateFill.soft` tonal treatment (`primary @ opacity12`).
- Tests or validation already present: `tio_date_calendar_test.dart`, `tio_date_calendar_ring_geometry_test.dart`
  (the latter mapped `TioThemeMode.dark` to `TioColors.dark`; runtime resolves `TioColors.oled`).

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Selected fill = `primary @ TioOpacity.opacity12` | Made | owner asked for gray tone only; neutral in every theme (OLED `#232323` vs reference `#212121`); `surfaceVariant` rejected because high-contrast maps it to strong grays (textPrimary contrast 1.47 HC-dark, 2.04 HC-light) | owner + implementation |
| Numeral colours unchanged | Made | owner: no other colour change; supersedes the earlier D2 `onPrimary` proposal | owner |
| Selected + feature fill keeps fill r12.5 + 0.5dp ring | Made | D1 compatibility; pixels unchanged for that state | owner |
| Disk r13 = old ring outer edge | Made | D3 | owner |

## 4. Architecture Design

### Chosen Approach

`_DateCirclePainter` draws a tonal disk at `selectionRadius + selectionStroke / 2` when `isSelected && fill == null`,
and draws the 0.5dp ring only when `isSelected && fill != null`. `isSelected` already arrives as
`isSelected && isEnabled`, so disabled cells get neither.

### Ownership and Data Flow

```text
caller selectedDate -> _cellFor(isSelected, isEnabled) -> _DateCell -> _DateCirclePainter
```

### Alternative Rejected

Primary solid disk + `onPrimary` numeral (owner chose gray tone); `surfaceVariant` disk (fails high contrast).

### Failure and Accessibility States

Semantics untouched (`selected: true` + label). Measured pairs only, no WCAG claim: textPrimary on the disk is
Light 13.81, Dark 15.72, Tio Dark 11.94, HC-light 15.91, HC-dark 15.72; selected Sunday `danger` on the disk is
Light 3.76, Dark 5.68, Tio Dark 4.51, HC-light 3.66, HC-dark 5.68.

## 5. Implementation Plan

- [x] Painter: tonal disk for selected-without-fill; ring only with a feature fill
- [x] Doc comments in `tio_date_calendar.dart` and `tio_date_decoration.dart`
- [x] Tests: update selection-ring expectations, add state matrix, fix theme mapping, add Tio Dark / high contrast
- [x] Theme README calendar contract and `docs/screens/meal-diary.md`
- [x] Validation + local visual render

## 6. Quality Review

### Validation Run

```text
Tree: e5211e70 + uncommitted Slice A changes, Windows, local Flutter SDK (G:\dev\flutter-sdk)
apps/core   flutter test --no-pub <calendar_test> <ring_geometry_test>   PASS 71
            same two files against the pre-change painter (mutation check) 13 expected failures
apps/core   flutter analyze --no-pub                                       PASS no issues
apps/core   flutter test --no-pub                                          PASS 323
apps/features/nutrition  flutter test --no-pub                             PASS 872
apps/features/workout    flutter test --no-pub                             PASS 19
apps/app                 flutter test --no-pub                             PASS 354
repo        git diff --check                                               PASS
melos: not run; the global melos is 8.x while melos.yaml pins the CI version, so CI's per-package
commands were run directly for the affected packages. Full melos analyze/test across every package not run.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | | | | |

## 7. Final Handoff

### Changed Files

- `apps/core/lib/src/ui/components/calendar/tio_date_calendar.dart` — painter selection treatment + doc comments
- `apps/core/lib/src/ui/components/calendar/tio_date_decoration.dart` — layer/contract doc
- `apps/core/test/ui/components/tio_date_calendar_test.dart` — updated selection expectations, new
  `selected-date fill` group
- `apps/core/test/ui/components/tio_date_calendar_ring_geometry_test.dart` — runtime mode→palette mapping, Light/
  Dark/Tio Dark × high contrast, normal disk and compound-fill geometry
- `apps/core/lib/src/theme/README.md` — `TioDateCalendar` selection contract + known limitation
- `docs/screens/meal-diary.md` — two "inner selection ring" sentences
- `.ai/tasks/tnyx-321-selected-date-fill.md` — this brief

### Actual Behavior

- selected + enabled + no fill: `primary @ opacity12` disk r13, no 0.5dp ring, numeral colour/weight unchanged;
- progress band (track r14, 2dp, arc) unchanged; disk identical for `progress` null / `0` / positive;
- selected + `solid`/`soft`: fill r12.5 + 0.5dp `primary` ring at r12.75, pixel-identical to before;
- disabled, out-of-range and neighbour-month selected cells: nothing painted, semantics excluded (unchanged).

Local visual evidence (throwaway `matchesGoldenFile` harness, deleted; PNGs kept outside the repo): Light, Dark
and Tio Dark renders of selected only, selected + progress 0.6, selected + progress 0, selected + Today, selected +
Sunday, selected + solid vs solid, selected + solid + progress vs same, selected + soft vs soft. A before/after
pixel diff changed only the five plain-selected cells in every theme; compound-fill rows and all unselected cells
were pixel-identical.

### Known Limitations

- Selected-only (tonal disk r13) and an unselected `TioDateFill.soft` date with progress (soft disk r13) are
  pixel-identical; without progress they differ only by radius (13 vs 15). The pre-existing identity between
  selected + `solid` + progress and unselected `solid` + progress also remains. No production consumer supplies
  `fill` today; resolve before the first `TioDateFill` consumer (TNYX-79). Owner accepted this as recorded.
- Selected Sunday `danger` on the tonal disk measures 3.76 in Light (was 4.83 on the plain surface) because
  numeral colours were intentionally left unchanged.

### Final Status

`REVIEW` — implemented and locally validated; owner visually approved the selected-date gray fill on
2026-09-23 (Slice A UI-locked). Published as PR #322; remaining: exact-head GitHub CI and owner merge decision.
