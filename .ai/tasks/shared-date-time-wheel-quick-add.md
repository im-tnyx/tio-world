# Shared Core DateTime Wheel + Quick Add Local Draft

**Status:** In progress
**Primary owner:** `apps/core` reusable picker + `apps/features/nutrition` Quick Add adapter/presentation
**Affected platforms:** Flutter Android + iOS phone UI; future Workout reuse is contract-only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice; approved product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:** Owner prompt dated 2026-09-06 explicitly approves this bounded Core DateTime wheel + Nutrition Quick Add local-draft slice.
**Approved product/UI/data-shape boundaries:** Add a shared Core coherent `Date | Hour | Minute | AM/PM` wheel and reveal it inline above `MealLogActionFooter`; initialize each new Quick Add from one current-local minute snapshot; update the local draft/footer live; preserve the draft across collapse/reopen; cap the Meal date wheel at local Today; snap future time attempts to fresh current local time; keep the footer concrete and 24-hour formatted.
**Explicit non-changes:** No Supabase/schema/RLS/Storage change; no `services/api`; no MealLog persistence; no timezone/UTC/DST persistence policy; no TNYX-113/TNYX-115 implementation; no meal categories; no AI/voice/photo/search/recent/saved meals; no Workout UI; no TNYX-157 theme migration; no merge; no mutation of `docs/supabase-android-studio-qa-run` or preserved commit `7fe89682`.

## Active Handoff

**Planning owner:** Codex `/root`
**Implementation owner:** Codex `/root`
**Review owner:** Codex `/root` quality-review pass; GitHub review remains external
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-06; `origin/main` fetched and clean at `8eace9977c155661a339ef59187dd62028b9988e`
**Branch:** `codex/shared-date-time-wheel-quick-add`
**HEAD SHA:** `8eace9977c155661a339ef59187dd62028b9988e`
**Observed working-tree state:** Clean before this brief; this brief is the first task-owned change
**Observed uncommitted/dirty files:** `.ai/tasks/shared-date-time-wheel-quick-add.md`
**PR / tracker:** No open GitHub PRs; PR #216 merged as baseline; TNYX-114 remains Backlog and blocked by TNYX-113; TNYX-158 is Done; no Linear mutation authorized or required
**Current implementation state:** Core extraction and Nutrition local-draft interaction implemented; remote Flutter validation pending
**Relevant execution surface:** `apps/core` wheel primitives and `TioDateTimeWheelPicker`; Nutrition Quick Add modal/editor/footer
**Validation completed at SHA:** Baseline/history/overlap checks only
**Validation remaining:** Focused Core/Nutrition tests; all Flutter package analyze/tests; `apps/shared` Dart analyze/test; `git diff --check`; scope/path audit; PR exact-head CI/review status
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Commit/push the bounded diff, open the PR, and use its Flutter CI because the configured local SDK path is unavailable.

## Global UI / Design-System Guardrail

The validated design-system ownership task and `apps/core/lib/src/theme/README.md` were read before source changes. Existing Tio geometry, theme roles, cards, editor-sheet behavior, calendar asset treatment, and wheel tokens remain authoritative. This slice changes only the owner-approved inline picker interaction and the minimum Core reuse extraction needed to avoid a fourth wheel implementation.

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
- [ ] Run complete validation and exact scope audit.
- [ ] Commit, push, open a focused PR against current `main`, inspect review threads/CI, and do not merge.

## 6. Quality Review

### Validation Run

```text
PASS: git diff --check
UNAVAILABLE LOCALLY: Flutter/Dart analyze and tests; PATH has no toolchain,
FLUTTER_ROOT points to absent G:\dev\flutter, the approved local tool catalog
has no Flutter route, and the available Melos shim cannot run without dart.
PENDING: GitHub Flutter CI exact-head full analyze/test matrix.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| QR-1 | P1 | Resolved | Quick Add picker card used only the scroll-target `GlobalKey`, so the stable public test key was absent. | working tree | Kept the `GlobalKey` on `KeyedSubtree` and added `quick-add-date-time-picker-card` to `TioCard`. |
| QR-2 | P1 | Resolved | A fully visible 236dp picker is impossible in the deliberately smaller keyboard viewport; the test asserted an impossible geometry rather than usability. | working tree | Assert visible intersection, centered wheel reachability/interaction, pinned footer, and no overflow. |
| QR-3 | P2 | Resolved | The first generic weight migration omitted the old lb upper/lower clamp on decimal changes. | working tree | Restored canonical kg bounds after lb conversion. |

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

`PARTIAL`
