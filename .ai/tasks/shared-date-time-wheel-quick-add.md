# Shared Core DateTime Wheel + Quick Add Local Draft

**Status:** In progress
**Primary owner:** `apps/core` reusable picker + `apps/features/nutrition` Quick Add adapter/presentation
**Affected platforms:** Flutter Android + iOS phone UI; future Weight and Workout reuse is contract-only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice; approved product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:** Owner prompts and review dated 2026-09-06 explicitly approve the shared Core DateTime popup card + Nutrition Quick Add local-draft slice.
**Approved product/UI/data-shape boundaries:** Reusable Core DateTime popup card (`TioDateTimePickerPopup`) anchored to `MealLogActionFooter` over the Quick Add editor; theme-adapted native `CupertinoDatePicker(mode: dateAndTime, use24hFormat: false)` drum wrapped in Core (`TioDateTimeWheelPicker`) with no visible column headers; single continuous selection highlight; one-shot current-local minute snapshot on new Quick Add; live update of local draft and footer; draft retained across popup dismiss and reopen; selection capped at current local minute with fresh-clock snap-back; concrete 24-hour footer text.
**Explicit non-changes:** No Supabase/schema/RLS/Storage changes; no `services/api`; no MealLog persistence; no timezone/UTC/DST persistence policy; no TNYX-113/TNYX-115 implementation; no meal categories; no AI/voice/photo/search/recent/saved meals; no Weight feature UI; no Workout feature UI; no TNYX-157 theme migration; no merge; no mutation of `docs/supabase-android-studio-qa-run` or preserved commit `7fe89682`.

## Active Handoff

**Planning owner:** Codex `/root`
**Implementation owner:** Codex `/root`
**Review owner:** Codex `/root` quality-review pass; GitHub review remains external
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-06; `origin/main` fetched at `8eace9977c155661a339ef59187dd62028b9988e`
**Branch:** `codex/shared-date-time-wheel-quick-add`
**Implementation SHA:** `c35225edc7c8d578e0ac03a50d475784e5065e08`
**Observed working-tree state:** Compact wheel-height token follow-up is modified in feature/core files; unrelated local `pubspec.lock` modification preserved
**PR / tracker:** GitHub PR #217 is open (Draft) against `main`; TNYX-114 remains Backlog and blocked by TNYX-113; TNYX-158 is Done
**Current implementation state:** `TioDateTimePickerPopup` (Overlay card) and `TioDateTimeWheelPicker` (`CupertinoDatePicker` wrapper) active; the compact DateTime selection pill uses `TioWheelPickerTokens.compactSelectionHeight` (44dp) while the standard 48dp shared token remains intact. The token follow-up is locally modified after the previously validated implementation SHA.
**Relevant execution surface:** `TioDateTimePickerPopup` and `TioDateTimeWheelPicker` in Core; Nutrition Quick Add modal/editor/footer
**Validation completed at SHA:** `c35225edc7c8d578e0ac03a50d475784e5065e08` (GitHub Actions run `34027402550` — all checks passed)
**Validation remaining:** Owner device screenshot visual acceptance
**Current blocker:** None
**Open review finding IDs:** QR-1 to QR-9 resolved; owner presentation findings resolved in code, pending owner device UI visual acceptance
**Next exact action:** Await owner device visual acceptance before marking PR Ready for Review.

## Global UI / Design-System Guardrail

The validated design-system ownership task and `apps/core/lib/src/theme/README.md` were inspected before source changes. Existing Tio geometry, semantic theme roles, cards, editor-sheet behavior, calendar asset treatment, and wheel tokens remain authoritative.

## 1. Discovery

### User Outcome

A new Quick Add opens with one stable current-local DateTime draft. Tapping its footer date/time control opens a reusable Tio DateTime popup card over the editor without expanding the editor body or opening a nested bottom-sheet route. The picker presents a unified Cupertino-style date+time drum without column headings, lines up baseline values, updates the footer live, retains draft state across popup dismiss/reopen, and snaps future time attempts back to a fresh current-local minute.

### Success Criteria

- Core owns `TioDateTimePickerPopup` (reusable anchored overlay card) and `TioDateTimeWheelPicker` (controlled, theme-adapted Cupertino date+time drum).
- No visible column headers (no Date, Hour, Minute, AM/PM headers).
- Selected row shares one horizontal baseline and coherent selection pill highlight.
- Date column is widest; AM/PM is part of the same drum.
- Quick Add snapshots current-local DateTime once on open; Diary historical selected date is not inherited.
- Untouched draft remains frozen; subsequent picker interactions check against fresh real current time.
- Future calendar dates are unavailable; future time on Today snaps back to current minute.
- Editor body does not expand or scroll when popup opens.
- Tapping outside dismisses popup; draft is preserved.
- Log Meal remains disabled; no persistence or Supabase changes.
- Analyzers, tests, and CI pass.

### Scope

- Core `TioDateTimePickerPopup` and `TioDateTimeWheelPicker`.
- Nutrition Quick Add draft, resolver, footer format, and popup presentation.
- Focused Core and Nutrition unit/widget tests.
- Task brief and PR body documentation.

### Non-Goals

- No MealLog persistence, storage, or backend logic.
- No Weight or Workout feature UI.
- No new product copy or enabled Log Meal action.
- No unrelated refactoring or branch cleanup.

## 2. Codebase Exploration

### Verified Evidence

- Source inspected: `TioWheelPickerTokens`, `TioEditorSheet`, `MealLogActionFooter`, `QuickAddEditorSheet`, `meal_diary_page.dart`, public Core barrels, manifests, and existing tests.
- CupertinoDatePicker capabilities in Flutter 3.44.6: supports `mode: CupertinoDatePickerMode.dateAndTime`, `use24hFormat: false`, `maximumDate`, `minimumDate`, `selectionOverlayBuilder`. Emits native selection click on iOS.
- Existing tokens: `TioWheelPickerTokens.viewportHeight` (200dp), `selectionHeight` (48dp), `compactSelectionHeight` (44dp), `selectionHorizontalMargin` (16dp / `TioSpacing.lg`), `itemExtent` (44dp), semantic `surfaceVariant`.

## 3. Clarification

### Decisions Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Presentation: Popup Card | Approved | Reusable `OverlayPortal` card over editor; does not expand editor body or introduce another bottom-sheet route. | Owner UI review |
| Drum: CupertinoDatePicker | Approved | Single aligned drum (Date, Hour, Minute, AM/PM) with native cylindrical depth and perspective; no visible column headers. | Owner UI review |
| Controlled Resync | Approved | Controlled re-key via revision counter on resolver snap-back, external value change, or maximum bound change. Valid detents do not recreate drum. | Architecture |
| Future Resolution | Approved | One-shot snapshot on open; future attempts checked against fresh current-local minute floor. | Owner contract |
| Haptics | Approved | Native iOS tick preserved; Android receives explicit `HapticFeedback.selectionClick()` on settled minute change. | Platform review |

## 4. Architecture Design

### Core Components

1. `TioDateTimePickerPopup`:
   - Anchored overlay card built with `OverlayPortal`.
   - Positions floating `TioCard` above or below anchor based on viewport geometry.
   - Outside tap dismisses popup; tapping inside is absorbed.
   - Child layout and scroll extent remain completely unaffected.

2. `TioDateTimeWheelPicker`:
   - Wraps `CupertinoDatePicker(mode: CupertinoDatePickerMode.dateAndTime, use24hFormat: false)`.
   - Selection pill rendered behind wheel text via `Stack` and semantic `surfaceVariant`.
   - Native top overlay suppressed via `selectionOverlayBuilder`.
   - Re-keys narrow revision only on caller snap-back or external bound/value change.

### Nutrition Adapter

- Quick Add snapshots current local minute once in `initState`.
- `_resolveMealDateTime` validates candidate against fresh clock reading; snaps future to minute floor.
- Timer refreshes `_maximumDateTime` every minute while popup is open.
- Footer displays concrete `MMM d, HH:mm` label.

### Data Flow

```text
Quick Add open -> Nutrition clock snapshot -> local DateTime draft
footer tap -> toggle TioDateTimePickerPopup
popup opens -> OverlayPortal renders floating TioCard over editor
user detent -> native CupertinoDatePicker -> Core onDateTimeChanged -> Nutrition resolver
resolved DateTime -> local draft -> footer text (live update)
future candidate -> resolved to fresh minute floor -> picker re-keys to snap back -> footer updates
tap outside -> popup dismisses -> local draft retained
```

## 5. Implementation Plan

- [x] Create `TioDateTimePickerPopup` with `OverlayPortal`, anchor measurement, and safe-area clamping.
- [x] Create `TioDateTimeWheelPicker` wrapping `CupertinoDatePicker(dateAndTime, use24hFormat: false)` with Tio theme derivation and behind-text selection pill.
- [x] Integrate popup card into Quick Add and wire anchor key to `MealLogActionFooter`.
- [x] Remove inline picker from Quick Add content body.
- [x] Remove obsolete `tio_wheel_picker.dart` and legacy commented-out tests.
- [x] Restore `TioWheelPickerTokens` to canonical geometry (48dp height, lg margin).
- [x] Fix analyzer const warnings in `TioDateTimePickerPopup`.
- [x] Add automated tests for popup, wheel, theme derivation, boundary resync, and Quick Add flow.
- [x] Verify `git diff --check` and push to existing branch `codex/shared-date-time-wheel-quick-add`.
- [x] Wait for exact-head CI and verify all checks pass.
- [x] Update PR body with complete truth.

## 6. Quality Review

### Review Findings and Resolution

| ID | Severity | Status | Finding | Resolution |
|---|---|---|---|---|
| QR-8 | P1 | Resolved | Resolver candidate cross-day inspection before calendar bounds. | Validated in commit `4562cbe3`. |
| QR-9 | P2 | Resolved | Non-pointer midnight bound refresh. | Validated in commit `4562cbe3`. |
| Owner UI | P1 | Resolved in Code | Replace inline card with reusable popup card; replace 4-column wheel with Cupertino drum. | Implemented via `TioDateTimePickerPopup` and `TioDateTimeWheelPicker`; owner device screenshot pending. |
| CI-1 | P1 | Resolved | Analyzer failure on non-const `desiredHeight` and `gap`. | Converted declarations to `const`. |
| CI-2 | P1 | Resolved | Design system token contracts broke when `TioWheelPickerTokens` was mutated to 44dp. | Restored `TioWheelPickerTokens` to canonical 48dp/lg. |
| CI-3 | P1 | Resolved | Test asserted 48dp height on footer action when contract was 44dp. | Aligned test expectation to 44dp. |
| Dead Code | P2 | Resolved | Unused `tio_wheel_picker.dart` and commented legacy tests. | Removed dead file and cleaned test file. |

## 7. Final Handoff

### Changed Files in PR

- `.ai/tasks/shared-date-time-wheel-quick-add.md`
- `apps/app/test/app/meal_logging_modal_theme_test.dart`
- `apps/core/lib/src/theme/README.md`
- `apps/core/lib/src/ui/components/components.dart`
- `apps/core/lib/src/ui/components/pickers/pickers.dart`
- `apps/core/lib/src/ui/components/pickers/tio_date_time_picker_popup.dart`
- `apps/core/lib/src/ui/components/pickers/tio_date_time_wheel_picker.dart`
- `apps/core/lib/src/ui/components/sheets/tio_editor_sheet.dart`
- `apps/core/test/ui/components/tio_date_time_wheel_picker_test.dart`
- `apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_page.dart`
- `apps/features/nutrition/lib/src/meal_logging/presentation/widgets/meal_log_action_footer.dart`
- `apps/features/nutrition/lib/src/meal_logging/presentation/widgets/quick_add_editor_sheet.dart`
- `apps/features/nutrition/test/meal_logging/meal_diary_add_food_flow_test.dart`
- `docs/MODULE_OWNERSHIP.md`
- `docs/screens/meal-diary.md`

### Safety / Boundaries

- Preserved branch: `docs/supabase-android-studio-qa-run` intact at `7fe89682`.
- Unrelated local modification in `pubspec.lock` preserved.
- No Supabase, no backend, no persistence, no Workout feature code.
