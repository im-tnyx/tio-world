# Routine Notes — Exercise inline UI Slice A

**Status:** In progress
**Primary owner:** Current implementation session
**Affected platforms:** Flutter phone Create/Edit Routine; Supabase contract consumed read-only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice / product-visible UI
**Approval status:** Approved
**Approval evidence:** Owner instruction `Tio-world — Exercise Notes Inline UI Implementation` received 2026-11-02, with the attached screenshot as the visual and interaction reference.
**Approved product/UI/data-shape boundaries:** Add Exercise-scoped Notes inline inside the existing Create/Edit Routine Exercise card, directly below Rest/Note actions and above the Set table. Use `RoutineNoteScope.exercise(ExerciseRef)`, the existing `RoutineNotesRepository`, existing authenticated provider/session guards, explicit inline `Save Note`/`Cancel`, existing five-note and 500-character limits, and existing delete/mutation-safety behavior. Owner clarification received 2026-11-02 also approves tapping the left pin icon or right-swiping a saved Note to change Note type and left-swiping a saved Note to reveal Delete. Type transfer uses the existing atomic repository contract; `Pinned Routine` is enabled only when an existing Routine identity is available (Edit), while Create remains Exercise-scoped until the Routine has a durable identity.
**Explicit non-changes:** No sheet/dialog/navigation page for creating or editing the Note, no autosave or per-keystroke write, no copy/share, new repository/model/table/migration/RLS/grant, hosted deployment, Rest Timer redesign, Set/table redesign, Routine-level Notes change, WorkoutSession/history/post behavior, or physical-device acceptance claim. The type chooser is limited to the explicitly approved type-change action and does not become a general Note editor.

## Active Handoff

**Planning owner:** Current implementation session
**Implementation owner:** Current implementation session
**Review owner:** Independent GitHub review (`im-tio`) when PR exists
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-11-02
**Branch:** `codex/routine-notes-exercise-inline-slice-a`
**HEAD SHA:** `e9d1cfb798aa4d676b75c655efc47d0c9d84f162` before the pending exact Rest-card follow-up
**Observed working-tree state:** Clean for authorized files; generated Android registrant has no content diff and is excluded
**Observed uncommitted/dirty files:** Flutter test tooling reports a metadata-only `apps/app/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` change; it is not part of this slice
**PR / tracker:** GitHub PR #725 (`https://github.com/im-tnyx/tio-world/pull/725`) linked to existing GitHub #716 and Linear `TNYX-81`; independent review requested from `im-tio`; no separate child issue available in the current Linear workspace limit
**Current implementation state:** Shared Create/Edit composer now mounts the inline Exercise Notes surface; the existing Routine Notes contract is generalized by injected scope without a new data source
**Relevant execution surface:** `apps/features/workout/lib/src/presentation/library/routines/routine_composer_screen.dart`
**Validation completed at SHA:** Local Flutter `3.44.6` initialization through the elevated SDK-root path; focused Notes/controller/Routine and shared composer/Create/Edit suites; app `workout_exercises_route_test.dart` (89 tests); Core visual-ownership test; `flutter analyze --no-pub` for `apps/features/workout` and `apps/app`; read-only Dart formatting check; `git -c core.fsmonitor=false diff --check`; Note-right-of-Rest compact layout test; hidden-until-Note-tap visibility test; no-Retry UI assertion; filled Rest-style `TioButton.supporting` assertion. Initial PR CI found and locally fixed the owner-ID compatibility and Core visual-duration findings; PR #725 exact-head CI for `c672a69b` is pending after push.
**Validation remaining:** Exact-head CI for `c672a69b`, independent review, and physical Android/iOS QA
**Current blocker:** No source-level blocker remains after local fixes; hosted Notes objects are not deployed and physical device QA has not been performed. This source slice does not activate production Notes.
**Open review finding IDs:** None
**Next exact action:** Verify CI on PR #725 HEAD `1d107b23`, then address independent review findings without merging.

## 1. Discovery

### User Outcome

Users can create and view private Exercise Notes inline while building or editing a Routine, without leaving the Exercise/Set context or opening a modal editor.

### Success Criteria

- The existing `Note` action focuses an inline multiline field and opens the normal keyboard.
- The inline Note field is hidden on first render and appears only after the user taps `Note`.
- Draft text survives rebuilds and keyboard inset changes.
- Persistence happens only from an explicit inline `Save Note` action.
- Exercise Notes use canonical `ExerciseRef` identity and existing owner/session guards.
- Read/create/delete, quota, validation and uncertain-save states are covered.
- Existing Rest Timer, Set table, Add Set and Routine-level Notes behavior remain unchanged.

### Scope

Shared `RoutineComposerExerciseCard`, its feature-owned controller/widget support, Create/Edit wiring, focused tests and this handoff.

### Non-Goals

Editing existing note bodies, copy/share, pinned presentation redesign, schema/deployment, device QA and unrelated Routine UI. Type transfer is included only for the explicitly approved pin-icon and right-swipe interaction.

## 2. Codebase Exploration

### Verified Evidence

- `RoutineNotesRepository` already exposes `read/create/update/transfer/delete`.
- `RoutineNotesController` already owns 5-note quota, 500-rune normalization, owner/scope validation, session checks and unknown create reconciliation; it will be generalized to accept an existing `RoutineNoteScope` without changing Routine behavior.
- `RoutineComposerExerciseCard` is the shared Create/Edit Exercise header, Rest control, Set header/table and Add Set surface.
- `routineNotesRepositoryProvider` is authenticated and login-cycle bound in `apps/app`.
- `TioInput.multiline`, `TioButton`, `TioCard` and `showTioConfirmationBottomSheet` are the existing governed Core patterns.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Inline commit behavior | Made | Existing Routine Notes uses explicit `Save Note`; multiline input must not write per keystroke. | Product/implementation audit |
| Existing note edit behavior | Deferred | Body editing remains out of scope; type transfer is separately approved by the 2026-11-02 follow-up. | Owner scope |
| Note type change | Made | Left pin icon opens the existing option-sheet pattern; transfer calls the existing atomic `transfer` contract. Create cannot target a Routine before Save. | Owner follow-up |
| Delete gesture | Made | Saved Notes use the existing swipe-to-reveal destructive action pattern plus the established confirmation; no mutation on partial drag. | Owner follow-up |
| Create Routine persistence timing | Made | Exercise Notes use independent canonical Exercise scope and may persist before Routine Save; no Routine ID is required. | Existing data contract |

## 4. Architecture Design

### Chosen Approach

Generalize the existing `RoutineNotesController` from fixed Routine scope to injected `RoutineNoteScope`, retain the existing Routine constructor behavior, and mount a feature-owned inline `ExerciseNotesInline` widget in the shared composer card.

### Ownership and Data Flow

```text
RoutineComposerExerciseCard
  -> ExerciseNotesInline
  -> RoutineNotesController(scope: RoutineNoteScope.exercise(ExerciseRef))
  -> RoutineNotesRepository
  -> SupabaseRoutineNotesRepository
  -> existing Notes RPC/read contract
```

### Alternative Rejected

The existing `TioEditorSheet` was rejected for Exercise Notes because the approved interaction is inline and must keep the Exercise/Set context visible.

### Failure and Accessibility States

Loading, empty, quota-disabled, invalid body, save failure, unknown save notice/reconciliation, stale-session fail-closed behavior, delete confirmation, semantic labels, keyboard-visible scroll and compact/large-text layouts.

## 5. Implementation Plan

- [x] Generalize the existing controller to accept Routine or Exercise scope.
- [x] Add the inline Exercise Notes widget with explicit Save/Cancel, type chooser and swipe-to-reveal delete.
- [x] Wire authenticated repository and session callback through app Create/Edit routes.
- [x] Preserve the existing Rest/Set/Add Set geometry and behavior in the shared composer.
- [x] Add focused tests and run local validation; Flutter tests require elevated SDK-root access on this machine, but pass there.
- [x] Resolve the PR CI findings without backend/schema changes: governed motion token and invalid-owner fail-closed compatibility.

## 6. Quality Review

### Validation Run

```text
PASS: `G:\dev\flutter-sdk\bin\flutter.bat --suppress-analytics test test/presentation/exercise_notes_inline_test.dart test/presentation/routine_notes_controller_test.dart test/presentation/routine_notes_section_test.dart --reporter compact` — all tests passed
PASS: `G:\dev\flutter-sdk\bin\flutter.bat --suppress-analytics test test/presentation/routine_composer_screen_test.dart test/presentation/create_routine_page_test.dart test/presentation/edit_routine_page_test.dart --reporter compact` — all tests passed
PASS: `G:\dev\flutter-sdk\bin\flutter.bat --suppress-analytics test test/app/workout_exercises_route_test.dart --reporter compact` in `apps/app` — 89 tests passed
PASS: `G:\dev\flutter-sdk\bin\flutter.bat --suppress-analytics test test/theme/final_enforcement_visual_ownership_test.dart --reporter compact` in `apps/core`
PASS: `G:\dev\flutter-sdk\bin\flutter.bat --suppress-analytics analyze --no-pub` in `apps/features/workout`
PASS: `G:\dev\flutter-sdk\bin\flutter.bat --suppress-analytics analyze --no-pub` in `apps/app`
PASS: Dart formatting check on 9 changed Dart files — `0 changed`
PASS: `git -c core.fsmonitor=false diff --check`
CI initial PR HEAD `3702fb0a`: analysis, docs hygiene and attribution passed; app-workout failed on existing route compatibility after the Notes injection (`ownerId: test-user`), and core failed the visual-ownership contract on the new inline focus duration. Both findings are fixed locally. Exact-head CI for `fd390b40` is pending.
NOT RUN: physical Android/iOS keyboard, gesture, theme, accessibility and compact-layout QA
```

### Review Provenance

**Review source / link:** GitHub PR #725 (`https://github.com/im-tnyx/tio-world/pull/725`)
**Reviewer / relation to implementer:** Independent reviewer requested: `im-tio`
**Diff or commit SHA actually reviewed:** PR HEAD `c672a69b954f4d3b34bcbc129e53e051ea560734`; independent review pending
**Review result and finding IDs/dispositions:** No review findings yet; PR remains `REVIEW_REQUIRED`
**Independent review?** Requested / pending
**Limitations and unmet required gates:** Hosted Notes deployment remains intentionally blocked; physical Android/iOS QA, exact-head CI and independent review remain open.

## 7. Final Handoff

### Changed Files

- `apps/features/workout/lib/src/presentation/library/routines/exercise_notes_inline.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_notes_controller.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_composer_screen.dart`
- `apps/features/workout/lib/src/presentation/library/routines/create_routine_page.dart`
- `apps/features/workout/lib/src/presentation/library/routines/edit_routine_page.dart`
- `apps/features/workout/test/presentation/exercise_notes_inline_test.dart`
- `apps/features/workout/test/presentation/routine_notes_controller_test.dart`
- `apps/features/workout/lib/src/presentation/library/library.dart`
- `apps/app/lib/app/routing/shell/shell_route.dart`

### Actual Behavior

- `Note` remains beside Rest and focuses the inline multiline Exercise Note input; creation uses explicit `Save Note`/`Cancel` and does not open an editor sheet.
- `Rest` and `Note` remain in one governed action row; `Rest` stays left and `Note` sits immediately to its right with equal governed control height, without moving to the screen edge or wrapping below Rest at the approved compact width.
- `Note` uses the same local `Material`/`InkWell` capsule geometry as the existing Rest action—surface, radius, padding, icon size, typography and height—while retaining Note-specific semantics and focus behavior.
- The first Exercise render shows only the action row and Set surface; `Save Note`/`Cancel` and the text field appear after `Note` is tapped, then hide after `Cancel` or a confirmed save.
- The inline Exercise Notes error state shows only its message/notice; no `Retry` button is rendered.
- Draft text is held by the stateful inline widget while keyboard/rebuild events occur; `Scrollable.ensureVisible` requests the focused field into view.
- Saved Notes render inline with existing Core input/card/theme patterns, five-note quota, 500-character validation, owner/session guards and delete confirmation.
- Tapping the pin icon opens the approved `Notes type` sheet. A saved Note can also open it through right swipe; Create mode exposes only Exercise scope, while Edit mode can transfer to the current Routine through the existing atomic repository contract.
- Left swipe reveals the red `Delete` action; delete occurs only after tapping the revealed action and confirming.
- Existing Routine-level Notes continue using the compatibility constructor and unchanged Routine scope.

### Known Limitations

Hosted Notes migrations are not applied; this does not authorize production activation. Existing body edit/copy/share behavior remains out of scope. Physical Android/iOS gesture and keyboard QA remains pending.

### Final Status

`REVIEW`
