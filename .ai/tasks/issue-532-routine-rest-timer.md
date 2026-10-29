# Routine Rest Timer (W4B2) — GitHub Issue #532 / Linear TNYX-81

**Status:** In Review (P2 Fixes Addressed)
**Primary owner:** `apps/features/workout`
**Affected platforms:** Flutter mobile (`apps/features/workout`, `apps/app`)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** GitHub Issue #532 owner comments (2026-10-28, 2026-10-29), Linear TNYX-81 owner directives.
**Approved product/UI/data-shape boundaries:**
- Routine Create/Edit Exercise-level Rest Timer configuration.
- Header button on `RoutineComposerExerciseCard` in `routine_composer_screen.dart` with summary:
  - `Rest: OFF` when both Normal and Warm-up are OFF.
  - `Rest: 1min 30s` when only Normal is active.
  - `Rest: (45s)` when only Warm-up is active.
  - `Rest: 1min 30s (45s)` when both are active.
  - Explicit accessibility semantics identifying Normal and Warm-up duration categories.
- Dedicated `RoutineRestTimerSheet` with:
  - Centered title ("Rest Timer") and exercise name subtitle (no checkmark/close icons).
  - `Normal set` and `Warm-up Set` independent tabs using `TioTabSwitcher`.
  - Single unified duration wheel in 5-second steps (from index 0 "Off" up to 10m 0s) with selection click haptics.
  - Pinned white `Done` action button.
- Effective rest assignment mapping:
  - Warm-up timer ON: Warm-up sets use Warm-up duration.
  - Warm-up timer OFF: Warm-up sets fallback to Normal timer.
  - Normal timer ON: Normal, Failure, and Drop sets use Normal timer.
  - Normal timer OFF: Normal, Failure, and Drop sets have effective rest OFF (`null`).
  - Both OFF: All set types have rest OFF (`null`).
  - Failure and Drop inherit Normal timer; no separate presets.
  - Adding or changing a set type resolves rest according to active presets while preserving existing values when presets are OFF.
**Explicit non-changes:**
- No database schema, migrations, or RPC changes (strict RPC whitelist preserved).
- No Active Workout timer countdown execution.
- No Wearable sync.
- No Exercise Notes UI or schema changes.
- No premature Workout Settings storage or global state mutations (Workout Settings is planned for W10/TNYX-87).

## Active Handoff

**Planning owner:** im-tnyx
**Implementation owner:** Antigravity agent
**Review owner:** im-tnyx
**Implementation ownership state:** Ready for Review
**Ownership transition:** Handed off for PR review
**Repository state last verified:** 2026-10-29
**Branch:** feat/issue-532-routine-rest-timer
**HEAD SHA:** a694a3075c81673e2ded3a499ff011470eb49b5e
**Observed working-tree state:** Changes ready for commit
**Observed uncommitted/dirty files:** Only task-related files
**PR / tracker:** GitHub Issue #532, Linear TNYX-81
**Current implementation state:** Complete
**Relevant execution surface:** `apps/features/workout`
**Validation completed at SHA:** `feat/issue-532-routine-rest-timer` branch (1,066 / 1,066 tests passing, flutter analyze 0 issues)
**Validation remaining:** Remote CI run on push
**Current blocker:** None
**Open review finding IDs:** Addressed discussion_r4408682692 (active preset override on addSet), Addressed discussion_r4408960765 (seconds wheel reset/disable at 10-minute cap), Addressed discussion_r4409572462 (preserve legacy per-set rest values when preset is OFF)
**Next exact action:** Commit, push to origin feat/issue-532-routine-rest-timer, reply to review thread, await CI/approval.

## Global UI / Design-System Guardrail

- Adheres to `apps/core/lib/src/theme/README.md` and `apps/features/AGENTS.md`.
- Consumes `TioEditorSheet`, `TioTabSwitcher`, `TioButton`, `TioRadius`, `TioSpacing`, `TioSize`, `TioWheelPickerTokens`.
- Reusable drum wheel mechanics follow `TioWheelPickerTokens.perspective` and `diameterRatio`.

## 1. Discovery

### User Outcome
A user composing or editing a workout routine can configure rest durations per exercise for Normal sets and Warm-up sets independently, see a concise summary in the exercise header, and have those durations automatically applied to sets when saved or added.

### Success Criteria
1. Independent Normal and Warm-up presets (OFF/OFF, ON/OFF, OFF/ON, ON/ON).
2. Summary label matches owner specifications exactly.
3. Fallback logic: Warm-up timer OFF falls back to Normal timer; Failure/Drop use Normal timer.
4. Preserves per-set `restSeconds` in `SetPrescription`.
5. Passes all unit and widget tests with 0 analyzer issues.

### Scope
- Domain model `RoutineRestTimerPreset` and formatter `RoutineRestTimerFormatter`.
- `RoutineRestTimerSheet` bottom sheet with tabs and wheel picker.
- `RoutineComposerExerciseCard` header rest timer button.
- `RoutineCreateController` & `RoutineEditorController` integration for rest timer preset configuration, set addition, and set-type transitions.
- Comprehensive unit and widget tests.

### Non-Goals
- Exercise Notes.
- Active workout timer engine.
- Wearable sync.
- Supabase migrations or RPC changes.

## 2. Codebase Exploration

### Verified Evidence
- RPC `save_user_workout_routine_composition` permits `rest_seconds` on sets, rejects unknown keys.
- `RoutineCompositionSet` and `SetPrescription` already contain `restSeconds: int?`.
- `TioEditorSheet` and `TioTabSwitcher` exist in `apps/core` and provide modal chrome and tab selection.
- `TioWheelPickerTokens` governs drum wheels.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Failure/Drop mapping | Resolved | Inherits Normal timer directly | Owner approved 2026-10-29 |
| Warm-up fallback | Resolved | Warm-up timer OFF falls back to Normal timer | Owner approved 2026-10-29 |
| OFF vs 0 | Resolved | OFF is `null`, 0 is explicit zero | Owner approved 2026-10-29 |
| Summary label | Resolved | `Rest Timer: OFF`, `Rest Timer: 1min 30s (45s)`, etc. | Owner approved 2026-10-29 |
| Workout Settings | Resolved | Planned only in W10/TNYX-87; no runtime changes | Codebase audit 2026-10-29 |

## 4. Architecture Design

### Chosen Approach
1. `RoutineRestTimerPreset` pure domain value class in `apps/features/workout/lib/src/domain/models/routine_rest_timer_preset.dart`.
2. Controller-level `_restPresets` map keyed by `entryId`.
3. Sets' `restSeconds` updated on configuration, creation, and set-type transitions.
4. `RoutineRestTimerSheet` UI using `showTioEditorSheet`.

### Ownership and Data Flow
```text
RoutineComposerExerciseCard (tap) -> showRoutineRestTimerSheet -> RoutineRestTimerSheet (Done)
  -> controller.configureExerciseRestTimer(entryId, preset)
  -> updates entry sets' SetPrescription.restSeconds
  -> controller emits state -> UI refreshes summary
  -> Save/Update persists sets' rest_seconds via existing RPC
```

## 5. Implementation Summary
1. Created `routine_rest_timer_preset.dart` with `RoutineRestTimerPreset` domain model, `effectiveRestForSetType`, and `RoutineRestTimerFormatter`.
2. Exported `routine_rest_timer_preset.dart` from `models.dart`.
3. Added `RoutineRestTimerSheet` in `routine_rest_timer_sheet.dart` with `TioTabSwitcher`, drum wheel pickers, toggle switch, and `Done` action button.
4. Added rest timer configuration to `RoutineCreateController` and `RoutineEditorController`, with fallback and legacy set preservation.
5. Integrated rest timer button in `RoutineComposerExerciseCard` in `routine_composer_screen.dart`.
6. Wired `onConfigureRestTimer` in `CreateRoutinePage` and `EditRoutinePage`.
7. Created and updated tests:
   - `routine_rest_timer_preset_test.dart`: 9 tests.
   - `routine_rest_timer_sheet_test.dart`: 3 tests.
   - `routine_create_controller_test.dart`: 3 new rest timer tests (all 29 pass).
   - `routine_editor_controller_test.dart`: 3 new rest timer tests (all 37 pass).
   - `routine_composer_screen_test.dart`: added button rendering and callback test (all 8 pass).
   - `create_routine_page_test.dart`: verified all 21 tests pass.
   - Full suite in `apps/features/workout`: all 1,062 tests pass.
   - `flutter analyze lib/ test/`: 0 issues found.
