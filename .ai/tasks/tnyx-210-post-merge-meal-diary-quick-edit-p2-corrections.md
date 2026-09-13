# TNYX-210 — Post-merge Meal Diary Quick Edit P2 corrections

**Status:** Ready for review — implementation and validation complete, awaiting push/PR/CI\
**Primary owner:** `apps/features/nutrition`\
**Affected platforms:** Flutter phone app (`apps/features/nutrition`, consumed by `apps/app`)

## Owner Approval and Scope Boundary

**Trigger:** None — bounded correctness/regression follow-up inside the already-approved TNYX-204 scope\
**Approval status:** Not required (scoped bug fixes/review findings inside approved scope per `.ai/FEATURE_DEVELOPMENT.md`)\
**Approval evidence:** Linear `TNYX-210` created 2026-09-13 recording six post-merge Codex review findings against merged PR #263 / TNYX-204 (head `366410e99cec64181df3b938b4ba783cad009739`, merged as `main@0380bc9b`). Not a redesign; card/section geometry, typography and one-switch behavior stay as approved.\
**Approved product/UI/data-shape boundaries:** Fix six correctness/regression defects only. No new visible UI, no new actions, no Supabase/schema change.\
**Explicit non-changes:** No TNYX-209 implementation; no timezone resolver/IANA conversion; no new meal media/overflow actions; no DailyNutritionBudget/Daily Summary work; no global `TioSheet` redesign; no Supabase/schema/RLS change.

## Active Handoff

**Planning owner:** Claude\
**Implementation owner:** Claude\
**Review owner:** Unassigned\
**Implementation ownership state:** Active\
**Ownership transition:** Not applicable\
**Repository state last verified:** 2026-09-13, clean at `main@0380bc9be82155932562b67674fc913fb9b60de2`, matching `origin/main`\
**Branch:** `tnyx/tnyx-210-n20c-2a-post-merge-meal-diary-quick-edit-p2-corrections`\
**HEAD SHA:** pending first commit\
**Observed working-tree state:** Clean before implementation\
**Observed uncommitted/dirty files:** None\
**PR / tracker:** Source review is merged PR [#263](https://github.com/im-tnyx/tio-world/pull/263) (Codex review `pullrequestreview-5189642450` on final head `366410e9`); this task opens a new Draft PR against `main`. Linear `TNYX-210` is `In Progress`, parent `TNYX-115`, blocks `TNYX-209`.\
**Current implementation state:** RF1–RF6 implemented and each has a focused regression test proving the fix.\
**Relevant execution surface:** `quick_add_meal_log_edit_controller.dart`, `meal_diary_meal_card.dart`, `add_food_sheet.dart`, `meal_diary_history_view.dart`, `meal_diary_page.dart`\
**Validation completed at SHA:** working tree, pre-commit — `apps/features/nutrition` analyze clean + 705 tests (was 695), `apps/app` analyze clean + 319 tests (unchanged), `git diff --check` clean, no `apps/core`/Supabase files touched\
**Validation remaining:** Exact-head CI after push\
**Current blocker:** None\
**Open review finding IDs:** RF1–RF6, all `Resolved` (see table below)\
**Next exact action:** Commit, push, open Draft PR against `main`, wait for exact-head CI, then reconcile Linear `TNYX-210` to `In Review` only once that CI is actually green.

## Global UI / Design-System Guardrail

`apps/core/lib/src/theme/README.md` and `apps/features/AGENTS.md` were read before touching UI code. All six fixes are pixel/behavior-preserving corrections to already-approved TNYX-204 geometry — no new visible design, no new Core component, no token changes.

## 1. Discovery

### User Outcome

Six merged-runtime correctness/regression defects found by post-merge Codex review no longer occur: unrelated Quick Edit saves are not falsely blocked after timezone travel, unnamed cards never collide with the overflow target, Add Food's rounded sheet corners are not squared by the bottom-inset fill, the section header never crashes under large accessibility text, rapid taps cannot stack two Quick Edit sheets, and rows without an exact reconstructable time never expose a dead Edit action.

### Success Criteria

See Linear TNYX-210 acceptance checklist (reproduced in full in the issue; not duplicated here per `.ai/tasks/README.md` — GitHub/Linear own full text, this brief owns compact execution state).

### Scope

Exactly the six RF items below. No other TNYX-204 behavior, geometry, or copy changes.

### Non-Goals

TNYX-209 amount-range policy; timezone resolver; new meal media/overflow actions; DailyNutritionBudget/Daily Summary; global `TioSheet` redesign; Supabase/schema/RLS.

## 2. Codebase Exploration

### Verified Evidence

- `quick_add_meal_log_edit_controller.dart:114-119` — `submit()` compares `draft.consumedLocalDateTime` to `_clock()` unconditionally, not to whether the draft time actually changed from `_baseEntry`'s reconstructed wall time.
- `meal_diary_meal_card.dart:80` — title/overflow-clearance band gate is `mealName != null || noteIndicatorVisible`, omitting `edit != null`, while the overflow target ( `meal_diary_meal_card.dart:185-190`) is positioned unconditionally on `edit != null` alone.
- `add_food_sheet.dart:44-56` — `ColoredBox(color: surface)` wraps the entire `SafeArea`-protected subtree including `TioSheet`'s own rounded-corner `Material` (`apps/core/lib/src/ui/components/sheets/tio_sheet.dart:20-24`, which already paints `colors.surface` with `BorderRadius.vertical(top: ...)`), so the outer box's flat rectangle sits behind/around that rounded arc.
- `meal_diary_history_view.dart:209-212` — `ConstrainedBox(constraints: BoxConstraints(maxWidth: constraints.maxWidth - TioSpacing.sm))` can receive a negative `maxWidth` when the `LayoutBuilder`'s own `constraints.maxWidth` (already reduced by a wide non-flexible `_SectionNutritionSummary` sibling under large text scale) is below `TioSpacing.sm` (8dp).
- `meal_diary_history_view.dart:281-304` (`_MealEntryCard`) — `open` is gated only on `onEdit != null`, not on `entry.loggedLocalDateTime` (which the read model already computes as `null` whenever `consumedUtcOffsetMinutes` is absent, identically to `QuickAddMealLogEditController.editableLocalDateTime`'s own offset check).
- `meal_diary_page.dart:186-239` (`_openQuickEdit`) — no in-flight guard; `mealLogRepository.readById(id)` is awaited with the card fully interactive throughout.

### Existing Pattern To Follow

- `_buildInput`'s own `timeChanged = draft.consumedLocalDateTime != originalLocal` pattern (already in the same file) is the exact comparison RF1 needs, reused rather than reinvented.
- `_MealEntryCard` already derives one shared `open` callback passed to both `onTap` and `onEdit` on `MealDiaryMealCard` — RF6 extends that same single predicate rather than adding a second one.

### Tests Or Validation Already Present

676+ existing Nutrition tests cover the approved TNYX-204 card/header/edit behavior (see prior task brief `.ai/tasks/tnyx-204-manual-meal-diary-card-overflow-quick-edit.md`); none of the six RF scenarios were covered.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| RF4 caps `_SectionNutritionSummary` with `ConstrainedBox` + `FittedBox(fit: BoxFit.scaleDown)` against an outer `LayoutBuilder`'s full header width, not `Flexible` | Made | `ConstrainedBox`+`FittedBox` keeps the summary a plain intrinsic-width Row sibling — a no-op at any normal size — while still giving it a genuine shrink-to-fit fallback under adversarial width. A `Flexible` sibling to the title's `Expanded` was tried first and reverted: Flutter's flex algorithm gives a tight `Expanded` its full allotted share regardless of need, while a loose `Flexible` that ends up smaller leaves the gap as trailing slack rather than returning it — breaking the "summary flush at the content edge" geometry at normal widths too, confirmed by a regression in the existing 390dp test | Claude |
| RF5's guard window ends the instant `showQuickAddEditorSheet` is called, not when it resolves | Made | `showModalBottomSheet`'s route/barrier is installed synchronously by that call, so further taps on the page are already blocked by the framework's own modal barrier from that point on; holding the guard for the sheet's whole open duration would block a legitimate *later* edit opened right after this one closes for no reason | Claude |
| RF6 reuses `MealDiaryEntryReadModel.loggedLocalDateTime` as the capability predicate rather than adding a new field | Made | It is already computed unconditionally as `null` exactly when `consumedUtcOffsetMinutes` is absent — the identical condition `QuickAddMealLogEditController.editableLocalDateTime` checks — and is independent of the `showMealTimes` display preference, so it is a correct, already-available signal | Claude |

## 4. Architecture Design

### Chosen Approach

Six independent, minimal, feature-local fixes; no shared new abstraction introduced since the six defects do not share a root cause.

### Ownership And Data Flow

Unchanged from TNYX-204: `MealDiaryHistoryView`/`MealDiaryMealCard` render state and emit `onEdit`; `MealDiaryPage` orchestrates the canonical read-before-edit and the editor sheet; `QuickAddMealLogEditController` owns submit/validation/conflict semantics.

### Alternative Rejected

- RF3: rewriting `TioSheet`/the whole Add Food sheet shell was rejected — the smallest fix keeps `TioSheet`'s own painted surface untouched and only relocates the bottom-inset fill to a sibling strip below it.
- RF4: making `_SectionNutritionSummary` fabricate an abbreviated value under pressure was rejected (explicitly forbidden by TNYX-204's no-fabrication rule); scaling the same value down visually preserves truthful content.

### Failure And Accessibility States

RF6 removes the Edit affordance entirely (card becomes read-only, no overflow popup at all) rather than rendering a disabled-looking control, matching TNYX-204's existing "no dead action" rule.

## 5. Implementation Plan

- [x] RF1 — gate future-time validation on an actual time change in `quick_add_meal_log_edit_controller.dart`.
- [x] RF2 — reserve the title/overflow band whenever `edit != null` in `meal_diary_meal_card.dart`.
- [x] RF3 — limit the Add Food bottom-inset fill to the inset strip only in `add_food_sheet.dart`.
- [x] RF4 — clamp the section-title `ConstrainedBox` to non-negative width and make the summary shrink-safe in `meal_diary_history_view.dart`.
- [x] RF5 — add a page-level in-flight guard around `_openQuickEdit` in `meal_diary_page.dart`.
- [x] RF6 — gate card/overflow Edit on `entry.loggedLocalDateTime != null` in `meal_diary_history_view.dart`.
- [x] Focused tests for all six.
- [x] Full Nutrition + App analyze/test, `git diff --check`.

## 6. Quality Review

### Validation Run

```text
See Final Handoff below for the actual commands and results.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| RF1 | P2 | Resolved | `submit()` applied future-time validation to the reconstructed stored wall-clock unconditionally, so an unrelated edit after device timezone travel could be falsely rejected as a future meal time | PR #263 head `366410e9` | Future-time validation now only runs when `draft.consumedLocalDateTime != editableLocalDateTime(_baseEntry)`, reusing the exact comparison `_buildInput` already makes for `timeChanged`. Unchanged time always preserves canonical `consumedAt`/offset facts through the existing `_buildInput` logic, untouched by this fix |
| RF2 | P2 | Resolved | The 48dp title/overflow-clearance band existed only when `mealName` or the note indicator was visible, while the overflow popup still occupied the top-right 48×48 region regardless, so a nameless/no-note actionable card placed its first nutrition row under the overflow target | PR #263 head `366410e9` | Band condition extended to `mealName != null \|\| noteIndicatorVisible \|\| edit != null`; the existing `Spacer()`/trailing-`SizedBox` fallbacks already handle the name-absent case correctly, so no further change was needed. 120dp media, 40dp fallback icon and card height are untouched |
| RF3 | P2 | Resolved | Wrapping the whole `SafeArea` subtree in an opaque `ColoredBox` painted behind `TioSheet`'s own rounded top corners (which already paint `colors.surface` with `BorderRadius.vertical(top: ...)`), squaring them against the transparent modal route | PR #263 head `366410e9` | Removed the wrapping box. The builder returns a `Stack` with the original, unmodified `SafeArea(top: false)` (bottom `true`, as before — its own bottom padding already reserves the inset) as the sizing child, plus a `Positioned(bottom: 0, height: MediaQuery.paddingOf(context).bottom)` `ColoredBox` sibling that paints only inside that already-reserved, already-unrounded strip. An earlier `Column`-based attempt (`SafeArea(bottom: false)` + an appended sibling `SizedBox`) was reverted after it broke three unrelated top-inset tests: a `SingleChildScrollView` given a bounded main-axis constraint inside a `mainAxisSize: min` `Column` claims the *entire* budget rather than shrink-wrapping its content, leaving no room for the appended strip and overflowing by the strip's height. `Stack` avoids this because a `Positioned` child does not contribute to the `Stack`'s own size at all, so the sizing math matches the pre-existing, already-correct `SafeArea` behavior exactly |
| RF4 | P2 | Resolved | `constraints.maxWidth - TioSpacing.sm` could go negative when a wide non-flexible `_SectionNutritionSummary` left the title `LayoutBuilder` less than 8dp, throwing a `BoxConstraints` layout assertion under large accessibility text scale | PR #263 head `366410e9` | Two changes. First, the same clamp as the title's own `ConstrainedBox`: `.clamp(0.0, double.infinity)`, eliminating the negative-constraint crash outright. Second, an *outer* `LayoutBuilder` now wraps the whole header `Row` (title region + summary together), and the summary is capped via `ConstrainedBox(maxWidth: (headerConstraints.maxWidth - TioSpacing.sm).clamp(0.0, double.infinity))` + `FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerEnd)`, so a pathologically wide summary shrinks instead of forcing a `RenderFlex` overflow on the outer Row. A no-op at any normal size, since the cap is the header's own full width. An initial attempt instead wrapped the summary directly in `Flexible` (sharing flex:1 with the title's `Expanded`) — reverted because Flutter's flex algorithm gives a tight `Expanded` sibling its *entire* allotted share regardless of what it needs, while a loose `Flexible` that ends up smaller than its share leaves the difference as *trailing slack at the row's end* rather than handing it back — breaking the pre-existing "summary flush at the content edge" geometry even at normal widths. The `ConstrainedBox`+`FittedBox` approach avoids the flex system entirely, so the summary stays a plain intrinsic-width sibling exactly as before whenever it fits |
| RF5 | P2 | Resolved | `_openQuickEdit` had no in-flight guard around its `await readById(id)`, so rapid repeated taps (same card or two different cards) could launch concurrent reads and stack two Quick Edit sheets, leaving one behind with a stale revision | PR #263 head `366410e9` | Added a page-level `_isOpeningQuickEdit` boolean. Set before the canonical read; cleared on every early return (missing repositories, read error, not-found, not-editable) and immediately after `showQuickAddEditorSheet` is *called* — that call synchronously installs the modal barrier, so the framework itself blocks further page taps from that point on; holding the guard through the sheet's full open duration would have blocked a legitimate later edit right after this one closes |
| RF6 | P2 | Resolved | A canonical row with `consumedTimezoneId` set but `consumedUtcOffsetMinutes` null is valid per the MealLog contract, but every rendered card exposed working-looking card-tap and overflow Edit that later failed with "Editing is not available" | PR #263 head `366410e9` | `_MealEntryCard`'s single shared `open` callback (already passed to both `onTap` and `onEdit`) now additionally requires `entry.loggedLocalDateTime != null` — the same offset-availability signal `QuickAddMealLogEditController.editableLocalDateTime` computes, already present on the read model and independent of the `showMealTimes` display preference. `MealDiaryMealCard` already omits the whole overflow popup (not just the `Edit` item) when `onEdit` is null, so such a row renders read-only with no overflow control at all rather than a dead one |

Use `Open`, `Resolved`, or `Deferred`.

## 7. Final Handoff

### Changed Files

- `apps/features/nutrition/lib/src/meal_logging/quick_add_meal_log_edit_controller.dart` — RF1.
- `apps/features/nutrition/lib/src/meal_diary/presentation/widgets/meal_diary_meal_card.dart` — RF2.
- `apps/features/nutrition/lib/src/meal_logging/presentation/widgets/add_food_sheet.dart` — RF3.
- `apps/features/nutrition/lib/src/meal_diary/presentation/widgets/meal_diary_history_view.dart` — RF4, RF6.
- `apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_page.dart` — RF5.
- `apps/features/nutrition/test/meal_logging/quick_add_manual_edit_controller_test.dart` — RF1 tests.
- `apps/features/nutrition/test/meal_diary/meal_diary_history_view_test.dart` — RF2, RF4, RF6 tests.
- `apps/features/nutrition/test/meal_logging/meal_diary_add_food_flow_test.dart` — RF3 test rewritten for the new composition.
- `apps/features/nutrition/test/meal_logging/quick_add_edit_flow_test.dart` — RF5 tests.
- `.ai/tasks/tnyx-210-post-merge-meal-diary-quick-edit-p2-corrections.md` — this brief.

No `apps/core` file changed. No Supabase/schema/RLS file changed.

### Actual Behavior

All six post-merge P2 findings from the Codex review on PR #263 head `366410e9` are fixed: an unrelated Quick Edit save no longer fails after timezone/clock travel when the meal's own time is unchanged; an unnamed/no-note actionable card always reserves the overflow band so its nutrition rows never collide with it; the Add Food sheet's bottom-inset fill no longer squares TioSheet's rounded top corners; the section header can no longer construct a negative width or overflow under a long aggregate summary; rapid repeated Quick Edit taps (same card or two different cards) can no longer stack two editor sheets; and a canonical row that cannot reconstruct an exact editable local time (timezone-ID-only, no offset) no longer exposes a card-tap or overflow Edit action at all.

### Known Limitations

**Newly discovered, explicitly out of scope for this task:** while constructing an adversarial RF4 regression test (a single large-digit entry, e.g. `999999`/`99999` kcal/g, at the card's actual ~288dp content width), `MealDiaryMealCard`'s own `_MealDetailRow` (`meal_diary_meal_card.dart`) overflows independently of the section header — a `RenderFlex overflowed by 29 pixels` in the card's own Calories/Protein row, reproduced both through the full `MealDiaryHistoryView` and in isolation with `showMealSectionNutrition: false` (confirming it is unrelated to the header fix). This is a **card-level**, not header-level, defect and is not one of the six RF items in scope here. It was not fixed in this task per the explicit "Do NOT widen scope" instruction. The RF4 regression test below instead uses a long *aggregate* achieved through many modest-value entries (safe on each individual card) rather than one entry with extreme digits, which reproduces the header's specific negative-constraint/overflow risk without tripping this separate card issue. Recommended as a follow-up Linear issue before this card composition is exercised at large accessibility text scales in production.

### Final Status

`REVIEW` — implementation, focused tests (13 new: 2 RF1, 1 RF2, 3 RF4, 1 RF6, 3 RF5, plus the rewritten RF3 test) and full validation complete: `apps/features/nutrition` analyze clean + 705 tests passed (was 695), `apps/app` analyze clean + 319 tests passed (unchanged, Core untouched), `git diff --check` clean. Exact-head CI pending at handoff time — see the conversation's Final Handoff message for the exact pushed SHA and CI result.
