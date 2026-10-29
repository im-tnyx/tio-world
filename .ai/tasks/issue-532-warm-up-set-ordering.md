# GitHub #532 — Routine Warm-up Set Ordering Policy

**Status:** Ready for review / Handoff
**Primary owner:** Workout feature (`apps/features/workout`), app-shell composition/navigation (`apps/app`).
**Affected platforms:** Flutter mobile (Android/iOS).

## Owner Approval and Scope Boundary

**Trigger:** Implementation subtask of approved issue #532 / W4B2 Warm-up ordering invariant.
**Approval status:** Approved in Issue #532 comment on 2026-10-29.
**Approval evidence:** GitHub Issue #532 comment (2026-10-29) clarifying:
- All `warm_up` sets must precede every non-warm-up set (`normal`, `failure`, `drop`).
- Adding a Warm-up set inserts it after existing Warm-up sets and before working sets.
- Changing a Set type to `warm_up` repositions it to the end of the Warm-up group.
- Changing a Set type from `warm_up` to non-warm-up repositions it after remaining Warm-up sets.
- Reordering operations violating this invariant must be rejected.
- Preserves stable Set IDs, prescriptions, and unaffected set ordering.
**Explicit non-changes:**
- No Rest Timer configuration UI or sheet in this slice (Phase 3).
- No Routine Notes schema or UI (Slice C).
- No database migrations, tables, columns, or RPC changes.
- No Active Workout countdown engine (Slice D / TNYX-84).

## Active Handoff

**Planning owner:** Antigravity / Tio-world developer session
**Implementation owner:** Antigravity current session
**Review owner:** Independent review / Codex
**Implementation ownership state:** Completed
**Ownership transition:** Not applicable
**Repository state last verified:** `main@ea4b1f98f7198f1ef8ac27128fee9143cdc0ac87`
**Branch:** `main`
**HEAD SHA:** `ea4b1f98f7198f1ef8ac27128fee9143cdc0ac87`
**Observed working-tree state:** Changes in `apps/features/workout`
**PR / tracker:** GitHub #532, Linear TNYX-81
**Current implementation state:** Complete. `RoutineCompositionLimits.hasValidSetOrder`, `RoutineCreateController`, `RoutineEditorController`, `EditRoutinePage`, and comprehensive test suites implemented and verified.
**Relevant execution surface:** `apps/features/workout`
**Validation completed at SHA:**
- `flutter test test/presentation/routine_create_controller_test.dart`: 24/24 PASS (0 failures).
- `flutter test test/presentation/routine_editor_controller_test.dart`: 33/33 PASS (0 failures).
- Full package test suite: 1,039/1,039 PASS (0 failures).
- `flutter analyze lib/ test/`: No issues found! (0 warnings, 0 errors).
**Validation remaining:** None.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Ready for review / PR creation / proceeding to Rest Timer Phase 3 as approved.

## 1. Discovery
- User outcome: In Routine Create and Edit, Warm-up sets always group together at the beginning of each Exercise, preceding Normal, Failure, and Drop sets. Adding or changing sets automatically preserves this invariant without manual repositioning hurdles.

## 2. Codebase Exploration
- `apps/features/workout/lib/src/domain/models/routine_composition_limits.dart`: contains caps and measurement validation. Added `hasValidSetOrder(Iterable<SetPrescription> prescriptions)`.
- `apps/features/workout/lib/src/presentation/library/routines/routine_create_controller.dart`: `addSet`, `changeSetType`, `moveSet`, `save`.
- `apps/features/workout/lib/src/presentation/library/routines/routine_editor_controller.dart`: `addSet`, `changeSetType`, `moveSet`, `update`, `load`.
- `apps/features/workout/lib/src/presentation/library/routines/edit_routine_page.dart`: delegates set type selection to `changeSetType`, guards update when legacy invalid order is loaded.

## 3. Clarification
- Warm-up is an existing Set type (`RoutineSetType.warmUp`).
- Invariant: `warm_up` sets precede `normal`, `failure`, `drop`.
- Legacy invalid routines are preserved on load without silent reordering; Update is guarded until resolved.

## 4. Architecture Design
- Invariant helper `RoutineCompositionLimits.hasValidSetOrder`: single source of truth for ordering validity.
- Symmetrical controller methods across Create and Edit.
- Stable UUID and prescription preservation during repositioning.

## 5. Implementation Plan
- [x] Create task brief `.ai/tasks/issue-532-warm-up-set-ordering.md`.
- [x] Add `hasValidSetOrder` to `RoutineCompositionLimits`.
- [x] Implement invariant-preserving `addSet`, `changeSetType`, `moveSet`, and validation in `RoutineCreateController`.
- [x] Implement invariant-preserving `addSet`, `changeSetType`, `moveSet`, and validation in `RoutineEditorController`.
- [x] Update `EditRoutinePage` to call `changeSetType` and guard invalid ordering on legacy load.
- [x] Add comprehensive tests in `routine_create_controller_test.dart` and `routine_editor_controller_test.dart`.
- [x] Run flutter analyze and tests (1,039 tests PASS, analyze clean).
