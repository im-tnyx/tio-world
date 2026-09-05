# TNYX-158 — N5B Meal Diary Add Food entry & Quick Add editor shell

**Status:** In progress
**Primary owner:** Nutrition (`apps/features/nutrition`)
**Affected platforms:** Flutter phone app (`apps/features/nutrition`, `docs`)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** TNYX-158 (`In Progress`, parent TNYX-62) plus its implementation prompt. The issue's own acceptance list authorises the visible change: a contextual `+`, an Add Food sheet, a Quick Add manual editor, and a Meal Diary body that no longer ends only at `Meal logging is not available yet.`
**Approved product/UI/data-shape boundaries:** presentation and navigation only — `Meal Diary → + → Add Food sheet → Quick Add → Manual Nutrition Editor → disabled Log Meal`. No data shape at all: this slice defines no entity, no repository, no table and no column.
**Explicit non-changes:** no `MealLogEntry`, no persistence of any kind (Supabase, SharedPreferences, in-memory history), no AI/voice/photo/provider/search, no Diary cards or sections, no daily summary, no calendar decorations, no meal-category system, no consumed-time contract, no merge, no `Done` transition, no change to TNYX-66's own status.

## Focused N0 (TNYX-66) readiness result

```text
READY for TNYX-158
```

Audited only what this presentation/navigation slice needs, not the whole Nutrition epic.

### Readiness evidence

| Area | Verified | Evidence |
|---|---|---|
| Instructions | Read | `AGENTS.md`, `apps/features/AGENTS.md`, `apps/core/lib/src/theme/README.md`, `.ai/tasks/README.md`, `.ai/tasks/TEMPLATE.md` |
| Baseline | Clean | `origin/main` = `6639864fb9a959d911ab380d00b64ce059458d77` after fresh fetch; worktree clean; branch cut from that SHA |
| Overlap | None | `gh pr list --state open` returns no open PRs; no other Nutrition/Settings branch is in flight |
| Preserved work | Untouched | `docs/supabase-android-studio-qa-run` @ `7fe896820c8f176b5049df4fe84fc9acea5933b1`, local-only, not pushed/rebased/modified |
| Meal Diary runtime | Inspected | `MealDiaryDateController` owns `selectedDate`, `localToday`, `minDate`, `maxDate = localToday`, midnight rollover; `MealDiaryPage` forwards `resolvedFirstDayOfWeek` and renders the "not available yet" summary |
| Composition | Inspected | `apps/app/lib/app/router.dart` builds `MealDiaryPage` inside the Nutrition shell branch; `TioShell` exposes **no** `floatingActionButton` slot, so the affordance must live in the page body |
| Core sheet surface | Exists | `showTioEditorSheet` / `TioEditorSheet` is the canonical editable modal — handle, header, scrollable body, **pinned** actions, `MediaQuery.viewInsetsOf` keyboard inset, `SafeArea` |
| Core row surface | Exists | `TioGroupCard` + `TioSettingsNavigationRow` + `TioSettingsReadOnlyRow` |
| Core field surface | Exists | `TioInput` (label, `errorText`, `suffixText`, `inputFormatters`, `keyboardType`) |
| Core disabled CTA | Exists | `TioButton` reports `Semantics(button: true, enabled: false)` when its callback resolves to null |
| Numeric convention | Exists | `nutrition_macros_settings_page.dart`: blank = absent, `double.tryParse` + `isFinite` = "Enter a number.", `< 0` = "<Label> cannot be negative." |
| Floating action affordance | **Absent** | No `FloatingActionButton` anywhere in `apps/`, and `TioTheme` configures no `FloatingActionButtonThemeData` — a raw Material FAB would render un-governed colours |
| Meal category truth | **Absent** | No `MealCategory` type, enum, table or column exists in `apps/`, `supabase/` or runtime docs — it appears only in planning text (TNYX-57/N13/N14) |
| Tests baseline | Exists | `apps/features/nutrition/test/meal_diary/meal_diary_page_test.dart` covers calendar, range, rollover, visible month, short viewport |

### Two deferrals classified during readiness (not blockers)

1. **Meal category selector — deferred.** No production-safe canonical category source exists. TNYX-57 and TNYX-115 both consume `MealCategory.displayName`, and N13 owns category management. Hard-coding Breakfast/Lunch/Dinner/Snack here would invent a domain contract this slice is forbidden to own. TNYX-158 lists the field as one that "may include", so omitting it stays inside the approved boundary.
2. **Consumed time editing — deferred.** TNYX-114 owns consumed time, local date and timezone semantics. Nothing in this slice persists, so an editable time would be a draft value with no consumer and an implied storage contract. The editor instead shows the Diary's selected date **read-only**, which is what proves the handoff.

Both are recorded on TNYX-66 as focused readiness evidence. TNYX-66 stays open; one ready slice does not close the gate.

### Stale docs called out

- `.ai/CURRENT.md` is dated 2026-08-23, describes Onboarding O7 only, and references a "Draft PR #50" that no longer appears in `gh pr list --state open`. It is not readiness truth for Nutrition and was not followed.
- `docs/screens/nutrition.md` still describes the Nutrition tab body as target content; its Meal Diary paragraph is current. `docs/screens/meal-diary.md` is updated by this slice.

## Active Handoff

**Planning owner:** Claude (this session)
**Implementation owner:** Claude (this session)
**Review owner:** Unassigned — PR review
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-05
**Branch:** `tnyx/tnyx-158-n5b-meal-diary-add-food-entry-quick-add-editor-shell`
**HEAD SHA:** Authoritative from `git`; not duplicated here.
**Observed working-tree state:** Clean at branch creation.
**Observed uncommitted/dirty files:** None at branch creation.
**PR / tracker:** TNYX-158 `In Progress` during implementation, `In Review` once the PR is open.
**Current implementation state:** See Implementation Plan.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_diary/**`, `apps/features/nutrition/lib/src/meal_logging/**`, `apps/features/nutrition/test/**`, `.ai/tasks/`, `docs/screens/meal-diary.md`.
**Validation completed at SHA:** Recorded in Quality Review.
**Validation remaining:** Recorded in Quality Review.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Open the PR and move TNYX-158 to `In Review`.

## Global UI / Design-System Guardrail

This task follows `apps/core/lib/src/theme/README.md` and `apps/features/AGENTS.md`. Every surface is composed from the public `package:tio_core/core.dart` boundary. No new core component, no new token file, and no feature token bag is introduced. The two feature-local compositions (the `+` affordance and the two sheets) consume governed core values directly, which is what the feature rules require for a one-off composition with a single consumer.

## 1. Discovery

### User Outcome

From the Meal Diary a user can reach a Quick Add manual nutrition editor, see the day they picked carried into it, type calories and macros, and be told plainly — not by a dead end and not by a fake success — that saving is not available yet.

### Success Criteria

- A contextual `+` is reachable from Meal Diary and does not sit over the bottom navigation, the safe area or the expanded calendar grid.
- `+` opens an Add Food sheet whose only working path is Quick Add.
- Quick Add opens a Manual Nutrition Editor carrying the Diary's selected date.
- Negative, non-numeric and non-finite values are rejected; a blank optional field stays absent rather than becoming zero.
- `Log Meal` is present but disabled, and says why.
- Dismissing anything leaves no history, no draft and no change to the selected date.
- Existing calendar, first-day-of-week, Today and future-date behaviour is unchanged.

### Scope

Meal Diary entry affordance, Add Food sheet, Quick Add manual editor shell, the Meal Diary placeholder line, focused tests, this brief, and `docs/screens/meal-diary.md`.

### Non-Goals

Everything under **Explicit non-changes** above, plus N4 Diary cards, N6 detailed meal editor, N13 categories, N14 diary settings and TNYX-155.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `meal_diary_page.dart`, `meal_diary_date_controller.dart`, `apps/app/lib/app/router.dart`, `tio_shell.dart`, `tio_editor_sheet.dart`, `tio_sheet.dart`, `tio_settings_rows.dart`, `tio_group_card.dart`, `tio_input.dart`, `tio_button.dart`, `tio_date_calendar.dart`, `nutrition_macros_settings_page.dart`.
- Existing pattern to follow: `showTioEditorSheet` + `TioEditorSheet` for the editor; `TioGroupCard` + `TioSettingsNavigationRow` for the action list; the macros sheet's numeric validation wording; `TioButton` for the disabled CTA.
- Tests or validation already present: `meal_diary_page_test.dart` (calendar, range, rollover, visible month, short viewport). One of its assertions matches the placeholder string this slice rewrites, so that finder is updated to the new string — no assertion is removed or weakened.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| The `+` lives in the Meal Diary body, not in `TioShell` | Made | `TioShell` has no FAB slot, and giving Core one for a single Nutrition consumer would push a feature concern into the shell. A `Stack` in the page body sits above the bottom nav by construction, since the nav is the `Scaffold`'s own slot | Nutrition |
| The `+` is a feature-local governed circular action, not `FloatingActionButton` | Made | No FAB exists in the repo and `TioTheme` configures no FAB theme, so a raw Material FAB would draw un-governed colours. One consumer means feature-local composition over a new core component | Nutrition |
| The `+` hides while the calendar month grid is expanded | Made | Keeps the affordance from overlapping date cells on a short viewport. Observed through the calendar's existing `onDisplayModeChanged` callback; `displayMode` stays calendar-owned so no behaviour changes | Nutrition |
| Add Food renders all four N5 paths, three of them unavailable | Made | The issue asks for the future hierarchy to be represented. Unavailable rows are dimmed, chevron-less, non-tappable, labelled "Not available yet" and report `enabled: false` to assistive technology — no fake navigation and no silent no-op | Nutrition |
| Quick Add is a `TioEditorSheet`, not a route | Made | It is the canonical editable modal and already solves the pinned-CTA, keyboard-inset and safe-area requirements this slice must meet. It also keeps `apps/app/router.dart` untouched | Nutrition |
| Meal category omitted | Made | See readiness deferral 1 | Nutrition |
| Consumed time omitted; date shown read-only | Made | See readiness deferral 2 | Nutrition |
| `Log Meal` disabled with an explanatory line | Made | The issue's preferred honest boundary. `TioButton` already reports disabled semantics; the line above it says why, so the state is not communicated by dimming alone | Nutrition |
| The minus sign passes the input formatter | Made | The macros sheet filters to `[0-9.]`, which makes its own "cannot be negative" message unreachable. Here `[-0-9.]` lets the validator actually say why, instead of a keystroke silently vanishing. Letters and every other symbol stay filtered | Nutrition |
| The date is a disabled `TioInput`, not a settings read-only row | Revised after review | The first attempt put the full date in `TioSettingsReadOnlyRow`, which measures its value with no width limit and overflowed a narrow row. Widening that component's contract split the row's free space evenly and made short values wrap earlier than before, so the core change was reverted in full. A disabled `TioInput` is the better fit anyway: the date is one of the editor's fields, drawn like the rest, and "disabled" is the accurate state for a value TNYX-114 will later make editable | Nutrition |
| Both sheets are presented on the root navigator | Made after review | `MealDiaryPage` runs inside a `StatefulShellRoute` branch navigator while `TioShell` owns the app bar and bottom navigation outside it. A branch-navigator barrier would have left the Today action and the tabs live behind an open editor, so a reader could move the diary to today while the editor held a captured historical date. `showTioEditorSheet` gained an optional `useRootNavigator`, defaulting to Flutter's own `false` so no existing caller changes | Core / Nutrition |
| The diary body reserves the action's footprint | Made after review | The `+` is painted over the scroll view, so without a reserved band the last lines of a scrolled-to-the-end body sat underneath it. Reserved unconditionally rather than only while the button is visible, so expanding the calendar does not shift the reader's scroll position | Nutrition |
| Locale decimal separators are not handled | Deferred | In a comma-decimal locale, `1,5` is filtered to `15` — silently, and wrongly. That is the behaviour of every numeric field in the repo today, including `nutrition_macros_settings_page.dart`, and correct handling needs locale-aware parsing that also has to tell a decimal comma from an en_US thousands comma. Fixing it here alone would leave the app inconsistent; it belongs in a repo-wide numeric-input slice | Nutrition |

## 4. Architecture Design

### Chosen Approach

```text
MealDiaryPage (Stack)
├─ SingleChildScrollView                 unchanged calendar + summary
└─ bottom-end + affordance               hidden while the month grid is expanded
        │
        ▼ showMealDiaryAddFoodSheet(context)
   AddFoodSheet                          TioSheet + TioGroupCard rows
        │  Quick Add only
        ▼ showQuickAddEditorSheet(context, selectedDate: …)
   QuickAddEditorSheet                   TioEditorSheet
        ├─ meal name / calories / protein / carbs / fat / fiber   TioInput
        ├─ Date (read-only)                                       TioSettingsReadOnlyRow
        └─ Log Meal (disabled) + reason                           TioButton.primary
```

### Ownership and Data Flow

```text
MealDiaryDateController.selectedDate  →  read once at sheet open  →  displayed read-only
```

The date travels one way. No sheet holds a reference to the controller, so nothing a sheet does can move the Diary's selection. Field state is local `TextEditingController` state inside the editor's `State` and dies with the route: there is no notifier, no provider, no repository and no store behind it.

### Alternative Rejected

- **A `floatingActionButton` slot on `TioShell`.** Generic in shape, but only Nutrition needs it and the shell would then own an affordance whose visibility rule is a Meal Diary concern (it hides with the calendar grid). Rejected under the core admission gate.
- **A full-screen Quick Add route.** Would need `apps/app/router.dart`, a route contract and back-navigation handling for a surface TNYX-115 may reshape anyway. The editor sheet delivers the same fields with less to unpick later.
- **A draft/unsaved-changes confirmation on dismiss.** No comparable Tio form does this today, and inventing draft management for a form that cannot save would be a broader contract than this slice owns.

### Failure and Accessibility States

- Invalid number → `errorText` under the field: a message plus the component's error styling, never colour alone.
- Unavailable Add Food path → dimmed row, `Not available yet` supporting text, no chevron, `Semantics(button: true, enabled: false)` with the reason in the label.
- `Log Meal` → disabled `TioButton` whose `semanticLabel` states it is unavailable, above an explanatory line.
- `+` → `Semantics` button with the label `Add food` and a matching tooltip.

## 5. Implementation Plan

- [x] Focused N0 readiness audit and this brief
- [x] Meal Diary `+` affordance, hidden while the calendar is expanded
- [x] Add Food sheet with one active and three unavailable paths
- [x] Quick Add manual nutrition editor sheet
- [x] Honest Meal Diary placeholder line
- [x] Focused tests
- [x] `docs/screens/meal-diary.md` synchronisation
- [x] Validation

## 6. Quality Review

### Validation Run

`melos` is not installed on this machine, so the documented per-package
equivalents were run instead — the same commands `melos analyze` and
`melos test` would have executed.

Re-run after the review remediation:

```text
flutter analyze   16 packages          No issues found
flutter test      14 packages          1826 passing, 0 failing
                                       (baseline 1801 + 23 new nutrition + 2 new core)
dart analyze      apps/shared          No issues found
dart test         apps/shared          38 passing
git diff --check                       clean
```

Exact-head GitHub Actions run `33971516926` on `4918edcf` (the pre-remediation
head) completed successfully — Flutter CI, job "Analyze and test". A fresh run
follows the remediation push.

`apps/wear/.../GeneratedPluginRegistrant.java` was rewritten by `flutter pub
get` during validation and restored; it is not part of this change.

### Review Findings and Resolution

Automated Codex review on PR [#214](https://github.com/im-tnyx/tio-world/pull/214), commit `4918edcf`, raised four P2 findings.

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| P2-readonly-row-width | P2 | Resolved | `Flexible` on the read-only row's value split the row's free space evenly, so short label/value pairs wrapped earlier than before | `4918edcf` | The core change was reverted in full; the date is now a disabled `TioInput`, which cannot overflow and suits the editor's field layout better |
| P2-shell-navigator | P2 | Resolved | Both sheets used the branch navigator, leaving the shell's Today action and tabs live behind an open editor holding a captured date | `4918edcf` | `useRootNavigator: true` on both, via a new optional parameter on `showTioEditorSheet`; covered by two nutrition tests in a nested-navigator harness and two core tests |
| P2-action-scroll-clearance | P2 | Resolved | The floating `+` was painted over the scroll view with no matching bottom inset, so content at the maximum extent sat underneath it | `4918edcf` | The body reserves `TioSize.dp56 + TioSpacing.xl * 2`; covered by a test that fails without the reservation |
| P2-decimal-separator | P2 | Deferred | A comma decimal separator is filtered out, silently turning `1,5` into `15` | `4918edcf` | Real, and repo-wide: every numeric field behaves this way today. Correct handling needs locale-aware parsing that can also distinguish a decimal comma from an en_US thousands comma. Belongs in its own numeric-input slice, not in a UI shell |

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/tnyx-158-meal-diary-add-food-quick-add-shell.md                       new
apps/core/lib/src/theme/README.md                                               modified
apps/core/lib/src/ui/components/sheets/tio_editor_sheet.dart                    modified
apps/core/test/ui/components/tio_editor_sheet_test.dart                         modified
apps/features/nutrition/lib/nutrition.dart                                      modified
apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_page.dart          modified
apps/features/nutrition/lib/src/meal_diary/presentation/presentation.dart       modified
apps/features/nutrition/lib/src/meal_diary/presentation/widgets/meal_diary_log_action.dart  new
apps/features/nutrition/lib/src/meal_diary/presentation/widgets/widgets.dart    new
apps/features/nutrition/lib/src/meal_logging/meal_logging.dart                  new
apps/features/nutrition/lib/src/meal_logging/presentation/presentation.dart     new
apps/features/nutrition/lib/src/meal_logging/presentation/widgets/add_food_sheet.dart       new
apps/features/nutrition/lib/src/meal_logging/presentation/widgets/quick_add_editor_sheet.dart new
apps/features/nutrition/lib/src/meal_logging/presentation/widgets/widgets.dart  new
apps/features/nutrition/test/meal_diary/meal_diary_page_test.dart               modified
apps/features/nutrition/test/meal_logging/meal_diary_add_food_flow_test.dart    new
docs/screens/meal-diary.md                                                      modified
```

`apps/app/lib/app/router.dart` is deliberately untouched: both surfaces are
modal sheets owned by Nutrition, so no route or composition change was needed.
Nothing under `supabase/` is touched.

### Actual Behavior

```text
Meal Diary
→ +  (bottom-trailing, above the bottom nav, hidden while the month grid is open)
→ Add Food sheet
   ├─ What did you eat?   disabled, "Not available yet"
   ├─ Take a Photo        disabled, "Not available yet"
   ├─ Quick Add           active
   └─ Search Food         disabled, "Not available yet"
→ Quick Add
→ Manual Nutrition Editor
   ├─ Meal name                      optional
   ├─ Calories                       kcal
   ├─ Protein / Carbs / Fat / Fiber  g, optional, blank = absent
   ├─ Date                           read-only, the diary's selected day
   └─ Log Meal                       disabled, with the reason above it
```

Dismissing either surface returns to the diary with the same selected date, no
history, and no retained input — reopening Quick Add starts empty.

### Known Limitations

- Nothing can be saved. `Log Meal` is inert by design until TNYX-113 → TNYX-114 → TNYX-115 land.
- No meal category and no consumed time, for the reasons recorded above.
- The Add Food sheet's three unavailable paths are presentation only; none of them has an implementation behind it.
- The `+` hides while the calendar's month grid is expanded. That is a deliberate anti-overlap rule, not a bug.
- A comma decimal separator is still filtered out of numeric fields, as it is everywhere else in the app. Recorded as `P2-decimal-separator` for a repo-wide numeric-input slice.

### Final Status

`REVIEW`
