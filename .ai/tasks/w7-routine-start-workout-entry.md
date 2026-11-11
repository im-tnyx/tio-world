# W7 Routine Start Workout Entry

**Status:** Blocked

**Primary owner:** Codex

**Affected platforms:** Flutter Android + iOS

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice; product-visible UI/UX change

**Approval status:** Approved

**Approval evidence:** Owner request in this conversation: add `Start Routine` directly below Routine Detail's top bar; start the same Log Workout screen with Routine title, ordered Exercises and planned Sets; preserve the existing three controls. Follow-up authorized reference inspection of `G:\projects\Tio-Workspace` and accepted template-copy Save semantics.

**Approved product/UI/data-shape boundaries:** Routine Detail CTA seeds the existing account-bound encrypted local `ActiveWorkoutDraft` from the verified Routine composition; title, Exercise occurrence order, planned `SetPrescription`s and existing rest presets are carried forward. A planned rep range (for example `8–12`) appears as reference hint in the single `REPS` input while actual reps remain blank/unlogged until entered and checked. `Start New` conflict path uses the same seed after replacement.

**Explicit non-changes:** Routine/Program source identity is not stored in saved history (`origin='ad_hoc'` remains); no Supabase schema/RPC/grant/RLS changes; no automatic legacy session start; Home Play stays empty; existing three Active Workout controls and rendered geometry stay unchanged; the existing explicit Start New conflict behavior is reused; no E2E, W8 or offline persistence work.

## Active Handoff

**Planning owner:** Product owner

**Implementation owner:** Codex

**Previous agent:** Not applicable

**Last commit agent:** Not applicable

**Last commit SHA:** Not applicable

**Review owner:** Pending

**Implementation ownership state:** Blocked

**Ownership transition:** Not applicable

**Repository state last verified:** 2026-11-11; original checkout remains `codex/w7-trigger-search-path-hardening` at `6779f6975b3f0641eee4b12472d3edfa9c5db4fd` with pre-existing modification only in `.ai/tasks/w7-trigger-search-path-hardening.md`; implementation uses isolated worktree based on local verified `main@3e5b70c6467c704d2a67fd7210b0babd55aa2215`.

**Branch:** `codex/w7-routine-start`

**HEAD SHA:** `3e5b70c6467c704d2a67fd7210b0babd55aa2215`

**Observed working-tree state:** Clean at task start; isolated worktree `.claude/worktrees/w7-routine-start`.

**Observed uncommitted/dirty files:** None at task start in implementation worktree. Original checkout modification preserved separately.

**PR / tracker:** Linear TNYX-84 In Progress; W3/W4 and authenticated Save E2E blockers remain. No PR for this slice.

**Current implementation state:** Routine Detail CTA, validated start request, local draft seeding and rep-range hint are implemented in this isolated worktree. Source/docs review is pending tool-backed validation.

**Relevant execution surface:** Routine Detail -> owner/session-verified app callback -> existing `runWorkoutPlayStart` conflict flow -> local draft controller -> existing Active Workout route.

**Validation completed at SHA:** `git diff --check` passed (exit 0) at `3e5b70c6467c704d2a67fd7210b0babd55aa2215` plus uncommitted changes.

**Validation remaining:** `dart`, `flutter`, `melos` and `fvm` are not available on PATH. A safe executable-name scan under `G:\dev` (excluding protected credential/session/history/log/cache areas) found none of those binaries. The repository has no local wrapper. `melos bootstrap`, `melos analyze` and `melos test` were each attempted and failed before execution with PowerShell command-not-found (exit 127); formatting, analysis and tests therefore remain unverified.

**Current blocker:** Flutter/Dart formatter and analyzer unavailable; code is not ready for PR/merge review.

**Open review finding IDs:** None.

**Next exact action:** Run formatter and targeted Flutter analysis with the repository-compatible Dart toolchain; fix findings before PR review.

## Global UI / Design-System Guardrail

Before visual code edits, use `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, reusable `apps/core` components and `apps/features/AGENTS.md`. CTA is a one-off feature composition using existing `TioButton` and governed spacing.

## 1. Discovery

### User Outcome

A user can start a planned Routine from its Detail page and immediately log its preloaded Exercises and planned Sets without manually adding them; `Log Workout` stays in the app bar, while the Routine name pre-fills the editable Save title. Home Play continues to start an empty workout.

### Success Criteria

- A `Start Routine` CTA is displayed just below the Routine Detail top bar only for an owner/session-verified, ready, non-empty, executable Routine.
- Starting opens the existing Active Workout screen with the unchanged `Log Workout` app-bar title, ordered Exercise/Set prescriptions in the account-bound local draft, and the Routine name prefilled in the editable Save title.
- A planned rep range appears in the single `REPS` input as a hint/reference only; it is never copied into performed reps or treated as logged.
- Existing draft conflict actions remain: Resume retains current workout; Start New replaces it before seeding Routine; Cancel does nothing.
- A stale auth owner/login cycle or unreadable/unexpected draft fails closed without opening a Routine-seeded screen.
- Existing three Active Workout controls are unchanged; a fresh Routine start creates no server session. Existing explicit Start New behavior remains the only path that may discard a prior legacy session.

### Scope

Routine Detail presentation, public Workout feature start-request contract, local draft controller initialization, app shell guarded routing, and minimal canonical screen documentation reconciliation.

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
- [ ] Format and run the required Flutter bootstrap, analyzer and tests when the repository-compatible SDK/CLI is available; `git diff --check` passed.

## 6. Quality Review

### Validation Run

```text
PASS: `git diff --check` (exit 0), 2026-11-11.
BLOCKED: `melos bootstrap`, `melos analyze`, `melos test` each exited 127 because `melos` is not recognized; `dart`, `flutter`, `melos` and `fvm` were absent from PATH and from the safe `G:\dev` executable scan.
NOT RUN: `dart format`, targeted widget tests and runtime/device verification because no Dart/Flutter SDK was available.
```

### Acceptance Evidence

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| `Log Workout` app bar stays fixed; Routine title pre-fills editable Save title; ordered Exercises and planned Sets seed local draft | `ActiveWorkoutDraftController.startFromRoutine`; existing `SaveWorkoutPage.initialTitle` binding | Source inspected; runtime not verified | `codex/w7-routine-start` at base `3e5b70c` | No analyzer/device acceptance |
| Rep range remains a hint, performed reps stay blank until typed | `WorkoutSetInputRow` | Source inspected; runtime not verified | `codex/w7-routine-start` | No widget/runtime verification |
| Empty Home Play stays empty; three controls unchanged | Existing Home Play call has no seed callback; `ActiveWorkoutPage` untouched | Diff inspection | `codex/w7-routine-start` | No analyzer/device acceptance |
| Owner/session and existing-draft conflict guards fail closed | Shell callback and `runWorkoutPlayStart` | Source inspected; runtime not verified | `codex/w7-routine-start` | No analyzer/authenticated Save E2E |
| Saved history remains ad-hoc | Existing save contract | Source contract inspection | main@3e5b70c | No Routine provenance in history |

### Review Provenance

**Review source / link:** Self-review of uncommitted source diff

**Reviewer / relation to implementer:** Codex, implementer

**Diff or commit SHA actually reviewed:** Uncommitted diff on `codex/w7-routine-start`, base `3e5b70c`

**Review result and finding IDs/dispositions:** Manual scope and boundary review; no independent findings collected.

**Independent review?** No (self-review)

**Limitations and unmet required gates:** Formatter/analyzer unavailable; no tests, independent review, authenticated Save E2E, device acceptance or PR CI run yet.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/w7-routine-start-workout-entry.md`
- `apps/app/lib/app/routing/shell/shell_route.dart`
- `apps/features/workout/lib/src/domain/models/models.dart`
- `apps/features/workout/lib/src/domain/models/workout_routine_start_request.dart`
- `apps/features/workout/lib/src/presentation/controllers/active_workout_draft_controller.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_detail_page.dart`
- `apps/features/workout/lib/src/presentation/widgets/workout_set_input_row.dart`
- `apps/features/workout/lib/src/presentation/workout_play_start_flow.dart`
- `docs/screens/active-workout.md`
- `docs/screens/programs.md`
- `docs/screens/routine-library.md`
- `docs/screens/workout.md`

### Actual Behavior

Routine Start prepares the existing Save-only local draft with Routine title, ordered supported Exercises, planned prescriptions and rest timer presets. The app bar remains `Log Workout`; the Routine name pre-fills the editable Save title. The single `REPS` field shows a planned range only as a hint; performed reps remain blank until typed. Home Play remains empty and the three existing workout controls are unchanged.

### Known Limitations

Routine source identity is not saved. Existing TNYX-84 W3/W4 dependencies, authenticated Save E2E and device acceptance remain open.

### Final Status

`BLOCKED` — implementation is present, but Dart formatting and Flutter analysis could not run; do not open or merge a PR until validated.

### One Next Task

Run formatter and targeted Flutter analysis with the repository-compatible Dart toolchain, fix findings, and refresh this handoff before PR review.
