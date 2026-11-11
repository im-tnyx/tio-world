# W7 Routine Start Workout Entry

**Status:** Ready for review

**Primary owner:** Codex

**Affected platforms:** Flutter Android + iOS

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice; product-visible UI/UX change

**Approval status:** Approved

**Approval evidence:** Owner request in this conversation: add `Start Routine` directly below Routine Detail's top bar; start the same Log Workout screen with Routine title, ordered Exercises and planned Sets; preserve the existing three controls. Follow-up authorized reference inspection of `G:\projects\Tio-Workspace` and accepted template-copy Save semantics. Scope extension: owner requested a play icon on Routine rows in Program Detail and Library, starting that same Routine-seeded workout flow.

**Approved product/UI/data-shape boundaries:** Routine Detail CTA and Routine-row play actions in Program Detail and expanded Library seed the existing account-bound encrypted local `ActiveWorkoutDraft` from the verified Routine composition; title, Exercise occurrence order, planned `SetPrescription`s and existing rest presets are carried forward. A planned rep range (for example `8–12`) appears as reference hint in the single `REPS` input while actual reps remain blank/unlogged until entered and checked. `Start New` conflict path uses the same seed after replacement.

**Explicit non-changes:** Routine/Program source identity is not stored in saved history (`origin='ad_hoc'` remains); no Supabase schema/RPC/grant/RLS changes; no automatic legacy session start; Home Play stays empty; existing three Active Workout controls and rendered geometry stay unchanged; the existing explicit Start New conflict behavior is reused; no E2E, W8 or offline persistence work.

## Active Handoff

**Planning owner:** Product owner

**Implementation owner:** Codex

**Previous agent:** Not applicable

**Last commit agent:** Codex

**Last implementation commit SHA:** `bb9b57f222b01016b145d65a6e334762fbc5a634` (Program/Library Routine Play implementation)

**Review owner:** Pending

**Implementation ownership state:** Ready for review

**Ownership transition:** Not applicable

**Repository state last verified:** 2026-11-11; root checkout `codex/w7-trigger-search-path-hardening` fast-forwarded to `b8c1a7dba1d4f6b1bf1fa03d95969dde467fdd6b`, matching origin and clean. Its prior handoff edit matched the upstream branch file exactly and was preserved through the alignment. Implementation worktree is `codex/w7-routine-start`, based on `main@3e5b70c6467c704d2a67fd7210b0babd55aa2215`.

**Branch:** `codex/w7-routine-start`

**Validated source HEAD SHA:** `bb9b57f222b01016b145d65a6e334762fbc5a634` (implementation commit; handoff-only commits follow it)

**Observed working-tree state:** Source commit `bb9b57f` is validated; this handoff update was the only modified file immediately before its documentation commit. Isolated worktree: `.claude/worktrees/w7-routine-start`.

**Observed uncommitted/dirty files:** `.ai/tasks/w7-routine-start-workout-entry.md` only immediately before its documentation commit. The root checkout is clean and aligned with its upstream branch.

**PR / tracker:** Linear TNYX-84 In Progress; W3/W4 and authenticated Save E2E blockers remain. No PR for this slice.

**Current implementation state:** Routine Detail CTA, validated start request, local draft seeding, rep-range hint, and direct play entry points on Program Detail and expanded Library Routine rows are implemented through the same guarded flow. No PR has been opened.

**Relevant execution surfaces:** Routine Detail CTA, Program Detail Routine-row play, and expanded Library Routine-row play -> owner/session-verified app callback -> the same verified Routine composition request and existing `runWorkoutPlayStart` conflict flow -> local draft controller -> existing Active Workout route.

**Validation completed at SHA:** `bb9b57f222b01016b145d65a6e334762fbc5a634`.

**Validation remaining:** Repository CI's pinned Melos 2.9.0 bootstrap/analyze/test has not run locally. The available Melos 8.6.0 rejects this legacy workspace configuration; affected-package formatting, analysis and focused tests were run directly. Exact-head CI and independent review remain pending.

**Current blocker:** None for local review. Exact-head CI and independent review remain required before merge.

**Open review finding IDs:** None.

**Next exact action:** Open a PR for independent review and exact-head CI only when explicitly requested; keep TNYX-84 In Progress.

## Global UI / Design-System Guardrail

Before visual code edits, use `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, reusable `apps/core` components and `apps/features/AGENTS.md`. CTA is a one-off feature composition using existing `TioButton` and governed spacing.

## 1. Discovery

### User Outcome

A user can start a planned Routine from Routine Detail, Program Detail, or an expanded Library Routine row and immediately log its preloaded Exercises and planned Sets without manually adding them; `Log Workout` stays in the app bar, while the Routine name pre-fills the editable Save title. Home Play continues to start an empty workout.

### Success Criteria

- A `Start Routine` CTA is displayed just below the Routine Detail top bar only for an owner/session-verified, ready, non-empty, executable Routine.
- Program Detail and expanded Library Routine rows expose an accessible play icon only when the caller supplies the current owner/session-verified start capability; tapping it starts the same Routine-seeded workout flow directly.
- Starting opens the existing Active Workout screen with the unchanged `Log Workout` app-bar title, ordered Exercise/Set prescriptions in the account-bound local draft, and the Routine name prefilled in the editable Save title.
- A planned rep range appears in the single `REPS` input as a hint/reference only; it is never copied into performed reps or treated as logged.
- Existing draft conflict actions remain: Resume retains current workout; Start New replaces it before seeding Routine; Cancel does nothing.
- A stale auth owner/login cycle or unreadable/unexpected draft fails closed without opening a Routine-seeded screen.
- Existing three Active Workout controls are unchanged; a fresh Routine start creates no server session. Existing explicit Start New behavior remains the only path that may discard a prior legacy session.

### Scope

Routine Detail, Program Detail and expanded Library Routine-row presentation; the public Workout feature start-request contract; local draft controller initialization; app shell guarded routing; and minimal canonical screen documentation reconciliation.

### Non-Goals

Routine-linked history identity, Save API/migration changes, authenticated Save E2E, empty/unsupported Routine execution, UI redesign, Play behavior change, workout-session persistence changes, W8 or new offline queue work.

## 2. Codebase Exploration

### Verified Evidence

- Current Routine Detail is a read-only preview with verified owner composition and resolved Exercise entries.
- `ActiveWorkoutDraftController` owns the encrypted local Save-only draft; legacy `startSessionFromRoutine` writes an online session and is excluded.
- `runWorkoutPlayStart` already guards Resume / Start New / Cancel and durable draft uncertainty.
- Current Save DTO serializes drafts with `origin='ad_hoc'`; no Routine source ID contract exists.
- Reference `G:\projects\Tio-Workspace` copies template title/Exercises into the active workout and has no Routine ID in `startWorkoutFromTemplate`; this slice follows that template-copy behavior.
- Source inspected: `routine_detail_page.dart`, `routine_detail_controller.dart`, `active_workout_draft_controller.dart`, `active_workout_draft.dart`, `workout_play_start_flow.dart`, `shell_route.dart`, draft providers, Set/Routine composition models and screen docs.

### Existing pattern to follow

Reuse `RoutineCompositionSnapshot`, resolved non-archived `Exercise` values, `RoutineCompositionLimits`, `RoutineRestTimerPreset`, `ActiveWorkoutDraftController`, encrypted draft store and `runWorkoutPlayStart`.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Saved history retains Routine identity? | Resolved: no | Reference uses template-copy semantics; current Save contract remains `ad_hoc`; persisting Routine identity is a separate API/schema task. | Product owner |
| Start with unsupported/empty/unresolved composition? | Resolved: fail closed / hide CTA | Do not fabricate an executable prescription or partial workout. | Codex |
| Reuse legacy server-session start? | Rejected | Violates current Save-only local-draft entry boundary. | Codex |

## 4. Architecture Design

### Chosen Approach

Routine Detail constructs a feature-owned immutable start request from the verified Routine and ordered resolved composition. App shell binds a callback only when bootstrap owner and authenticated owner match and captures login cycle. Existing workout conflict flow runs first; Resume never seeds. On absent or confirmed Start New, controller verifies local memory/store are empty, validates the whole request, and persists a new local draft before routing to the existing Active Workout page.

### Ownership and Data Flow

```text
Routine Detail (verified snapshot)
  -> WorkoutRoutineStartRequest
  -> shell owner/login-cycle guard + runWorkoutPlayStart
  -> ActiveWorkoutDraftController.startFromRoutine
  -> encrypted local ActiveWorkoutDraft
  -> existing Active Workout route
```

No routine/program IDs are added to draft or saved payload; no Supabase call is made at start.

### Alternative Rejected

Calling `ActiveWorkoutController.startSessionFromRoutine` would create a server session immediately, contrary to Save-only draft semantics. A new Save API to preserve source IDs is outside approved boundaries.

### Failure and Accessibility States

Hide the CTA unless the verified Routine has 1–100 supported/resolved Exercise entries with valid 1–8 planned Sets each. Keep the existing Detail loading/failed/not-found states. If auth changes, draft storage is unreadable/non-empty, or seed validation/persistence fails, do not navigate; announce a safe generic failure without private backend details. Use a labeled `TioButton`.

## 5. Implementation Plan

- [x] Add immutable feature-owned Routine start request and validate routine composition.
- [x] Add fail-closed local draft initialization from ordered prescribed Sets, preserving unset performed values.
- [x] Render unlogged prescribed rep ranges as a reference hint in the existing single `REPS` input; retain blank performed reps until entered.
- [x] Extend shared Play conflict flow with an optional seed callback, called only for fresh/new; keep existing callers unchanged.
- [x] Add the Routine Detail CTA and owner/login-cycle guarded app route callback.
- [x] Reconcile directly conflicting screen documentation and the current task index.
- [x] Add direct Program Detail and expanded Library Routine-row Play actions that reuse the same owner/session-guarded draft start flow.
- [x] Format-check all changed Dart files, analyze `apps/app` and `apps/features/workout`, and run focused feature and app route regression tests; `git diff --check` passed.

## 6. Quality Review

### Validation Run

```text
PASS: Flutter 3.44.6 / Dart 3.12.2 tool versions verified; `dart format --output=none --set-exit-if-changed` on all 12 changed Dart files (0 changes).
PASS: `flutter pub get --offline --enforce-lockfile` in `apps/app` and `apps/features/workout`; no lockfile changes.
PASS: `flutter analyze --no-pub` in `apps/app` and `apps/features/workout`; no issues found after formatting.
PASS: 91 focused Workout Library, Program Detail and Routine controller tests; all 92 `workout_exercises_route_test.dart` cases, including direct Program Detail/Library Play reaching the current Active Workout route with one seeded local draft.
PASS: `flutter analyze --no-pub` in `apps/app` and `apps/features/workout`; no issues found.
PASS: `git diff --check` and `git diff --cached --check`.
BLOCKED: The repository-pinned Melos 2.9.0 workflow was not run locally; an earlier attempt with available Melos 8.6.0 exited 1 because it rejected the legacy workspace (`Your current directory does not appear to be within a Melos workspace`). `melos analyze` and `melos test` were not run with that incompatible version. CI pins Melos 2.9.0. Affected packages were validated directly; exact-head CI remains pending.
NOTE: The Workout test command emitted the existing `uses-material-design` package-configuration warning; all 183 tests passed.
NOT RUN: authenticated Save E2E, device acceptance, and visual/runtime review.
```

### Acceptance Evidence

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| `Log Workout` app bar stays fixed; Routine title pre-fills editable Save title; ordered Exercises and planned Sets seed local draft | `ActiveWorkoutDraftController.startFromRoutine`; existing `SaveWorkoutPage.initialTitle` binding | Source inspected; runtime not verified | `codex/w7-routine-start` at base `3e5b70c` | No analyzer/device acceptance |
| Rep range remains a hint, performed reps stay blank until typed | `WorkoutSetInputRow` | Source inspected; runtime not verified | `codex/w7-routine-start` | No widget/runtime verification |
| Empty Home Play stays empty; three controls unchanged | Existing Home Play call has no seed callback; `ActiveWorkoutPage` untouched | Diff inspection | `codex/w7-routine-start` | No analyzer/device acceptance |
| Program Detail and expanded Library Play start the same Routine draft without opening Detail | Routine row callback propagation and shared app-shell start handler | `program_detail_page_test.dart`, `library_page_test.dart`, and app route tests; both entry paths reached the current `ActiveWorkoutPage`, saved one draft, and preserved Routine title/ordered Exercise/prescription | `codex/w7-routine-start` | No device acceptance |
| Owner/session and existing-draft conflict guards fail closed | Shell callback and `runWorkoutPlayStart` | Source inspection plus route regression suite; authenticated Save E2E not run | `codex/w7-routine-start` | No authenticated Save E2E |
| Saved history remains ad-hoc | Existing save contract | Source contract inspection | main@3e5b70c | No Routine provenance in history |

### Review Provenance

**Review source / link:** Self-review of `bb9b57f222b01016b145d65a6e334762fbc5a634`; independent review is pending

**Reviewer / relation to implementer:** Codex, implementer

**Diff or commit SHA actually reviewed:** `bb9b57f222b01016b145d65a6e334762fbc5a634` on `codex/w7-routine-start`, parent `3e5b70c6467c704d2a67fd7210b0babd55aa2215`

**Review result and finding IDs/dispositions:** Manual scope and boundary review; no independent findings collected.

**Independent review?** No (self-review)

**Limitations and unmet required gates:** Repository-wide Melos 2.9.0 CI workflow, independent PR review, authenticated Save E2E and device acceptance have not run. No PR was opened in this commit/push task.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/w7-routine-start-workout-entry.md`
- `apps/app/lib/app/routing/shell/shell_route.dart`
- `apps/app/test/app/workout_exercises_route_test.dart`
- `apps/features/workout/lib/src/domain/models/models.dart`
- `apps/features/workout/lib/src/domain/models/workout_routine_start_request.dart`
- `apps/features/workout/lib/src/presentation/controllers/active_workout_draft_controller.dart`
- `apps/features/workout/lib/src/presentation/library/library_page.dart`
- `apps/features/workout/lib/src/presentation/library/programs/program_detail_page.dart`
- `apps/features/workout/lib/src/presentation/library/programs/programs_surface.dart`
- `apps/features/workout/lib/src/presentation/library/routines/inline_program_routines.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_detail_controller.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_detail_page.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_metadata_card.dart`
- `apps/features/workout/lib/src/presentation/widgets/workout_set_input_row.dart`
- `apps/features/workout/lib/src/presentation/workout_play_start_flow.dart`
- `apps/features/workout/test/presentation/library_page_test.dart`
- `apps/features/workout/test/presentation/program_detail_page_test.dart`
- `apps/features/workout/test/presentation/routine_detail_controller_test.dart`
- `docs/screens/active-workout.md`
- `docs/screens/programs.md`
- `docs/screens/routine-library.md`
- `docs/screens/workout.md`

### Actual Behavior

Routine Start and Program/Library Routine-row Play prepare the existing Save-only local draft with Routine title, ordered supported Exercises, planned prescriptions and rest timer presets. The app bar remains `Log Workout`; the Routine name pre-fills the editable Save title. The single `REPS` field shows a planned range only as a hint; performed reps remain blank until typed. Home Play remains empty and the three existing workout controls are unchanged.

### Known Limitations

Routine source identity is not saved. Existing TNYX-84 W3/W4 dependencies, authenticated Save E2E and device acceptance remain open.

### Final Status

`REVIEW` — affected-package formatting, analysis and focused regression tests pass. Independent review and exact-head CI remain pending; this is not a merge or completion claim.

### One Next Task

Push the validated commits to `codex/w7-routine-start`, then await exact-head CI and independent review through a PR when its creation is explicitly requested. Keep TNYX-84 In Progress.
