# Feature Task: Issue #569 Direct Move UX Correction

**Status:** Validated
**Completion date:** 2026-10-23
**Primary owner:** Antigravity
**Affected platforms:** `apps/features/workout`, `apps/app` (Flutter Android / iOS)

## Owner Approval and Scope Boundary

**Trigger:** Unapproved product-visible UI/UX change (superseding old two-step confirmation with owner-approved direct move flow)
**Approval status:** Approved
**Approval evidence:** GitHub #569 owner UX contract (2026-10-23) supersedes the old Move confirmation-dialog and extra Create & Move confirmation:
- Direct tap on eligible destination Program executes Move directly without `_confirm` dialog.
- `+ New Program` opens canonical Create Program sheet with editable `Program N` name and primary button labeled `Save & Move`. Tapping `Save & Move` directly executes atomic Create + Move without extra confirmation dialog.
- Real 5-second Undo remains a future server capability slice; cosmetic or fake client-side Undo is strictly disallowed.
**Approved product/UI/data-shape boundaries:**
- `routine_move_flow.dart`: Remove `_confirm` dialog. Direct selection of existing destination or submission of `Save & Move` is the affirmative action.
- `programs_surface.dart`: Support `submitLabel` in `_CreateProgramSheet` and default `submitLabel = 'Save & Move'` in `promptCreateProgramName`.
- Preserve single-dispatch, CAS, owner validation, frozen mutation identity, and UNKNOWN receipt reconciliation.
- Keep `routineMoveReleaseEnabledProvider = false` and hosted RPCs EXECUTE-denied.
**Explicit non-changes:**
- No hosted Supabase writes or migrations.
- No real Undo implementation in this slice.
- No Delete Program implementation (#567).
- No production Move activation.
- No visual redesign or token alteration.

## Active Handoff

**Planning owner:** GitHub #569; Linear TNYX-81 / TNYX-267
**Implementation owner:** Antigravity
**Review owner:** Codex / Peer Reviewer
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** `main@6dee84bfd018e13a7f8674560c07f719cfb0f5e9`
**Branch:** `tnyx/issue-569-direct-move-ux-20261023` (merged through PR #660)
**HEAD SHA:** PR source `b0c9cd13d98cfff383921f26f3c0c74fbfa21f7a`; merge commit `6dee84bfd018e13a7f8674560c07f719cfb0f5e9`
**Observed working-tree state:** Historical task branch; current checkout is clean at `main` during reconciliation.
**Observed uncommitted/dirty files:** None at reconciliation.
**PR / tracker:** GitHub PR #660 MERGED; GitHub #569 remains OPEN. Linear TNYX-81/TNYX-267 state was not re-read in this session.
**Current implementation state:** Direct Move and `Save & Move` UX merged; no real five-second Undo, Move release, or hosted RPC grant is included.
**Relevant execution surface:** `apps/features/workout/lib/src/presentation/library/routines/routine_move_flow.dart`, `apps/features/workout/lib/src/presentation/library/programs/programs_surface.dart`, `apps/features/workout/test/presentation/routine_move_flow_test.dart`, `apps/app/test/app/workout_exercises_route_test.dart`
**Validation completed at SHA:** PR source head `b0c9cd13d98cfff383921f26f3c0c74fbfa21f7a`: merged PR checks passed (Flutter/Dart analysis and tests, app-workout, core-wear, nutrition-onboarding, docs diff hygiene, attribution); prior task-local Flutter analysis/workout/app-route tests are recorded above.
**Validation remaining:** None for this bounded UX slice. Android E2E real-write regression remains a separate M5A prerequisite and is not proven by Flutter CI.
**Current blocker:** None for PR #660; M5A real Undo is separately blocked pending isolated Android E2E.
**Open review finding IDs:** None
**Next exact action:** See [active M5A handoff](../tasks/issue-569-m5a-real-move-undo.md); complete Gate 1 before any Undo architecture or source work.

## Global UI / Design-System Guardrail

All visual safety rules from `AGENTS.md` and `apps/core/lib/src/theme/README.md` are strictly observed.
- No token normalization, no spacing changes, no component geometry modifications.
- Reusing canonical `_CreateProgramSheet` with `Save & Move` action button.
- Retaining 5-second floating feedback pill for confirmed Move.

## 1. Discovery

### User Outcome
The user can move a routine to an existing program with a single tap in the "Select Program" sheet without an extra confirmation popup, or create a new program and move the routine in one step via "Save & Move" in the canonical Create Program sheet.

### Success Criteria
1. Tapping an eligible destination Program executes Move immediately without a confirmation popup.
2. Tapping `+ New Program` opens canonical Create Program sheet with editable `Program N` name and primary button `Save & Move`.
3. Submitting `Save & Move` executes atomic Create + Move with zero subsequent confirmation dialogs.
4. Dismissing either sheet results in zero writes.
5. All security, session, CAS, and UNKNOWN readback protections remain intact.

### Scope
- `apps/features/workout/lib/src/presentation/library/routines/routine_move_flow.dart`
- `apps/features/workout/lib/src/presentation/library/programs/programs_surface.dart`
- `apps/features/workout/test/presentation/routine_move_flow_test.dart`

### Non-Goals
- Real 5-second Undo backend/server transaction (separate slice).
- Delete Program (#567).
- Production Move feature flag activation.
- Hosted Supabase mutations or grant changes.

## 2. Codebase Exploration

### Verified Evidence
- `routine_move_flow.dart` currently contains `_confirm(...)` dialog called at lines 221 and 276.
- `programs_surface.dart` defines `_CreateProgramSheet` used by `promptCreateProgramName`.
- `routine_move_flow_test.dart` has 1143 lines covering destination selection, auth switch, cancel, UNKNOWN verification, and debug preview.

## 3. Clarification

### Decisions Made
| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Remove `_confirm` dialog | Approved | Owner explicit requirement (2026-10-23) | Owner |
| Primary button label `Save & Move` | Approved | Owner explicit requirement (2026-10-23) | Owner |
| Real Undo deferred | Approved | Requires reviewed atomic server capability; no fake cosmetic Undo | Owner |

## 4. Architecture Design

### Chosen Approach
1. In `programs_surface.dart`: Add `submitLabel` to `_CreateProgramSheet` and `promptCreateProgramName` (defaulting to `'Save & Move'`).
2. In `routine_move_flow.dart`: Remove `_confirm` dialog and its invocation on both existing program and new program flows. Tapping destination or submitting `Save & Move` directly triggers the respective protected RPC/controller dispatch.
3. Update `routine_move_flow_test.dart` to assert zero confirmation dialogs, primary button label `Save & Move`, and direct dispatch on affirmative selection/submit.
