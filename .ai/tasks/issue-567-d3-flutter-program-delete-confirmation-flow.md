# GitHub #567 D3 — Flutter Program Delete Confirmation Flow

**Status:** In progress
**Primary owner:** Antigravity (Implementation Owner)
**Affected platforms:** Flutter `apps/features/workout` presentation only

## Owner Approval and Scope Boundary

**Trigger:** Internal implementation subtask of approved #567 lifecycle slice (dormant confirmation UI)
**Approval status:** Approved
**Approval evidence:** User prompt explicitly requested D3 implementation while keeping Program Delete completely disconnected from production entry points.
**Approved product/UI/data-shape boundaries:**
- Reusable, compact centered confirmation dialog following the exact `RoutineDeleteFlow` architecture and `TioCard` / `TioButton` design tokens.
- Dynamic explanation clearly identifying selected Program name and explaining that deleting a non-default Program preserves and moves all its saved Routines to canonical `My Program`.
- Saved-Routine count displayed only when reliably available from `ProgramDeleteTarget.expectedRoutineIds`.
- Protected default `My Program` blocked from deletion.
- Cancel dismisses dialog without initiating deletion.
- Flow handles loading, error kinds, and uncertain (`UNKNOWN`) states without false success.
- Reusable presentation flow class `ProgramDeleteFlow` in `apps/features/workout/lib/src/presentation/library/programs/program_delete_flow.dart`.
- Focused unit/widget tests in `apps/features/workout/test/presentation/program_delete_flow_test.dart`.
**Explicit non-changes:**
- **Strict hard boundary:** Do NOT add a Delete action to `programs_surface.dart`, `_openProgramActions`, or any production entry point.
- Zero hosted Supabase migrations, grants, RLS, functions, or production database mutations.
- Zero table/column shape changes.
- Production UI remains completely untouched and dormant.

## Active Handoff

**Planning owner:** Antigravity
**Implementation owner:** Antigravity
**Review owner:** Independent reviewer
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `G:/projects/Tio-World` at branch `tnyx/567-d3-flutter-program-delete-confirmation-flow`
**Branch:** `tnyx/567-d3-flutter-program-delete-confirmation-flow`
**HEAD SHA:** `240b1b09ab40f176481967449e437fd7625b6fca`
**Observed working-tree state:** Clean
**PR / tracker:** GitHub #567 OPEN, PR #708; Linear TNYX-81 / TNYX-267 Backlog
**Current implementation state:** Codex findings remediation complete:
1. Serialized concurrent delete flows via `_activeProgramId` and bound controller target identity check immediately before confirm.
2. Verified canonical name displayed from prepared target `controller.state.program.name` rather than caller's potentially stale Program name.
3. Handled already-confirmed Program deletion in `!prepared` state (`controller.state.status == ProgramDeleteOperationStatus.confirmed`), showing accurate refresh message and returning true to trigger view refresh without claiming false new deletion.
4. Bound confirm call to exact captured target reference (`identical(currentTarget, target)` and `listEquals`) preventing cross-flow target replacement.
5. Populated `target` in `ProgramDeleteController.prepare()` when gate returns cached `unknown` or `committed`, and verified `cachedTarget.sourceProgramId == program.id` in `ProgramDeleteFlow` before attributing terminal state to requested Program.
6. Tracked `dispatched` explicitly in `ProgramDeleteControllerState` and returned `false` for pre-dispatch rejections (e.g. pending-conflict checks before delete repository dispatch), ensuring only true dispatched attempts or unconfirmed states return `true`.
**Relevant execution surface:** `apps/features/workout`
**Validation completed at SHA:** Local validation PASS: 17/17 focused tests in `program_delete_flow_test.dart`, 39/39 delete-suite regression tests, `flutter analyze --no-pub` PASS (0 issues in `workout` and `app`), `dart format` clean, and `git diff --check` clean.
**Validation remaining:** Push & GitHub PR CI checks
**Current blocker:** None
**Open review finding IDs:** None (Codex threads 4392621553, 4392621563, 4392621570, 4392770762, 4392845115, 4392920771 addressed)
**Next exact action:** Commit, push to PR #708, and verify CI checks.

## Global UI / Design-System Guardrail

Follow `apps/core/lib/src/theme/README.md` and `apps/features/AGENTS.md`.
- Dialog uses `TioCard(variant: TioCardVariant.elevated, padding: const EdgeInsets.all(TioSpacing.lg))`
- Sized with compact width `TioSize.dp320`
- Danger icon `Icons.delete_outline_rounded`, size `TioSize.dp24`, color `colors.danger`
- Title `Delete Program?`
- Action buttons: `TioButton.secondary(label: 'Cancel')` and `TioButton.destructive(label: 'Delete')`
- Floating pill for confirmed success: `SnackBar` with stadium border and `Icons.delete_outline_rounded`
- No raw color or font magic numbers; everything references `tioColors`, `TioSpacing`, `TioFontWeight`, `TioLineHeight`, and `TioSize`.

## 1. Discovery

- `RoutineDeleteFlow` in `apps/features/workout/lib/src/presentation/library/routines/routine_delete_flow.dart` defines the standard confirmation workflow, presentation dialog, and `SnackBar` messaging for destructive operations.
- `ProgramDeleteController` in `apps/features/workout/lib/src/presentation/library/programs/program_delete_controller.dart` requires:
  1. `prepare(sourceProgramId)` to fetch versioned snapshot and validate non-default status and gate readiness.
  2. `confirm({required String clientMutationId})` to dispatch delete via repository and execute post-attempt refresh.
- `ProgramDeleteControllerState` exposes:
  - `target?.expectedRoutineIds`: reliable count of saved Routines that will be reparented.
  - `status`: `ready`, `inFlight`, `confirmed`, `definitelyRejected`, `unknown`.
  - `failure`: `ProgramDeleteException` with `kind` (`defaultProtected`, `notFound`, `unauthorized`, `staleMembership`, `inProgress`, etc.).
  - `unknown`: `ProgramDeleteOutcomeUnknown`.

## 2. Architecture Decision

Implement `ProgramDeleteFlow` in `apps/features/workout/lib/src/presentation/library/programs/program_delete_flow.dart`.

- Reuses `ProgramDeleteController` for all orchestration, session validation, and RPC calls.
- Enforces `program.isDefault` guard both locally and via controller `prepare`.
- Formulates accurate dynamic confirmation text:
  - Count == 0: `"Delete \"$programName\"? This Program has no saved Routines. This cannot be undone."`
  - Count == 1: `"Delete \"$programName\"? Its 1 saved Routine will be moved to My Program. This cannot be undone."`
  - Count > 1: `"Delete \"$programName\"? All $routineCount saved Routines will be moved to My Program. This cannot be undone."`
- Does NOT connect to `programs_surface.dart` or any production widget. Flow remains fully dormant and unit/widget tested.

## 3. Tests and Validation Plan

- Unit & widget tests in `apps/features/workout/test/presentation/program_delete_flow_test.dart`:
  - Renders dialog with Program name, correct routine count message, Cancel and Delete buttons.
  - Cancel dismisses dialog without calling `confirm`.
  - Confirm triggers `controller.confirm(clientMutationId: ...)`.
  - Default Program is blocked from deletion (shows feedback, never shows dialog or calls confirm).
  - Handles `confirmed` state (shows floating SnackBar pill).
  - Handles `unknown` state (shows unconfirmed message, does not report false success).
  - Handles `definitelyRejected` failure kinds (session expired, not found, in progress, stale membership).
  - In-flight duplicate tap prevention (`_opening` set).
- Run `flutter test test/presentation/program_delete_flow_test.dart`
- Run `flutter analyze`
- Run `git diff --check`
