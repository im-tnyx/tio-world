# TNYX-55 — N2 Reusable inline date calendar + Meal Diary first consumer

**Status:** In progress — latest calendar/top-bar visual corrections implemented; focused Flutter validation unavailable; awaiting owner UI acceptance
**Primary owner:** `apps/core` (reusable calendar) + `apps/features/nutrition` (Meal Diary adapter)
**Affected platforms:** Flutter phone (`apps/app`, `apps/core`, `apps/features/nutrition`)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice | Unapproved product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:** Owner-approved direction recorded on Linear TNYX-55 (re-read at
`updatedAt 2026-09-04T12:25:10Z`, status `Todo`, title "N2 — Reusable inline date calendar (horizontal strip +
expandable month)"). Sections "Current first consumer" and "Owner clarification — calendar family, global
preference & future safety" are authoritative: build the reusable core calendar now and wire the same
component into the Meal Diary date-navigation surface as its first actual consumer. N0 readiness (TNYX-66)
result for this slice is `READY for TNYX-55`.

**UI acceptance gate:** owner-imposed. Automated tests verify behaviour and regressions; they do not grant
visual acceptance. The earlier implementation was validated, but the latest visual corrections remain
`IMPLEMENTED, AWAITING FOCUSED VALIDATION + OWNER UI ACCEPTANCE`. Pixel geometry is not frozen. Visual
refinements the owner requests after review stay inside TNYX-55 when they refine the already-approved calendar
interaction.

**Owner refinement evidence (2026-09-04):** the owner explicitly removed the expanded calendar's centred
month title and left/right arrow controls. Horizontal paging remains the only previous/next interaction in
both renderings: week-by-week when compact and month-by-month when expanded. The owner also approved a
calendar action that returns Meal Diary to Today and is visible only while another date is selected. The
action belongs immediately to the left of the right-anchored streak status so its appearance never moves the
streak. Its visible glyph follows the owner-supplied `ic_calendar_new.xml` vector reference rather than the
Material calendar glyph. Weekday labels follow the supplied three-letter reference (`SUN`, `MON`, …) rather
than single letters.

**Owner visual correction (2026-09-04):** the first top-bar refinement left too much visible distance between
the calendar action and the streak, and the calendar handle still incorrectly painted the entire notch as a
solid tab. The fixed contract is: keep the visible streak icon at the same right-side position, remove the
extra leading status padding only while the calendar action is present, and leave the centered notch
transparent. Because the calendar action exists only for a non-Today selection, its calendar body also shows
the currently selected day number while the action continues to mean “return to Today”.

**Owner handle reference correction (2026-09-05):** the later supplied crop supersedes the earlier small
64x10 cut and 36x4 grabber interpretation. The approved handle is a wide, sharp-sided trapezoid cut into the
calendar bottom edge: 200dp outer width, 160dp flat inner edge and 20dp depth, with a centered 160x14 rounded
grabber. The existing 48dp handle touch target and tap/vertical-drag behavior remain unchanged.

**Owner motion/icon correction (2026-09-05):** compact and expanded first-row dates must share the same
vertical position throughout the expansion transition; the month rendering must not jump upward as it fades
in. The conditional top-bar calendar action always displays Today's day number, not the selected historical
day, because the action's destination is Today. Visibility and tap behavior remain unchanged.

**Superseded owner grabber-size correction (2026-09-05):** the transparent trapezoid geometry remains 200dp outer /
160dp inner / 20dp deep, but the visible 160x14 grabber is too large. Halve only its width to 80dp and set its
height to 10dp. Keep it centered, pill-shaped, alpha-50, and retain the 200x48 interaction target.

**Owner Sunday-color correction (2026-09-05):** match the verified `Tio-hub` calendar behavior: the localized
`SUN` header and Sunday date numerals use the semantic danger/error color. Normal Sundays are softened;
selected or Today Sundays use full danger. A solid completed-day fill keeps `onPrimary` numeral contrast.

**Owner weekday-header Today correction (2026-09-05):** Today's emphasis must reach the shared weekday header,
not only the date numeral. Exactly one column is emphasised — the column carrying `localToday` — so with Today on
a Saturday the 5th, both `SAT` and `5` read strong while the other six columns stay muted. Today weekday emphasis
is shown only while `localToday` belongs to the active visible calendar range. Paging away removes that emphasis;
returning to Today restores it. Selection never controls the header emphasis. The emphasis is never moved to
another weekday because the reader scrolled, and is never derived from `selectedDate` or from the midpoint
`visibleMonth`. A Sunday Today keeps the semantic danger color and only loses its muting; when Today is off
screen every column, Sunday included, returns to its ordinary styling. Core resolves visibility from the same
active-range truth that feeds `onVisibleDateRangeChanged`, so the header and the top-bar month label can never
disagree about what is visible.

**Superseded owner cut-size correction (2026-09-05):** reducing only the visible grabber left the transparent cut too
large. Preserve the reference's 1.25 outer-to-inner width ratio while fitting the 80dp grabber: reduce the cut
from 200/160/20 to 100dp outer / 80dp inner / 14dp deep. Keep the grabber at 80x10 and the touch height at 48dp.

**Owner outside-tap correction (2026-09-05):** while the month rendering is expanded, a pointer interaction
anywhere outside the calendar collapses it back to the compact week rendering. Interactions inside the
calendar remain owned by dates, horizontal paging and the handle and must not trigger this dismissal.

**Owner viewport/Today correction (2026-09-05):** the top-bar Today action is visible whenever either the
selected date is not Today or the currently paged calendar range does not contain Today. Activating it performs
both resets as needed: select Today and command the calendar viewport back to Today's week/month. A generic
Core visible-range callback reports navigation; Nutrition owns the feature-specific action visibility rule.

**Superseded owner handle sizing (2026-09-05):** the owner directly set the source geometry to an 80dp outer /
60dp inner / 8dp deep transparent cut and a centered 60x4 grabber. This supersedes the earlier 100/80/14 cut
and 80x10 grabber decisions; the invisible interaction height remains at least 48dp.

**Superseded owner radius correction (2026-09-05):** the 60x4 grabber is a true pill with a 2dp radius on every corner.
Implement it as declarative box geometry and verify the resolved `BorderRadius`; merely matching the outer size
or leaving radius behavior implicit is not sufficient.

**Owner selection-ring correction (2026-09-05):** the 1.5dp outer selected-date ring reads too heavy. The owner
directly set that ring to the governed 0.5dp stroke; keep the 28dp circle and the independent 2dp progress ring
unchanged. This supersedes the intermediate 1dp interpretation.

**Latest owner handle sizing (2026-09-05):** retain the 80dp outer and 60dp inner notch widths, reduce notch
depth to 6dp, and use a centered 60x3 grabber. The grabber remains a true pill with the radius derived as half
its height (`1.5dp`), while the invisible interaction height remains at least 48dp.

**Approved product/UI/data-shape boundaries:**

- new reusable Core component `TioDateCalendar`, the inline date calendar: a compact horizontal strip and an
  expandable inline month grid as two renderings of one selected date, joined by the centered notch handle.
  `horizontal` describes the compact rendering, not the component's identity;
- neither rendering includes a month title or previous/next arrows; horizontal swipe pages compact by week
  and expanded by month;
- `/nutrition` primary shell branch changes from `TioShellPlaceholder` to a Nutrition-owned Meal Diary surface
  that renders the calendar plus an honest empty selected-date state;
- the Nutrition root top bar shows a calendar-shaped Today action immediately left of the fixed streak status
  when Meal Diary is not selected on `localToday` or the visible calendar range does not contain Today; it has
  no redundant visual gap from the streak, and tapping it resets both selection and viewport to Today;
- no Supabase table/column change of any kind.

**Explicit non-changes:**

- no `NutritionSnapshot`, `MealLogEntry`, `MealLogItemSnapshot`, Add Food, Food Search, AI parsing, barcode, Meal Editor;
- no daily nutrition summary, meal groups, Quick Add, streaks, targets surface;
- no Workout adapter/screen, `TrainingPlan`, `PlannedWorkout`;
- no Diet Plan UI, `MealPlan`, `PlannedMeal`, `Day x/y`, `Week x/y`;
- no Planning Calendar, no Progress Calendar;
- no Calendar Preferences Settings UI (TNYX-72), and no feature-owned week-start state of any kind
  (`nutritionFirstDayOfWeek` and equivalents are forbidden; week start is one app-wide value);
- no Planning Calendar and no Progress Calendar, and no pre-generalizing of `TioDateCalendar` into a universal
  calendar to accommodate them;
- no empty future Workout/Meal Plan folders;
- no unrelated stale-doc cleanup (for example the legacy `backend/*` rows in `docs/MODULE_OWNERSHIP.md`).

## Active Handoff

**Planning owner:** N0 audit (TNYX-66)
**Implementation owner:** this slice
**Review owner:** Not applicable
**Implementation ownership state:** Complete — owner UI acceptance received
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-04 after owner refinement validation
**Branch:** `main`
**HEAD SHA:** `6853d30dcec790ecd6eae0afd90fdf0bc6977fd9`
**Observed working-tree state:** dirty TNYX-55 working tree on `main`; nothing committed
**Observed uncommitted/dirty files:** the TNYX-55 calendar/Meal Diary source, tests, manifests, lockfiles, docs and task brief listed in Final Handoff
**PR / tracker:** Linear TNYX-55; no PR created (not authorized in this task)
**Current implementation state:** latest owner refinements implemented (no month title/arrows, working week/month swipe with visible-range reporting, outside-tap collapse, stable compact/month first-row position, three-letter weekday labels with semantic-danger Sundays, 0.5dp selected-date ring, conditional Today/viewport action with Today's day number, close fixed-position streak composition, and the owner-set 80/60/6 transparent trapezoid with a 60x3 grabber); latest focused Flutter validation unavailable
**Relevant execution surface:** `apps/core/lib/src/ui/components/calendar`, `apps/features/nutrition` presentation, `apps/app/lib/app/router.dart`
**Validation completed at SHA:** final working tree over `6853d30d`; nothing committed
**Validation remaining:** focused Core/App tests for the latest handle/top-bar/icon corrections, owner UI acceptance on real UI; `melos` remains blocked by the recorded tooling mismatch
**Current blocker:** no `flutter` executable is available in either the normal or approved external shell for this turn
**Open review finding IDs:** none
**Next exact action:** owner reviews the rendered Meal Diary calendar and accepts or requests a bounded visual refinement

## Global UI / Design-System Guardrail

Read `.ai/tasks/design-system-token-consolidation.md` and `apps/core/lib/src/theme/README.md`.
The calendar consumes governed primitives (`TioSize`, `TioSpacing`, `TioRadius`, `TioStroke`,
`TioOpacity`, `TioFontWeight`) and runtime roles (`context.tioColors`, `context.tioMotion`,
`Theme.of(context).textTheme`). No component-token file is created: the theme README component-token
admission gate allows small reusable components to consume primitives directly, and no stable
component-level visual contract is proven yet.

## 1. Discovery

### User Outcome

On the Nutrition tab the user sees a compact horizontal date strip, can scroll and select a past date or
today, can drag or tap a centered handle to expand an inline month grid on the same screen, and cannot reach a
future date. The same component is reusable by Workout and Meal Plan later without changing Core.

### Success Criteria

- reusable `TioDateCalendar` lives in `apps/core` and imports no feature package;
- Meal Diary is its first actual production consumer, reachable through the existing `/nutrition` shell branch;
- compact and month renderings share one caller-controlled `selectedDate`;
- compact pages horizontally by week and expanded pages horizontally by month, with no month title or arrow controls;
- weekday labels use localized three-letter abbreviations;
- the Nutrition Today action appears immediately left of the fixed right-side streak only off Today, uses the
  owner-supplied calendar glyph, and selects Today when pressed without shifting the streak;
- `maxDate = localToday` in Meal Diary; Core itself never forbids future dates;
- missing progress stays distinct from `0.0`; no nutrition data is fabricated;
- gesture: horizontal strip scroll, handle tap/drag toggles mode, page vertical scroll never toggles it.

### Scope

1. Core reusable calendar (compact strip, notch/handle, inline month grid, generic decorations).
2. Meal Diary first-consumer integration (thin Nutrition-owned date state).
3. Tests plus affected documentation.

### Non-Goals

See "Explicit non-changes" above.

## 2. Codebase Exploration

### Verified Evidence

- Source and config inspected at `6853d30d`:
  - no calendar implementation exists anywhere. Repo-wide search for `TioDateCalendar`, `DateCalendar`,
    `CalendarPreferences`, `firstDayOfWeek`, date strip, calendar strip, month grid and week calendar returns
    no production hit. `selectedDate` appears only in `tio_dob_picker_bottom_sheet.dart` (DOB wheel) and
    onboarding `age_screen.dart`. No duplicate risk and no conflicting active work.
  - `apps/core/lib/src/ui/components/<family>/<family>.dart` barrel convention, re-exported from
    `components.dart`. `TioSelectableCard` (#204) is the most recent example.
  - `apps/app/lib/app/router.dart` `_shellBranchPage` returns `HomePage()` for `ShellTab.home` and
    `TioShellPlaceholder` otherwise, so `/nutrition` is the live reachable Nutrition surface and is a
    placeholder today. `docs/screens/meal-diary.md` records "No route exists yet".
  - `apps/features/nutrition` contains Settings pages only. No diary, no MealLog, no NutritionSnapshot.
    Its pubspec already depends on `tio_core`, `flutter_riverpod` and `go_router`.
  - `apps/shared` has no Flutter dependency and stays Flutter-free.
  - no localization infrastructure exists (`flutter_localizations`, `intl`, `.arb` and
    `localizationsDelegates` are all absent), so `MaterialLocalizations.of(context)` is the correct locale
    seam and adds no dependency.
  - `apps/app/test/app/app_mode_router_test.dart` asserts `find.text('Nutrition')`, which resolves to the
    bottom-navigation label in `tio_shell.dart` rather than the placeholder body, so replacing the
    placeholder is safe.
  - `apps/core/test/theme/final_enforcement_visual_ownership_test.dart` scans `apps/app/lib/app` and every
    `apps/features/*/lib/src/presentation` outside `/controllers/` for raw colors, raw `FontWeight.wNNN`,
    numeric `fontSize`, numeric `letterSpacing`, numeric alpha and numeric millisecond durations. New
    feature and app code must stay clean of all of those.
- Existing pattern to follow: `TioSelectableCard` component style and the `HomePage` root-page precedent.
- Tests or validation already present: `apps/core/test/ui/components/*_test.dart` widget tests. The
  repository has no golden and no integration test infrastructure.

### Docs and runtime conflicts recorded, not silently followed

- `.ai/CURRENT.md` is stale (last verified 2026-08-23, frozen SHA `f95ddf7c`) and was not used as readiness
  evidence.
- `docs/MODULE_OWNERSHIP.md` still lists `future backend/api`, `future backend/ai-coach`, `future backend/jobs`
  and `future supabase/`, contradicting `AGENTS.md` and ADR-0007. Out of scope here and recorded as a follow-up.
- `docs/screens/meal-diary.md` and `docs/screens/nutrition.md` disagree on whether Meal Diary is a nested route
  or a section of the `/nutrition` root. This slice delivers it on the `/nutrition` root branch and both docs
  are reconciled to that delivered fact.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Reusable calendar owner is `apps/core` | Made | `docs/MODULE_OWNERSHIP.md`: core owns reusable Flutter UI and must not import feature packages | TNYX-54 and repo docs |
| First consumer surface is the `/nutrition` shell branch | Made | It is the only reachable Nutrition surface; `HomePage` is the existing root-page precedent; a new nested route would be unreachable | this slice |
| Per-date decoration is a builder callback, not a `Map<DateTime, ...>` | Made | `DateTime` equality includes time, so raw date-key maps are easy to misuse | this slice |
| `progress == null` means unavailable and `0.0` means actual zero | Made | TNYX-55 acceptance, enforced by an explicit test | TNYX-55 |
| `localToday` is caller-supplied and Core never calls `DateTime.now()` for date policy | Made | preserves the future TNYX-114 local-date and timezone resolver seam | TNYX-55 and TNYX-114 |
| `resolvedFirstDayOfWeek` is a nullable Core parameter defaulting to `MaterialLocalizations.firstDayOfWeekIndex` | Made | TNYX-72 now supplies the Settings-owned resolved value from app composition; standalone callers retain the generic locale fallback and no feature-local preference is created | TNYX-72 |
| No component-token file | Made | the theme README component-token admission gate is not met yet | theme README |
| Month grid is non-scrollable | Made | removes every nested vertical-scroll conflict, so only the handle owns vertical drags | this slice |
| Meal Diary history window is `localToday` minus 365 days | Made | a bounded honest default until real MealLog history exists, replaceable by the N20 slice | this slice |
| Meal Diary forwards the generic `resolvedFirstDayOfWeek` supplied by app composition | Made | week start is one app-wide Settings value; Nutrition consumes it without persisting, resolving or caching a second preference. Direct standalone callers may still pass null for Core's locale fallback | TNYX-72 |
| The handle uses Core primitives rather than another component's token class | Made | importing `TioAvatarActionSheetTokens` would couple unrelated components; the owner-provided crop now supplies the calendar-specific geometry | this slice |
| Date helpers stay private to the calendar file | Made | TNYX-73 says later calendar slices should audit what this implementation actually proved reusable and extract then, rather than this slice pre-extracting a shared foundation nobody consumes | TNYX-73 |
| Expanded navigation has no title or arrow row | Made | owner UI review explicitly removed the centred month and both arrows; month `PageView` swipe remains | owner refinement 2026-09-04 |
| Today action is a Nutrition-owned command composed before the shell's fixed status | Made | returning to Today is feature policy; placing the optional action before the right-anchored streak prevents the streak from shifting when the action appears | owner refinement 2026-09-04 |
| Today action glyph uses the supplied calendar vector | Made | the owner rejected the Material calendar glyph and supplied `ic_calendar_new.xml`; Tio-World owns a Flutter SVG conversion of that geometry rather than depending on a sibling repository at runtime | owner refinement 2026-09-04 |
| Calendar action removes redundant distance without moving the streak | Made | when the optional action exists, only the status cluster's leading padding is removed; its right padding and visible streak icon position remain unchanged | owner correction 2026-09-04 |
| Handle follows the owner-supplied wide trapezoid reference | Superseded | the later direct owner sizing replaces this wide geometry | owner correction 2026-09-05 |
| Calendar action displays the selected day number | Superseded | the later owner correction requires the action to display its Today destination instead | owner correction 2026-09-04 |
| Weekday labels use `intl` short weekday formatting in Core | Made | Flutter `MaterialLocalizations` exposes only localized single-letter `narrowWeekdays`; the approved reference requires localized three-letter labels | owner refinement 2026-09-04 |
| Expanded first-row dates preserve compact vertical position | Made | the compact row centers its date content 3dp lower than the month row; a month-only derived 3dp top inset removes the cross-fade jump without changing date-cell geometry | owner correction 2026-09-05 |
| Calendar action displays Today's day number | Made | the action is a conditional return-to-Today command, so its visible date describes its destination rather than echoing the selected historical date; this supersedes the 2026-09-04 selected-day decision | owner correction 2026-09-05 |
| Visible grabber is 80x10 inside the existing trapezoid | Superseded | the owner later directly set the source grabber to 60x4 | owner correction 2026-09-05 |
| Sunday label and numerals use semantic danger styling | Made | verified against `G:/projects/Tio-hub/apps/core/.../TnyxWeeklyCalendar.kt`: normal Sundays are softened, highlighted Sundays are full error, and completed fills retain `onPrimary` numeral contrast | owner correction 2026-09-05 |
| Transparent cut scales down with the 80x10 grabber | Superseded | the owner later directly set the source cut to 80dp outer / 60dp inner / 8dp deep | owner correction 2026-09-05 |
| Expanded calendar collapses on outside interaction | Made | Core owns its expanded state and boundary, so a `TapRegion` dismissal belongs in the reusable component; inside date/pager/handle interactions stay within the region | owner correction 2026-09-05 |
| Today action observes selection and viewport independently | Made | page navigation does not change the controlled selection, so Core reports a generic visible date range and Nutrition combines `!isOnToday || !isTodayVisible`; the action then selects and jumps to Today | owner correction 2026-09-05 |
| Handle uses the owner's direct 80/60/8 and 60x4 geometry | Superseded | the owner later reduced the notch depth and grabber height | owner correction 2026-09-05 |
| Grabber owns an explicit 2dp all-corner radius | Superseded | the latest 3dp height derives a 1.5dp pill radius | owner correction 2026-09-05 |
| Selected-date ring uses a 1dp stroke | Superseded | the owner directly set the latest source value to 0.5dp | owner correction 2026-09-05 |
| Selected-date ring uses a 0.5dp stroke | Made | the owner's direct source value is authoritative; the ring diameter and separate 2dp progress stroke remain unchanged | owner correction 2026-09-05 |
| Handle uses the owner's latest 80/60/6 and 60x3 geometry | Made | source values are owner-authored; the derived 1.5dp all-corner radius and 48dp touch height keep the grabber pill-shaped and accessible | owner correction 2026-09-05 |

### Dependency decisions

| Issue | Classification |
|---|---|
| TNYX-66 (N0 gate) | hard blocker, satisfied, result `READY for TNYX-55` |
| TNYX-54 (N1) | soft dependency, the N2-relevant N1 decisions are frozen and corroborated by repo docs, no longer a blocker for this slice |
| TNYX-72 (first day of week) | soft dependency, seam only, Settings UI out of scope |
| TNYX-114 (local date and timezone) | soft dependency, mitigated by caller-supplied `localToday` |
| TNYX-73 (Planning and Progress boundary) | related only |
| TNYX-79, TNYX-86, TNYX-94, TNYX-99 | future consumers |

## 4. Architecture Design

### Chosen Approach

```text
apps/core/lib/src/ui/components/calendar/
├─ calendar.dart                          barrel
├─ tio_date_calendar.dart                 controller + widget + private cell and painter
├─ tio_date_calendar_display_mode.dart    compact | month
└─ tio_date_decoration.dart               generic decoration, TioDateFill, builder typedef
```

The Core API is domain-neutral: `selectedDate`, `localToday`, `minDate`, `maxDate`,
`resolvedFirstDayOfWeek`, `displayMode`, `allowExpansion`, `onDateSelected`, `onDisplayModeChanged`,
`controller.jumpToDate(date)` and `decorationBuilder`. `selectedDate` is strictly controlled: the widget
never mutates it, so there is exactly one selected-date truth and it belongs to the caller.

Layers stay independent per cell: outer selection ring, inner progress ring, centre generic fill, date label
with bold emphasis for `localToday`, and marker dots below. Selection is never reused as progress or
completion.

### Ownership and Data Flow

```text
MealDiaryPage (Nutrition)
  -> mealDiarySelectedDateProvider (Nutrition controller)
  -> TioDateCalendar(selectedDate, localToday, minDate, maxDate = localToday, onDateSelected)
     Core renders. Core imports no feature package.
```

### Alternative Rejected

A new nested `/nutrition/diary` route. Nothing would navigate to it while `/nutrition` is a placeholder, so
the component would ship without a production consumer, which is exactly the outcome the approved direction
forbids.

### Failure and Accessibility States

No nutrition data exists, so `decorationBuilder` returns `null` for every date and no progress, fill or
markers are drawn. Every in-range date exposes a `Semantics` node with a localized full-date label, Today
emphasis and selected state. Out-of-range dates render as empty placeholders and are not interactive.
Meaning is never carried by colour alone. The handle hit area is at least 48dp tall.

## 5. Implementation Plan

- [x] Core: `tio_date_calendar_display_mode.dart`
- [x] Core: `tio_date_decoration.dart`
- [x] Core: `tio_date_calendar.dart`
- [x] Core: `calendar/calendar.dart` barrel and `components.dart` export
- [x] Core tests: `apps/core/test/ui/components/tio_date_calendar_test.dart`
- [x] Nutrition: `meal_diary_date_controller.dart`, `meal_diary_page.dart`, `pages.dart` export
- [x] Nutrition tests: `apps/features/nutrition/test/presentation/meal_diary_page_test.dart`
- [x] App: wire `ShellTab.nutrition` to `MealDiaryPage` in `router.dart`, including the conditional Today action
- [x] Core/App refinement: keep streak right-anchored, place Today action to its left and use the supplied glyph
- [x] Core/App visual correction: remove the redundant action/streak gap while keeping the streak fixed
- [x] Core calendar reference correction: wide transparent trapezoid with a distinct centered 160x14 grabber
- [x] App visual correction: render the selected day number inside the conditional calendar action
- [x] Core motion correction: keep compact and expanded first-row dates at the same vertical coordinate
- [x] App icon correction: render Today's day number inside the conditional calendar action
- [x] Core grabber-size correction: 80x10 pill inside the existing transparent trapezoid
- [x] Core Sunday-color correction: semantic danger for `SUN` and Sunday numerals with reference precedence
- [x] Core cut-size correction: 100/80/14 transparent trapezoid around the 80x10 grabber
- [x] Core outside-tap correction: expanded month collapses while inside calendar interactions remain active
- [x] Core viewport contract: report the visible week/month range after user and programmatic paging
- [x] Nutrition/App Today correction: show for off-Today selection or viewport and reset both on activation
- [x] Core superseded handle sizing pass: 80/60/8 transparent cut around a centered 60x4 grabber
- [x] Core superseded radius pass: explicit/tested 2dp all-corner pill radius
- [x] Core selection-ring correction: reduce only the outer selected-date stroke from 1.5dp to 0.5dp
- [x] Core latest handle correction: 80/60/6 transparent cut around a centered 60x3 grabber with 1.5dp radius
- [x] Docs: `docs/screens/meal-diary.md`, `docs/screens/nutrition.md`, `docs/MODULE_OWNERSHIP.md`, `apps/core/lib/src/theme/README.md`
- [x] Baseline validation before the latest owner visual corrections
- [x] Focused Flutter validation for the latest owner visual corrections
- [x] Workspace-wide validation after the `intl` dependency was introduced

## 6. Quality Review

### Validation Run

Run at working tree on top of `6853d30d` (nothing committed).

```text
flutter pub get   Core, Nutrition and App: passed

flutter analyze
  Core:      No issues found
  Nutrition: No issues found
  App:       No issues found

flutter test
  Core:      218 passed, 0 failed
  Nutrition: 187 passed, 0 failed
  App:       270 passed, 0 failed

Focused behavior evidence included in those suites:
  calendar: 24 passed (week/month swipe, no title/arrows, three-letter labels,
            compact width/large text, controlled selection and accessibility)
  Meal Diary: 7 passed (range, honest empty state and Today controller)
  shell top bar: 11 passed (generic optional action, compact width/large text)
  router: conditional Today action integration passed

git diff --check   clean
```

UI-level audit re-run (2026-09-05), whole workspace:

```text
flutter pub get   16/16 packages resolved
flutter analyze   16/16 packages: No issues found
flutter test      1715 passed, 0 failed
  core 222 · shared 38 · app 270 · wear 9 · account_setup 38 · auth 159
  home 1 · nutrition 188 · onboarding 450 · profile 59 · progress 51
  settings 204 · splash 12 · workout 14
  calendar suite: 28 passed
git diff --check  clean
```

Three defects were found by that run and fixed inside this slice:

1. `intl` had been added to `apps/core` without re-resolving the packages that
   depend on it, so seven packages failed to compile their tests. Fixed by
   running `flutter pub get` across the workspace; the affected `pubspec.lock`
   files are part of this diff.
2. `_applyMode` never re-reported the visible range, so switching to the month
   grid left the caller holding the previous week. `shouldShowTodayAction`
   reads that value, so the Today action could show or hide against a page
   nobody was looking at. Mode changes now schedule a report.
3. The week pager reported its own page changes while the month grid was on
   screen — both pagers stay mounted through the expand animation and moving
   one moves the other — overwriting the month range with a week. Each pager
   now reports only while its own rendering is active.

Also removed: an unnecessary `package:flutter/gestures.dart` import, and a
first-row top inset in the month grid that over-corrected the alignment it was
meant to hold.

Latest owner top-bar refinement validation (2026-09-04):

```text
git diff --check                           clean
calendar SVG XML parse                     passed (24x24 viewBox, 1.3 stroke)
stale trailing-action/top-right references none in current source/docs/task brief
handle source contract                       superseded by the owner reference correction dated 2026-09-05
top-bar source contract                      passed (action first, no redundant leading gap, fixed right padding)
selected-day icon source contract            superseded by the owner correction dated 2026-09-05
flutter focused tests                      unavailable: `flutter` is not recognized in either
                                           the normal shell or the approved external shell
dart format                                unavailable: `dart` is not recognized in the shell
```

Owner handle reference validation (2026-09-05):

```text
git diff --check                           clean
handle source contract                     passed (200 outer / 160 inner / 20 deep sharp trapezoid,
                                                   separate centered 160x14, 8-radius, alpha-50 grabber)
narrow-width source contract               passed (outer width, inner width and depth clamp to surface bounds)
focused Core widget test source            updated (200dp handle width, 160x14 grabber, centered at 3dp inset)
flutter focused tests                      unavailable: neither `flutter` nor the known local SDK path exists
dart format                                unavailable: `dart` is not on `PATH`
```

Owner expansion/icon correction validation (2026-09-05):

```text
git diff --check                           clean
first-row position source contract         passed (derived 3dp month-only top inset)
first-row focused widget test source       added (same first-row date has equal compact/expanded top coordinate)
Today glyph source contract                passed (`localToday.day`; stale selected-day key absent)
Today glyph focused app test source        updated (Today number present; historical number absent)
flutter focused tests                      unavailable: neither `flutter` nor the known local SDK path exists
dart format                                unavailable: `dart` is not on `PATH`
```

Owner grabber-size correction validation (2026-09-05):

```text
git diff --check                           clean
grabber source contract                    passed (80x10, radius = height / 2, alpha-50)
focused Core widget test source            updated (80x10 size, centered with 5dp vertical inset)
trapezoid/touch target                     superseded by the owner cut-size correction below
flutter focused tests                      unavailable: neither `flutter` nor the known local SDK path exists
dart format                                unavailable: `dart` is not on `PATH`
```

Owner Sunday/cut correction validation (2026-09-05):

```text
git diff --check                           clean
Sunday source contract                     passed (`SUN` alpha-140 danger; normal numeral alpha-179 danger;
                                                   selected/Today full danger; solid fill `onPrimary`)
Sunday focused widget test source          added (header, normal, highlighted and solid-fill precedence)
cut/grabber source contract                passed (100 outer / 80 inner / 14 deep; 80x10 centered grabber)
handle focused widget test source          updated (100dp width, 48dp minimum height, 2dp visual inset)
flutter focused tests                      unavailable: neither `flutter` nor the known local SDK path exists
dart format                                unavailable: `dart` is not on `PATH`
```

Owner outside-tap correction validation (2026-09-05):

```text
git diff --check                           clean
outside-tap source contract                passed (`TapRegion`, month/allowExpansion guard, notified compact mode)
focused Core widget test source            added (outside tap collapses; inside date tap does not collapse)
flutter focused tests                      unavailable: neither `flutter` nor the known local SDK path exists
dart format                                unavailable: `dart` is not on `PATH`
```

Owner viewport/Today correction validation (2026-09-05):

```text
git diff --check                           clean
Core visible-range source contract         passed (inclusive week/month callback, initial report,
                                                   duplicate suppression, user/programmatic page reporting)
Nutrition action-state source contract     passed (`!isOnToday || !isTodayVisible`)
Today dual-reset source contract           passed (select Today + `calendarController.jumpToDate(today)`)
Core focused widget test source            updated (week and month range reports)
Nutrition focused widget test source       added (Today selected, off-week viewport, dual reset)
App focused widget test source             updated (icon appears off-week and hides after viewport reset)
Core theme usage contract                  updated for `onVisibleDateRangeChanged`
flutter focused tests                      unavailable: neither `flutter` nor the known local SDK path exists
dart format                                unavailable: `dart` is not on `PATH`
```

Final owner handle sizing validation (2026-09-05):

```text
git diff --check                           clean
cut/grabber source contract                passed (80 outer / 60 inner / 8 deep; 60x4 centered grabber)
handle focused widget test source          aligned (80dp width, 48dp minimum height, 2dp visual inset)
grabber radius source contract             passed (declarative 2dp all-corner `BorderRadius`)
grabber radius widget test source          added (resolved `BoxDecoration.borderRadius` assertion)
flutter focused tests                      unavailable: neither `flutter` nor the known local SDK path exists
dart format                                unavailable: `dart` is not on `PATH`
```

Owner selection-ring correction validation (2026-09-05):

```text
selection ring source contract             passed (`TioStroke.width05`)
progress ring source contract              unchanged (`TioStroke.width2`)
focused paint matcher source               updated (outer selection circle asserts `strokeWidth: 0.5`)
flutter focused test                       unavailable: configured SDK produced no output and was terminated
```

Latest owner handle sizing validation (2026-09-05):

```text
cut/grabber source contract                passed (80 outer / 60 inner / 6 deep; 60x3 centered grabber)
handle focused widget test source          aligned (80dp width, 48dp minimum height, 1.5dp visual inset)
grabber radius widget test source          aligned (resolved 1.5dp all-corner `BorderRadius`)
flutter focused test                       not rerun; configured SDK remains blocked without output
```

The earlier green App suite above predates this latest top-bar ordering/icon refinement and is not claimed as
validation for the new code.

Tooling mismatch, reported not worked around: the installed `melos 8.6.0` rejects this repo's
v1-style `melos.yaml` with "Your current directory does not appear to be within a Melos workspace",
so `melos bootstrap / analyze / test` could not run. The equivalent per-package checks that those
melos scripts wrap were run instead, and are listed above. This mismatch is pre-existing and
unrelated to this slice.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| — | — | — | No open findings. | — | — |

## 7. Final Handoff

### Changed Files

New:

```text
apps/core/lib/src/ui/components/calendar/{calendar,tio_date_calendar,
    tio_date_calendar_display_mode,tio_date_decoration}.dart
apps/core/assets/svg_icon/ic_calendar.svg
apps/core/test/ui/components/tio_date_calendar_test.dart
apps/features/nutrition/lib/src/meal_diary/meal_diary.dart
apps/features/nutrition/lib/src/meal_diary/presentation/presentation.dart
apps/features/nutrition/lib/src/meal_diary/presentation/controllers/meal_diary_date_controller.dart
apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_page.dart
apps/features/nutrition/test/meal_diary/meal_diary_page_test.dart
.ai/tasks/tnyx-55-core-date-calendar-meal-diary.md
```

Modified:

```text
apps/app/lib/app/router.dart                           MealDiaryPage + Today action composition
apps/app/pubspec.lock                                  Core intl resolution
apps/app/test/app/app_mode_router_test.dart             Today action integration
apps/app/test/app/tio_shell_top_bar_test.dart            fixed-status leading slot + compact-width coverage
apps/core/lib/src/ui/components/components.dart         calendar barrel export
apps/core/lib/src/ui/shell/presentation/shell/tio_shell.dart
apps/core/lib/src/ui/shell/presentation/widgets/tio_shell_status_top_bar.dart
apps/core/lib/src/theme/README.md                      calendar + shell-slot contracts
apps/core/pubspec.yaml / pubspec.lock                  localized short-weekday dependency
apps/features/nutrition/lib/nutrition.dart              meal_diary barrel export
apps/features/nutrition/pubspec.yaml / pubspec.lock    Material icons + resolved Core dependencies
docs/MODULE_OWNERSHIP.md                               core calendar ownership
docs/screens/meal-diary.md                            delivered route/interaction behavior
docs/screens/nutrition.md                              root is no longer a placeholder
```

Deliberately NOT in this diff: `apps/core/test/theme/final_enforcement_{architecture,visual_ownership}_test.dart`.
Those discovery-widening changes were written during this slice but belong to TNYX-153 §16. Verified they
are not required for TNYX-55: both files are unchanged since PR #22, the original discovery simply does not
reach `lib/src/meal_diary/presentation/**`, and the full suite passes without them. Reverted to HEAD.

### Actual Behavior

`/nutrition` renders the Nutrition-owned Meal Diary surface instead of `TioShellPlaceholder`. It shows the
reusable core `TioDateCalendar` (compact horizontal strip, owner-set 80dp-wide centered transparent
trapezoid with a distinct 60x3 grabber, expandable inline month grid) over an honest empty selected-date
area. Weekday labels use localized three-letter abbreviations; `SUN` and Sunday numerals use semantic danger
styling, with highlighted Sundays stronger than ordinary Sundays.
Compact swipe pages by week; expanded swipe pages by month. No month title or previous/next arrows render.
An interaction outside the expanded calendar collapses it to the compact week rendering; calendar-internal
date, paging and handle interactions remain inside the dismissal boundary.
Nutrition owns `selectedDate`, `localToday`, a 365-day history window and `maxDate = localToday`; no
decorations are supplied because no meal-log source exists. When another date is selected, the supplied
calendar glyph appears without redundant distance immediately left of the right-anchored streak status. It
also appears when selection remains Today but the visible week/month is away from Today. The glyph shows
Today's day number; tapping it selects Today, pages the calendar to Today's week/month and hides the icon again
without moving the streak.

### Known Limitations

- awaiting owner UI acceptance; pixel geometry is not frozen;
- the calendar title/arrows/swipe/weekday refinement is widget-tested but has not been visually accepted on
  Android hardware;
- the newer handle/top-bar/Today-day-icon corrections have static checks only because this turn's shells
  expose no `flutter` or `dart` executable; their focused tests remain pending;
- `lib/src/meal_diary/presentation/**` is outside the current visual-ownership enforcement discovery; the
  code is clean but the coverage gap closes in TNYX-153;
- `melos` could not run (tooling mismatch above).

### Preview method and limitations

The earlier scratchpad Flutter-web preview preceded the latest owner refinement. Earlier behavior has widget
test evidence, including horizontal gestures and compact-width/large-text layout; the newest visual corrections
have source-contract checks only. No Android device or emulator visual acceptance was performed in this
refinement turn.

### Final Status

`PARTIAL` — IMPLEMENTED; LATEST HANDLE/TOP-BAR/SELECTED-DAY-ICON CORRECTIONS AWAIT FLUTTER VALIDATION + OWNER UI ACCEPTANCE.
