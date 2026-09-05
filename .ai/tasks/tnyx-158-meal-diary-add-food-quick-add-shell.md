# TNYX-158 — N5B Meal Diary Add Food entry & Quick Add editor shell

**Status:** In review
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
2. **Consumed time editing — deferred.** TNYX-114 owns consumed time, local date and timezone semantics. Nothing in this slice persists, so an editable time would be a draft value with no consumer and an implied storage contract. The editor instead shows the Diary's selected date in a **disabled `TioInput`**, which is what proves the handoff.

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
**Repository state last verified:** 2026-09-05, fourth pass — owner UI review of the Quick Add editor.
**Branch:** `tnyx/tnyx-158-n5b-meal-diary-add-food-entry-quick-add-editor-shell`
**HEAD SHA:** Authoritative from `git` and PR metadata; not duplicated here. The previous reviewed head was `cea7679a`, and this pass supersedes it.
**Observed working-tree state:** Clean once this remediation is committed.
**Observed uncommitted/dirty files:** None.
**PR / tracker:** PR [#214](https://github.com/im-tnyx/tio-world/pull/214) is open and non-draft; TNYX-158 is `In Review`.
**Current implementation state:** The shell is complete and published. Four review rounds have landed on top of it: the shell-navigator / scroll-clearance / read-only-row fixes; the numeric silent-mutation fix plus this record's synchronization; the owner device review that rebuilt the Add Food sheet to the TNYX-62 hierarchy; and this pass, which rebuilds the Quick Add editor to the owner-approved shell and introduces `MealLogActionFooter`. The Add Food sheet is byte-identical to the version the owner accepted — verified with `git diff` against `cea7679a`.
**Relevant execution surface:** `apps/features/nutrition/lib/src/meal_diary/**`, `apps/features/nutrition/lib/src/meal_logging/**`, `apps/features/nutrition/test/**`, `apps/core` (`showTioEditorSheet` plus the theme README), `.ai/tasks/`, `docs/screens/meal-diary.md`.
**Validation completed at SHA:** Recorded in Quality Review against the current head.
**Validation remaining:** None beyond the exact-head CI run recorded in Quality Review.
**Current blocker:** None in code. The Add Food sheet passed owner device review; this pass rebuilds the Quick Add editor to the owner-approved shell recorded above, and the slice then waits on an owner device pass over that screen.
**Open review finding IDs:** None. All nine findings — six automated, one manual governance, two owner UI — are resolved and recorded in Quality Review.
**Next exact action:** Owner device review of the Quick Add UI. No merge and no `Done` transition are authorized.

## Owner-approved Quick Add UI shell — locked 2026-09-05

Recorded here from TNYX-158's own `Owner-approved Quick Add UI shell — locked
2026-09-05` section, before any source change, so this pass does not depend on
session memory. The Linear issue remains authoritative; this is the execution
copy.

**Quick Add is not the full detailed Meal Editor.** It stays a direct path:

```text
Meal Diary → + → Add Food → Quick Add → Manual Nutrition Editor → Log Meal
```

AI, Voice, Photo, Search, Recent and Saved Meal may converge on the full Meal
Editor later, through a `MealLoggingDraft`. Quick Add stays the intentionally
simpler manual/coarse surface with direct values and no item identities.
Components may be shared; the two screens must not be forced into one.

### Upper content

```text
Meal name (optional)   large rounded field
Calories               required for a useful coarse entry
Carbs                  optional
Protein                optional
Fat                    optional
```

Fiber and micronutrients are **deferred** from this simple V1 shell. TNYX-115
and TNYX-58 may add supported nutrients later through the shared
nutrition-value contract; nothing about them is deleted from planning, they are
just not rendered here.

### Bottom — reusable Nutrition-owned Meal Log footer

```text
Meal type                         Date / time
<category shell, left>            🗓 <date/time shell, right>

[                 Log Meal                 ]
```

- meal category control: visible, **disabled**, non-authoritative — TNYX-67
  owns category identity (V1 defaults Breakfast/Lunch/Dinner/Snacks, later
  renameable, addable, hideable, reorderable, up to 8 active). No parallel
  static enum is invented here.
- date/time control: visible, **disabled**, non-editable. The date comes from
  the Meal Diary's controlled `selectedDate`, never from Today. TNYX-114 owns
  consumed-time, local-date and timezone semantics, so no picker, no
  timestamp, no timezone behaviour.
- `Log Meal`: full width, **disabled**, no persistence. Create mode says
  `Log Meal`; a later edit mode says `Save Changes`, which is out of scope.
- The footer is one Nutrition-owned reusable widget, not Quick-Add-specific
  composition, so the full Meal Editor can adopt it later. It lives in
  `apps/features/nutrition` rather than `apps/core` because it knows Nutrition
  concepts — meal category, consumed date/time, Log Meal.

### Unnamed manual log

```text
mealName entered  → use it
mealName blank    → Diary display fallback "Quick Add"
```

`Quick Add` there is a **display fallback only**: not a food identity, not a
provider identity, not a fabricated MealLog item. TNYX-158 persists nothing, so
no fallback data is created — this records the contract for TNYX-115.

## Global UI / Design-System Guardrail

This task follows `apps/core/lib/src/theme/README.md` and `apps/features/AGENTS.md`. Every surface is composed from the public `package:tio_core/core.dart` boundary. No new core component, no new token file, and no feature token bag is introduced. The feature-local compositions — the `+` affordance, and the Add Food sheet's describe/photo/compact-action surfaces built on `TioSheet` and `TioCard` — consume governed core values directly, which is what the feature rules require for a one-off composition with a single consumer. The owner's reference screenshot contributed layout only: no external branding, copy, colour, gradient, glow or typography entered the code.

Three core APIs changed, all additive and all defaulting to current behaviour so no existing sheet moves: `showTioEditorSheet` gained `useRootNavigator` and `useSafeArea`, and `TioEditorSheet` gained `flushActions` for an action region that draws its own boundary. The theme README is updated in the same change, as its maintenance contract requires.

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
| Add Food renders all four N5 paths, three of them unavailable | Made | The issue asks for the future hierarchy to be represented. Unavailable paths are dimmed, non-tappable, labelled "Not available yet" and report `enabled: false` to assistive technology — no fake navigation and no silent no-op | Nutrition |
| Quick Add stays its own screen, not a mode of the Meal Editor | Owner-locked | Quick Add is for the reader who already knows the numbers. AI, voice, photo, search, repeat and saved meals converge on the full Meal Editor through a draft; routing Quick Add there too would make the fastest path wear the slowest screen's chrome. Components may be shared, surfaces are not merged | Owner / Nutrition |
| Fiber and micronutrients dropped from the visible shell | Owner-locked | A coarse entry that asks for seven numbers is not a coarse entry. Nothing is cancelled — TNYX-115 and TNYX-58 can add supported nutrients later through the shared nutrition-value contract — they are simply not rendered in this V1 | Owner / Nutrition |
| Meal name is a large `TioInput.multiline`, capped at two lines | Made | It is the field a reader identifies a meal by later, so it gets the governed larger rounded surface rather than a standard row. Two lines is the cap and the keyboard action is `done`, because this is a title, not a notes field | Nutrition |
| Nutrition values are label-left / compact-value-right rows, and the error is its own line | Made | The 2x2 macro grid went with the owner's simplification. The error message is a separate danger-coloured `Text` under the row rather than the field's `errorText`, because a message wrapped inside a 100dp value box is unreadable — and that is already the convention `nutrition_macros_settings_page.dart` uses | Nutrition |
| `MealLogActionFooter` is a Nutrition widget, not a Core one | Made | It knows meal category, consumed date/time and that the commit is called `Log Meal`. Core is not allowed to learn any of that, so a generic version would be too anonymous to be worth having. Built as its own widget now because the full Meal Editor needs the same three controls — create says `Log Meal`, a later edit mode says `Save Changes` — and extracting it from a screen later costs more | Nutrition |
| Footer controls are disabled by null callback, with no `enabled` flag | Made | `TioCard` and `TioButton` already treat a missing callback as the disabled state. Two ways to be switched off is one too many | Nutrition |
| Meal type shows a neutral placeholder, never Breakfast | Owner-locked | TNYX-67 owns category identity — the V1 defaults, renaming, custom entries, hiding, ordering and the eight-category ceiling. Naming one here would be this screen inventing a second, weaker version of that | Owner / Nutrition |
| The date/time chip shows the real date and an unresolved time | Made | TNYX-114 owns consumed time, so there is no correct time to show. `Aug 20 · Time` states the half that is true and leaves the half that is not clearly unset, instead of printing a clock value the app does not have | Nutrition |
| The Meal Diary `+` uses `ic_fab_main.svg` | Owner request, mid-pass | The owner supplied the designed FAB glyph in place of the Material plus. It is a single monochrome path, so it is tinted from the theme exactly like the diary's Today glyph in the app shell. Nothing else about the affordance changed | Owner / Nutrition |
| The four paths are weighted, not listed | Revised after owner device review | The first build rendered all four as equal `TioSettingsNavigationRow` entries in one `TioGroupCard`. TNYX-62 already specifies otherwise, and on a device the flat list reads as four options to compare rather than one obvious way in. Now: a describe-your-meal surface shaped like somewhere to type, a full-width photo card, and Quick Add / Search Food sharing one compact row. The owner's GymStreak screenshot was a structural reference only — no branding, copy, colour, gradient or typography from it | Owner / Nutrition |
| The describe-a-meal surface is an outlined `TioCard`, not a `TioInput` | Made | It carries a prompt, a hint line and a microphone at once, which is not the single-line contract the generic field owns, and there is nothing to type into yet — a live field would collect a sentence and drop it. `TioCard(variant: outlined)` gives the input-looking surface from governed core values, with the content composed locally. No new core component for one Nutrition consumer | Nutrition |
| Quick Add is a `TioEditorSheet`, not a route | Made | It is the canonical editable modal and already solves the pinned-CTA, keyboard-inset and safe-area requirements this slice must meet. It also keeps `apps/app/router.dart` untouched | Nutrition |
| Meal category omitted | Made | See readiness deferral 1 | Nutrition |
| Consumed time omitted; date shown but disabled | Made | See readiness deferral 2 | Nutrition |
| `Log Meal` disabled with an explanatory line | Made | The issue's preferred honest boundary. `TioButton` already reports disabled semantics; the line above it says why, so the state is not communicated by dimming alone | Nutrition |
| The numeric fields have no input formatter at all | Revised after review | An allow-list looked safe and was the opposite: filtering does not reject input, it edits it, and the edit lands on a number that is still valid — `1,5` became `15`, `1e400abc` became `1400`. Per-keystroke atomic rejection ends the same way, because refusing the comma in `1,5` leaves the following `5` to land on the `1`. Nothing is filtered now; whatever is typed stays visible and the validator decides. The reader sees their own value or sees why it is refused, never a quiet third thing | Nutrition |
| Parsing is not locale-aware | Made | Reading `1,5` as `1.5` is only correct in a comma-decimal locale; in an en_US one the same rule reads `1,500` as `1.5`, which is the original silent wrong number reached more politely. `intl`'s own `NumberFormat.decimalPattern('en_US').parse('1,5')` treats the comma as grouping and returns `15` — exactly the outcome the review forbids. A real locale contract is a repo-wide numeric-input slice, so here an unsupported separator is refused out loud rather than guessed at | Nutrition |
| The date is a disabled `TioInput`, not a settings read-only row — **superseded** by the footer's date control | Revised after review, then superseded | The first attempt put the full date in `TioSettingsReadOnlyRow`, which measures its value with no width limit and overflowed a narrow row. Widening that component's contract split the row's free space evenly and made short values wrap earlier than before, so the core change was reverted in full. A disabled `TioInput` was the better fit at the time. It no longer exists: the owner-approved shell moved the date out of the body entirely, into `MealLogActionFooter`'s disabled date/time control. Kept here as history, not as the current contract | Nutrition |
| Both sheets are presented on the root navigator | Made after review | `MealDiaryPage` runs inside a `StatefulShellRoute` branch navigator while `TioShell` owns the app bar and bottom navigation outside it. A branch-navigator barrier would have left the Today action and the tabs live behind an open editor, so a reader could move the diary to today while the editor held a captured historical date. `showTioEditorSheet` gained an optional `useRootNavigator`, defaulting to Flutter's own `false` so no existing caller changes | Core / Nutrition |
| The diary body reserves the action's footprint | Made after review | The `+` is painted over the scroll view, so without a reserved band the last lines of a scrolled-to-the-end body sat underneath it. Reserved unconditionally rather than only while the button is visible, so expanding the calendar does not shift the reader's scroll position | Nutrition |
| Repo consistency does not justify keeping the unsafe behaviour | Made after review | The first response to this finding was to defer it because every numeric field in the repo, `nutrition_macros_settings_page.dart` included, filters a comma the same way. The reviewer rejected that, correctly: this editor is new code, and matching an existing silent-corruption behaviour would have written it into new tests. Only this editor is fixed here; standardizing the rest stays a separate repo-wide slice | Nutrition |

## 4. Architecture Design

### Chosen Approach

```text
MealDiaryPage (Stack)
├─ SingleChildScrollView                 calendar + summary, action footprint reserved
└─ bottom-end + affordance               hidden while the month grid is expanded
        │
        ▼ showMealDiaryAddFoodSheet(context)
   AddFoodSheet                          TioSheet, root navigator
        ├─ describe your meal + mic                               TioCard outlined
        ├─ Take a Photo, full width                               TioCard normal
        └─ Quick Add | Search Food, side by side                  TioCard normal
        │  Quick Add only
        ▼ showQuickAddEditorSheet(context, selectedDate: …)
   QuickAddEditorSheet                   TioEditorSheet, root navigator
     body, scrolls
        ├─ Meal name (optional), large                            TioInput.multiline
        └─ Calories / Carbs / Protein / Fat                       label + TioInput.numericEditor
     actions, pinned
        └─ MealLogActionFooter                                    Nutrition-owned, reusable
             ├─ Meal type (disabled)        date · Time (disabled)
             ├─ "Saving is not available yet."
             └─ Log Meal (disabled)                               TioButton.primary
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

Re-run after the owner Quick Add UI pass:

```text
flutter analyze   16 packages          No issues found
flutter test      14 packages          1846 passing, 0 failing
                                       (baseline 1801 + 39 new nutrition + 6 new core)
dart analyze      apps/shared          No issues found
dart test         apps/shared          38 passing
git diff --check                       clean
```

GitHub Actions history for this branch, oldest first:

```text
4918edcf   Flutter CI 33971516926  success   first published shell
e974c410   Flutter CI 33972666065  success   first review remediation
bff61fb8   Flutter CI 33974244612  success   numeric fix + record sync
cea7679a   Flutter CI 33980943073  success   Add Food N5 hierarchy
54c0e311   Flutter CI 33983562633  success   Quick Add owner shell
12c9517e   Flutter CI 33985463787  success   footer tightening + Add Food safe area
<current>  recorded on the PR once the run for this head completes
```

`apps/wear/.../GeneratedPluginRegistrant.java` was rewritten by `flutter pub
get` during validation and restored; it is not part of this change.

### Review Findings and Resolution

Four automated Codex findings on commit `4918edcf`, one manual governance
finding on `e974c410`, three owner UI findings — the Add Food hierarchy on
`bff61fb8`, the Quick Add shell on `cea7679a` and the device follow-ups during
this pass — two automated findings on `54c0e311` and three more on
`12c9517e`. All thirteen are resolved. The history is kept: a resolved finding still records
what was wrong and what fixed it.

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| P2-readonly-row-width | P2 | Resolved | `Flexible` on the read-only row's value split the row's free space evenly, so short label/value pairs wrapped earlier than before | `4918edcf` | The core change was reverted in full; the date is now a disabled `TioInput`, which cannot overflow and suits the editor's field layout better |
| P2-shell-navigator | P2 | Resolved | Both sheets used the branch navigator, leaving the shell's Today action and tabs live behind an open editor holding a captured date | `4918edcf` | `useRootNavigator: true` on both, via a new optional parameter on `showTioEditorSheet`; covered by two nutrition tests in a nested-navigator harness and two core tests |
| P2-action-scroll-clearance | P2 | Resolved | The floating `+` was painted over the scroll view with no matching bottom inset, so content at the maximum extent sat underneath it | `4918edcf` | The body reserves `TioSize.dp56 + TioSpacing.xl * 2`; covered by a test that fails without the reservation |
| P2-decimal-separator | P2 | Resolved | The allow-list formatter did not reject unsupported input, it edited it into a different valid number — `1,5` became `15` and `1e400abc` became `1400`, with no error to notice | `4918edcf`, still open on `e974c410` | Deferring this was the wrong call and the reviewer rejected it. The formatter is gone: nothing is filtered, the typed text stays visible, and the validator decides. Five focused tests cover `1,5`, `1e400abc`, `1e400`, `1.2.3` and `-5` staying visible with an explicit error, plus `1.5` accepted as typed. Locale-aware parsing remains out of scope, with the reasoning recorded in the decisions table |
| P2-add-food-top-safe-area | P2 | Resolved | `showModalBottomSheet` defaults `useSafeArea: false`, which applies `MediaQuery.removePadding(removeTop: true)`, so no inner `SafeArea` could protect the top. On a short or split-screen viewport a sheet tall enough to reach the top put the Add Food title and close button under the status bar or cutout | `54c0e311` | `useSafeArea: true` on the Add Food route. Flutter's wrapper is `SafeArea(bottom: false)`, so the inner `SafeArea(top: false)` still owns the bottom and nothing is padded twice. A regression test at 360x320 with a 100dp top inset asserts the title and close clear it — it reports 27.5 without the fix |
| P2-docs-quick-add-sync | P2 | Resolved | `docs/screens/meal-diary.md`, this brief and the PR body still described the superseded Quick Add shell — Fiber, the 2x2 macro grid and the standalone disabled Date field | `54c0e311` | All three now describe the owner-approved shell: meal name, Calories/Carbs/Protein/Fat, Fiber deferred, and the reusable `MealLogActionFooter` with its disabled meal-type and date/time controls. Historical decisions and findings are kept |
| P1-changed-files-inventory | P1 | Resolved | The Changed Files handoff listed 17 of the 20 files in the diff — both owner-supplied glyphs and `meal_log_action_footer.dart` were missing, so a reviewer reconstructing ownership would have missed the new runtime assets and the reusable footer entirely | `12c9517e` | The list is now generated from `git diff --name-only origin/main...HEAD` rather than maintained by hand |
| P2-quick-add-top-safe-area | P2 | Resolved | `showTioEditorSheet` left `useSafeArea` at Flutter's `false`, so the route stripped the top padding and a keyboard-raised or split-screen viewport could push the Quick Add handle and title under the status bar — the same defect already fixed on Add Food | `12c9517e` | `useSafeArea` added to the presenter, defaulting to false, and passed true from Quick Add. Two Core tests cover both settings; a nutrition test at 360x460 with a 100dp inset reports 40.0 without the fix |
| P2-numeric-error-association | P2 | Resolved | An invalid value produced only a separate `Text`. The field itself still reported valid and the message was not a live region, so a screen reader in that field heard nothing and the error was not programmatically tied to it | `12c9517e` | The value box is wrapped in `Semantics(validationResult: invalid)` while the message becomes a live region. The visible separate line stays, because a message wrapped inside a 100dp value box is unreadable |
| owner-quick-add-ui-followups | Owner UI | Resolved | Device feedback on the first Quick Add build: the meal-name box was too tall, the value boxes too tall, the year in the date chip was noise, and the footer had no divider — then, once added, the divider was inset by the sheet's padding with dead space above it and the last field touching it | owner review during the pass | Meal name starts at one line, the value boxes take a shorter content padding, the chip is month and day only, and the footer draws one edge-to-edge rule. `TioEditorSheet` gained `flushActions` so the gap above the actions is genuinely removed rather than painted around, and the body ends with `TioSpacing.lg` so the last field clears the line |
| owner-quick-add-ui-pass | Owner UI | Resolved | The Quick Add editor was a 2x2 macro grid with Fiber, a settings-style date row and a paragraph of disabled-CTA copy — none of which matches the owner-approved shell locked on the issue | `cea7679a`, owner review | Rebuilt to the locked contract: Quick Add kept separate from the full Meal Editor, a large optional meal-name field, Calories / Carbs / Protein / Fat as simple rows, Fiber deferred, and one reusable Nutrition-owned `MealLogActionFooter` carrying a disabled meal-category shell, a disabled date/time shell showing the diary's selected date, and a disabled full-width `Log Meal`. The `+` also took the owner-supplied `ic_fab_main.svg` glyph |
| UI-owner-review-add-food-hierarchy | Owner UI | Resolved | The Add Food sheet rendered all four N5 paths as one vertical list of equal `TioSettingsNavigationRow` entries. Device review found this contradicts the TNYX-62 layout contract, which is authoritative: a natural-language input surface first, a full-width photo card second, and Quick Add plus Search Food as horizontal compact cards | `bff61fb8`, owner device review | The sheet is rebuilt to that hierarchy from `TioSheet` and `TioCard`, with geometry tests at 320px and 400px asserting the ordering, the shared row and the full-width photo card so it cannot flatten back into a list. Quick Add's editor is deliberately untouched; the owner reviews that separately |
| P1-handoff-sync | P1 | Resolved | The task brief still read `Current blocker: None` / `Open review finding IDs: None` / `Next exact action: Open the PR`, still drew the date as `TioSettingsReadOnlyRow` after that was reverted, and still treated `4918edcf` as the latest CI handoff; the PR body was stale in the same ways | `e974c410` | Active Handoff, the architecture diagram, the decisions table, this section and the PR body are all synchronized with the current head in the same commit |

## 7. Final Handoff

### Changed Files

Generated from `git diff --name-only origin/main...HEAD`, so the inventory
cannot drift from the diff again.

```text
.ai/tasks/tnyx-158-meal-diary-add-food-quick-add-shell.md
apps/core/assets/svg_icon/ic_calendar_.svg
apps/core/assets/svg_icon/ic_fab_main.svg
apps/core/lib/src/theme/README.md
apps/core/lib/src/ui/components/sheets/tio_editor_sheet.dart
apps/core/test/ui/components/tio_editor_sheet_test.dart
apps/features/nutrition/lib/nutrition.dart
apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_page.dart
apps/features/nutrition/lib/src/meal_diary/presentation/presentation.dart
apps/features/nutrition/lib/src/meal_diary/presentation/widgets/meal_diary_log_action.dart
apps/features/nutrition/lib/src/meal_diary/presentation/widgets/widgets.dart
apps/features/nutrition/lib/src/meal_logging/meal_logging.dart
apps/features/nutrition/lib/src/meal_logging/presentation/presentation.dart
apps/features/nutrition/lib/src/meal_logging/presentation/widgets/add_food_sheet.dart
apps/features/nutrition/lib/src/meal_logging/presentation/widgets/meal_log_action_footer.dart
apps/features/nutrition/lib/src/meal_logging/presentation/widgets/quick_add_editor_sheet.dart
apps/features/nutrition/lib/src/meal_logging/presentation/widgets/widgets.dart
apps/features/nutrition/test/meal_diary/meal_diary_page_test.dart
apps/features/nutrition/test/meal_logging/meal_diary_add_food_flow_test.dart
docs/screens/meal-diary.md
```

`apps/app/lib/app/router.dart` is deliberately untouched: both surfaces are
modal sheets owned by Nutrition, so no route or composition change was needed.
Nothing under `supabase/` is touched.

### Actual Behavior

```text
Meal Diary
→ +  (bottom-trailing, above the bottom nav, hidden while the month grid is open)
→ Add Food sheet
   Add Food                                            ×
   ┌──────────────────────────────────────────────────┐
   │ What did you eat?                             🎙 │  disabled
   │ Describe your meal · Not available yet           │
   └──────────────────────────────────────────────────┘
   ┌──────────────────────────────────────────────────┐
   │ 📷  Take a Photo                                 │  disabled
   │     Analyze food from a photo · Not available yet│
   └──────────────────────────────────────────────────┘
   ┌───────────────────────┐ ┌────────────────────────┐
   │ +  Quick Add          │ │ 🔍  Search Food        │
   │    Calories and macros│ │     Not available yet  │
   └───────────────────────┘ └────────────────────────┘
     active                    disabled
→ Quick Add
→ Manual Nutrition Editor
   ┌───────────────────────────────────────────┐
   │ Meal name (optional)                      │  large, two lines max
   └───────────────────────────────────────────┘
   Calories (kcal)                    [       ]
   Carbs (g)                          [       ]
   Protein (g)                        [       ]
   Fat (g)                            [       ]
   ─────────────────────────── body scrolls ───
   ══════════════════════════════════════════════  edge-to-edge rule
   Meal type ▼                  🗓 Aug 20 · Time   both disabled
   Saving is not available yet.
   [                Log Meal                   ]  disabled
```

Fiber and micronutrients are not rendered. Meal category names no real
category. The date is the diary's selected day; the time half is honestly
unresolved rather than invented.

Both sheets are presented on the root navigator, so the shell's app bar and
bottom navigation are behind the barrier rather than live beside it.

Numeric fields never rewrite what was typed:

```text
1.5        accepted as 1.5
1,5        stays "1,5",        "Enter a number."
1e400abc   stays "1e400abc",   "Enter a number."
1e400      stays "1e400",      "Enter a number."   (parses to infinity)
-5         stays "-5",         "Calories cannot be negative."
blank      absent, no error, and not zero
```

Dismissing either surface returns to the diary with the same selected date, no
history, and no retained input — reopening Quick Add starts empty.

### Known Limitations

- Nothing can be saved. `Log Meal` is inert by design until TNYX-113 → TNYX-114 → TNYX-115 land.
- No meal category and no consumed time, for the reasons recorded above.
- The Add Food sheet's three unavailable paths are presentation only. Describe-a-meal looks like somewhere to type and is not a field, the microphone does not listen, the photo card opens no camera, and Search Food opens no screen. None has an implementation behind it.
- Fiber and micronutrients are absent from Quick Add by owner decision, not by oversight.
- The meal-category and date/time controls are shells. Neither can be changed, and the time half of the date chip is unresolved rather than defaulted.
- The `+` hides while the calendar's month grid is expanded. That is a deliberate anti-overlap rule, not a bug.
- A comma decimal is refused rather than understood. That is safe but not friendly, and it is as far as this slice should go: reading `1,5` as `1.5` requires a locale contract that also governs grouping separators, which belongs to a repo-wide numeric-input slice. The rest of the app's numeric fields still filter the comma silently and are unchanged here.
- The numeric fields accept any keystroke, so a hardware keyboard or a paste can put text in them. That is deliberate — it is what lets the validator name the problem instead of the field quietly editing it away.

### Final Status

`REVIEW`
