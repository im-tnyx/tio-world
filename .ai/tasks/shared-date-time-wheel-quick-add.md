# Shared Core DateTime Wheel + Quick Add Local Draft

**Status:** In progress
**Primary owner:** `apps/core` reusable picker + `apps/features/nutrition` Quick Add adapter/presentation
**Affected platforms:** Flutter Android + iOS phone UI; future Workout reuse is contract-only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice; approved product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:** Owner prompt dated 2026-09-06 explicitly approves this bounded Core DateTime wheel + Nutrition Quick Add local-draft slice.
**Approved product/UI/data-shape boundaries:** Replace the rejected inline card with a shared Core DateTime popup/card anchored to `MealLogActionFooter`; use a theme-adapted native `CupertinoDatePicker(mode: dateAndTime, use24hFormat: false)` drum with no visible column headers; initialize each new Quick Add from one current-local minute snapshot; update the local draft/footer live; preserve the draft across popup close/reopen; cap selection at local current minute; keep the footer concrete and 24-hour formatted.
**Explicit non-changes:** No Supabase/schema/RLS/Storage change; no `services/api`; no MealLog persistence; no timezone/UTC/DST persistence policy; no TNYX-113/TNYX-115 implementation; no meal categories; no AI/voice/photo/search/recent/saved meals; no Workout UI; no TNYX-157 theme migration; no merge; no mutation of `docs/supabase-android-studio-qa-run` or preserved commit `7fe89682`.

## Active Handoff

**Planning owner:** Codex `/root`
**Implementation owner:** Codex `/root`
**Review owner:** Codex `/root` quality-review pass; GitHub review remains external
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-06; `origin/main` fetched and clean at `8eace9977c155661a339ef59187dd62028b9988e`
**Branch:** `codex/shared-date-time-wheel-quick-add`
**Implementation SHA:** `4562cbe391f4cd8854ace35a7a2ccf46001a6f54`
**Observed working-tree state:** Clean at the validated implementation SHA before this final handoff update
**Observed uncommitted/dirty files:** Owner-approved popup correction, its focused tests, and canonical UI-contract documentation; no unrelated work.
**PR / tracker:** GitHub PR #217 is open against `main`; TNYX-114 remains Backlog and blocked by TNYX-113; TNYX-158 is Done; no Linear mutation was made or required
**Current implementation state:** The prior inline card and four-column custom wheel are superseded by owner device UI review; popup/card and Cupertino-style correction is active
**Relevant execution surface:** `TioDateTimePickerPopup` and `TioDateTimeWheelPicker` in Core; Nutrition Quick Add modal/editor/footer
**Validation completed at SHA:** `4562cbe391f4cd8854ace35a7a2ccf46001a6f54` (GitHub Actions run `34014099801`)
**Validation remaining:** Full repository validation, exact-head CI, review-thread audit, and owner/device screenshot evidence
**Current blocker:** None
**Open review finding IDs:** QR-8 and QR-9 are resolved; owner presentation findings require the approved popup/card and wheel correction
**Next exact action:** Complete validation, then push the correction to existing Draft PR #217 without merging; device alignment remains required before UI PASS.

## Global UI / Design-System Guardrail

The validated design-system ownership task and `apps/core/lib/src/theme/README.md` were read before source changes. Existing Tio geometry, theme roles, cards, editor-sheet behavior, calendar asset treatment, and wheel tokens remain authoritative. This slice changes only the owner-approved inline picker interaction and the minimum Core reuse extraction needed to avoid a fourth wheel implementation.

## Owner Device UI Correction — 2026-09-06

Owner device review rejected the committed inline `TioCard` inside
`TioEditorSheet.content` and the visible custom `Date | Hour | Minute | AM/PM`
header/column composition. This correction supersedes that presentation only;
the route-local Quick Add draft, one-shot current-local snapshot, concrete
footer, fresh future-time bound, disabled `Log Meal`, and no-persistence scope
remain locked.

The approved direction is one reusable Core DateTime popup/popover card over
the editor, anchored to a generic date/time control without changing editor
body scroll extent. Its wheel uses a Tio-owned, theme-adapted wrapper around
Flutter `CupertinoDatePicker(mode: dateAndTime, use24hFormat: false)`. Meal,
future Meal Editor, future Weight editor, and future Workout editor are reuse
consumers; this correction implements no Weight or Workout feature screen.

The Flutter `3.44.6` source audit verified: `minimumDate` may be null,
`maximumDate` is a hard selectable DateTime boundary, invalid candidates do
not call the callback and settle back, `selectionOverlayBuilder` is supported,
and Cupertino's picker already emits `HapticFeedback.selectionClick()`. Since
`initialDateTime` is initialization-only, the Core wrapper re-keys only after
a caller constraint resolves a candidate to a different value or an external
controlled value/bound changes; normal valid detents do not recreate it.

## 1. Discovery

### User Outcome

A new Quick Add opens with one stable current-local DateTime draft. Tapping its footer date/time control reveals a shared Tio wheel inline; wheel changes remain coherent across date/hour/minute/AM-PM, update the footer immediately, survive collapse/reopen, and cannot retain a future Meal Log time.

### Success Criteria

- Core owns one reusable, theme-aware DateTime wheel and generic wheel-column mechanics.
- Existing Tio wheel geometry/pill/haptic behavior is reused rather than independently recreated.
- Quick Add no longer inherits the Meal Diary's historical selected date.
- No nested modal or picker confirmation control is introduced.
- The Date wheel stops at Today; past dates remain available without inventing a product-visible earliest date.
- Today future-time attempts resolve to a fresh current-local minute and visibly resynchronize every column/footer.
- Numeric/text draft values survive picker open/close and DateTime updates.
- Small viewport, keyboard, safe-area, Light/Dark/OLED/System, analysis, and tests remain green.

### Scope

- Core generic wheel column/frame extraction where proven necessary by the live audit.
- Core coherent DateTime wheel composition and public export.
- Nutrition-local clock boundary, draft DateTime state, Meal constraint adapter, inline presentation, footer interaction/formatting.
- Focused Core/Nutrition tests and documentation/task handoff updates.

### Non-Goals

- Any durable MealLog/domain/database/backend/timezone implementation.
- Any Workout UI or Workout business/persistence rule.
- Any new product copy, wheel title, nested route, or enabled Log Meal action.
- Any unrelated refactor or branch cleanup.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `TioWheelPickerTokens`, `TioWeightWheel`, `TioDobWheelPicker`, onboarding height wheel, `TioEditorSheet`, `MealLogActionFooter`, `QuickAddEditorSheet`, Meal Diary call site, public Core barrels, package manifests and current tests.
- Existing pattern to follow: `TioWheelPickerTokens` fixes 200dp viewport, 48dp selected row, 44dp item extent, perspective/diameter; selected surface is semantic `surfaceVariant`; haptic is `HapticFeedback.selectionClick()`; `TioEditorSheet` pins actions and scrolls content independently.
- Tests or validation already present: Core wheel token/weight/DOB/editor-sheet widget tests; Nutrition Add Food/Quick Add flow tests; PR #216 real-app Light/Dark/OLED theme regression tests.
- Fresh GitHub truth: `origin/main = 8eace9977c155661a339ef59187dd62028b9988e`; PR #216 is merged at that SHA; open PR count is zero; baseline commit is an ancestor of current main.
- Fresh Linear truth: TNYX-114 is Backlog and blocked by TNYX-113; TNYX-113 is Backlog and blocked by TNYX-54/TNYX-66; TNYX-158 is Done. This approved presentation-only precursor does not change those states.
- Preserved local branch truth: `docs/supabase-android-studio-qa-run` remains at `7fe896820c8f176b5049df4fe84fc9acea5933b1`.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Dedicated Linear issue | Not required | Repo governance requires a focused `.ai/tasks` brief, not a new external issue; owner prohibited inventing one and explicitly approved this bounded scope. | Repository governance + owner |
| TNYX-114 state | Keep Backlog/blocked | This is only presentation/local draft and cannot satisfy persistence/timezone acceptance. | Owner + Linear dependency graph |
| Core vs Nutrition ownership | Approved | Core owns generic coherent DateTime UI; Nutrition owns the clock snapshot and Meal future-time rule. | Owner |
| Date lower bound | No invented bound | An unbounded-past/optional-minimum Core date column avoids fabricating a Meal product rule. | Owner prompt |
| UI minute precision | Truncate snapshots/resolution to minute | Candidate wheels have zero seconds; comparing against real current time and snapping to its minute floor avoids invisible seconds affecting visible validity. | Implementation |

## 4. Architecture Design

### Chosen Approach

Extract controlled `TioWheelPickerColumn` mechanics plus a shared selected-row frame in Core, then compose `TioDateTimeWheelPicker` from four controlled columns. The Date column is bounded forward by caller-supplied `maximumDate`, optionally bounded in the past, and otherwise scrolls backward without an arbitrary product minimum. Looping columns report signed detent deltas so Core applies hour/minute/AM-PM changes to one coherent DateTime and synchronizes dependent columns programmatically without duplicate haptics.

Nutrition owns a local `DateTime Function()` clock seam. It snapshots once in `initState`, truncates to minute precision, and passes a resolver to Core that compares each attempted candidate against a fresh clock reading. A future candidate resolves to the fresh minute floor; only the resolved value reaches the Quick Add draft/footer.

Quick Add places the picker card at the tail of `TioEditorSheet.content`, immediately before the pinned footer. Opening it schedules `Scrollable.ensureVisible`, so short/keyboard-raised viewports can bring the wheel into view without nesting a modal or moving the commit region into the scroll view.

### Ownership and Data Flow

```text
Quick Add open -> Nutrition clock snapshot -> local DateTime draft
footer tap -> inline TioCard -> Core TioDateTimeWheelPicker
user detent -> Core coherent candidate -> Nutrition constraint resolver
resolved DateTime -> local draft -> controlled wheel columns + concrete footer
```

### Alternative Rejected

`CupertinoDatePicker` is being audited but is not the preferred implementation because the contract needs Tio-owned selected-row geometry/theme/haptics, controlled external resynchronization for feature-level snap-back, signed cascading detents, and an optional unbounded-past/maximum-Today date model. Wrapping it would either leak Cupertino visual behavior or require re-keying/recreating internal state for controlled snap-back.

### Failure and Accessibility States

- Footer remains an enabled 48dp semantic button; its label exposes the concrete selected date/time and whether the picker is expanded.
- Wheel columns expose semantic labels/values and remain theme-derived.
- Future attempts resolve atomically so footer and columns never settle incoherently.
- Log Meal and Meal type remain disabled with their existing semantics.
- Existing editor root-navigator and safe-area behavior remains intact.

## 5. Implementation Plan

- [x] Add/migrate the generic Core wheel column/frame without changing existing picker appearance.
- [x] Add public `TioDateTimeWheelPicker` with coherent cascading, bounds, controlled synchronization, semantics, and haptic discipline.
- [x] Integrate the local Quick Add DateTime draft, inline card, footer toggle/format, fresh future snap-back, and ensure-visible behavior.
- [x] Add focused Core and Nutrition tests, including viewport/keyboard and retained form values.
- [x] Update Core theme/component contract and this task handoff.
- [x] Run complete validation and exact scope audit.
- [x] Commit, push, open a focused PR against current `main`, inspect review threads/CI, address valid findings, and do not merge.

## 6. Quality Review

### Validation Run

```text
PASS: git diff --check
PASS: local focused Core picker test file, 12/12 tests
PASS: local focused Nutrition Quick Add flow test file, 54/54 tests
PASS: GitHub Actions run 34014099801 at 4562cbe391f4cd8854ace35a7a2ccf46001a6f54
  - Flutter analyze: 15/15 packages, no issues
  - Dart analyze: 1/1 package, no issues
  - Flutter test: 13/13 test-bearing packages, 1,837 tests passed
  - Dart test: 1/1 package, 38 tests passed
  - Total automated tests: 1,875 passed
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| QR-1 | P1 | Resolved | Quick Add picker card used only the scroll-target `GlobalKey`, so the stable public test key was absent. | working tree | Kept the `GlobalKey` on `KeyedSubtree` and added `quick-add-date-time-picker-card` to `TioCard`. |
| QR-2 | P1 | Resolved | A fully visible 236dp picker is impossible in the deliberately smaller keyboard viewport; the test asserted an impossible geometry rather than usability. | working tree | Assert visible intersection, centered wheel reachability/interaction, pinned footer, and no overflow. |
| QR-3 | P2 | Resolved | The first generic weight migration omitted the old lb upper/lower clamp on decimal changes. | working tree | Restored canonical kg bounds after lb conversion. |
| QR-4 | P1 | Resolved | First PR CI stopped in Core analysis on one extra parenthesis and nullable callback indices that were not promoted after `??=`. | `3d450e09` | Rewrote the decimal getter and resolved nullable inputs into non-null local values; next exact-head CI pending. |
| QR-5 | P1 | Resolved | A boundary overscroll could report an unchanged raw index or bounded DateTime, causing a no-op domain callback and possible selection haptic. | `b92ec6b3`, `b758eb48` | Generic column ignores zero-detent callbacks and DateTime composition suppresses unresolved no-op candidates; resolver snap-back still synchronizes. |
| QR-6 | P0 | Resolved | Flutter's null-count builder requested raw index `-1`, so the unbounded-past Date wheel rendered one day after its maximum. | `f5705f48` | Null-count non-looping delegates now terminate below raw index zero while keeping all positive historical indices available. |
| QR-7 | P2 | Resolved | Nutrition tests still expected the formerly disabled date control's compact height and no tap semantics action. | `12c74b43` | Assert one-row center alignment for the enabled 48dp target and require its accessibility tap action. |
| QR-8 | P1 | Resolved | Calendar bounds were applied before the feature resolver, so a cross-day time detent could transplant tomorrow's time onto Today and hide a future attempt. | `74da6a92` | At `4562cbe3`, resolve the original minute candidate first; if the resolved day remains out of range, keep the current boundary value. Cross-day resolver and boundary-rollover tests pass in CI. |
| QR-9 | P2 | Resolved | The Quick Add maximum calendar date refreshed on pointer-down only, so an editor open across midnight could retain yesterday's bound for assistive/keyboard users. | `74da6a92` | At `4562cbe3`, add route-owned next-midnight refresh plus app lifecycle rescheduling; retain pointer refresh for immediate clock adjustments. The no-pointer midnight test passes in CI. |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/shared-date-time-wheel-quick-add.md`
- `apps/core/lib/src/ui/components/pickers/*`
- `apps/core/lib/src/ui/components/components.dart`
- `apps/core/lib/src/ui/components/sheets/tio_{dob_picker_bottom_sheet,weight_wheel}.dart`
- `apps/core/test/ui/components/tio_date_time_wheel_picker_test.dart`
- `apps/features/onboarding/lib/src/presentation/widgets/wheels/onboarding_height_wheel.dart`
- `apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_page.dart`
- `apps/features/nutrition/lib/src/meal_logging/presentation/widgets/{meal_log_action_footer,quick_add_editor_sheet}.dart`
- `apps/features/nutrition/test/meal_logging/meal_diary_add_food_flow_test.dart`
- `apps/app/test/app/meal_logging_modal_theme_test.dart`
- `apps/core/lib/src/theme/README.md`
- `docs/MODULE_OWNERSHIP.md`
- `docs/screens/meal-diary.md`

### Actual Behavior

Shared Core wheel mechanics now back DOB, weight, onboarding height, and the new coherent DateTime composition. Quick Add takes a one-shot current-local minute draft, renders concrete footer text, expands the wheel inline, retains all route-local form state, and snaps future attempts to a fresh current-local minute. No persistence or submit path was added.

### Known Limitations

No persistence; no edit-existing MealLogEntry behavior; no timezone/instant semantics; no Workout UI; Log Meal remains disabled.

### Final Status

`REVIEW`

## Owner Correction Implementation — 2026-09-06

This section supersedes the earlier inline-card/custom-column architecture and
its associated validation notes.

- Reverted the incidental DOB, weight, and onboarding-height generic-wheel
  migrations; no unrelated existing picker changes remain in scope.
- Added `TioDateTimePickerPopup`, a generic `OverlayPortal` card anchored to a
  caller-owned control. It floats over the current editor route and does not
  enter or expand `TioEditorSheet.content`.
- Replaced the four-header custom wheel with the controlled
  `TioDateTimeWheelPicker` wrapper around
  `CupertinoDatePickerMode.dateAndTime` using `use24hFormat: false`.
  Native picker geometry owns the single selected-row overlay, wider date
  column, aligned AM/PM, and cylindrical wheel presentation.
- Refined selection pill z-order: moved the selection pill behind the wheel text
  via a Stack to match the DOB/weight picker pattern, suppressing native top overlay.
- Aligned selection pill geometry with tokens: height set to 44dp (`TioSize.dp44`),
  horizontal margin set to `TioSpacing.md` (12dp).
- Aligned popup card padding to `TioSpacing.xs` (4dp) and anchor gap to `TioSpacing.sm` (8dp).
- Quick Add retains its route-local draft and disabled/no-persistence contract.
  Its selectable maximum refreshes to the current local minute while the popup
  is open and before picker interaction; no lower date bound is invented.

Focused validation after the correction:

```text
PASS: apps/core/test/ui/components/tio_date_time_wheel_picker_test.dart (4)
PASS: apps/features/nutrition/test/meal_logging/meal_diary_add_food_flow_test.dart (50)
PASS: apps/app/test/app/meal_logging_modal_theme_test.dart (2)
```

Device/emulator screenshot comparison against the owner reference remains
required before reporting UI PASS or resolving the owner presentation finding.
