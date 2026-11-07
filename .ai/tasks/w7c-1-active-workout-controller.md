# Feature Task: W7C-1 Active Workout Controller & State Orchestration

**Status:** In progress
**Primary owner:** Antigravity
**Affected platforms:** Flutter (apps/features/workout, apps/app)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice (bounded presentation controller & state orchestration)
**Approval status:** Approved
**Approval evidence:** User prompt explicit GO instructions:
1. "GO — Implement W7C-1 Active Workout Controller & State Orchestration only."
2. "Use the completed W7C-1 read-only audit as the initial implementation proposal."
3. "This approval is limited to controller logic, state contracts, provider wiring and focused tests."
4. "Do not implement UI, navigation, hosted deployment or offline persistence."

**Approved product/UI/data-shape boundaries:**
- `ActiveWorkoutState` and `ActiveRestTimerState` models in `apps/features/workout/lib/src/presentation/controllers/active_workout_state.dart`.
- `ActiveWorkoutController` in `apps/features/workout/lib/src/presentation/controllers/active_workout_controller.dart`.
- Presentation layer exports update in `controllers.dart`.
- Authentication-aware Riverpod provider `activeWorkoutControllerProvider` in `apps/app/lib/app/composition/workout_providers.dart`.
- Focused unit, contract, and provider tests.

**Explicit non-changes:**
- No Active Workout UI, Start Workout UI, or visible screen/navigation changes.
- No `/workout/active` route registration.
- No hosted Supabase deployment or modification (`oykupyiitspujzpwwvuj` untouched).
- No new database schema, migrations, or RPC modifications.
- No `shared_preferences` pending mutation queue or offline SQLite/Isar database (strictly online-first, W7B-2B deferred).
- No Wear OS or Apple Watch changes.
- No PR/RIR analytics or W8 history redesign.
- No auto-merge or direct PR merge.

## Active Handoff

This is a compact recovery checkpoint, not a live activity log. Refresh it only at meaningful durable checkpoints, when implementation pauses, when ownership changes, or when recovery is needed. Use `Not applicable` where no handoff state exists.

**Planning owner:** Antigravity
**Implementation owner:** Antigravity
**Review owner:** im-tio
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-11-07 20:25 UTC+05:30
**Branch:** `feat/w7c-1-active-workout-controller`
**HEAD SHA:** `bb86b36870074ffbe29b7c8a544c0cc7abfba677`
**Observed working-tree state:** Clean branch branched from origin/main
**Observed uncommitted/dirty files:** None
**PR / tracker:** Linear TNYX-84 (W7 Active Workout)
**Current implementation state:** Implementation in progress
**Relevant execution surface:** `apps/features/workout/`, `apps/app/`
**Validation completed at SHA:** bb86b36870074ffbe29b7c8a544c0cc7abfba677
**Validation remaining:** Unit tests, provider lifecycle tests, Flutter analyze
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Implement `active_workout_state.dart` and `active_workout_controller.dart`.

## Global UI / Design-System Guardrail

Non-visual controller and state orchestration slice. No screens, design tokens, or UI layouts were touched or modified.

## 1. Discovery

### User Outcome
A canonical, resilient, and authentication-aware Active Workout presentation controller that orchestrates active/paused workout sessions, set logging, timing calculations, and failure recovery using the existing `WorkoutSessionRepository`.

### Success Criteria
- Restores existing active or paused sessions via `getActiveSession()`.
- Starts a session from validated Routine/snapshot context with duplicate prevention.
- Logs and removes performed sets with OCC revision checks and set slot conflict detection.
- Handles pause, resume, finish, and discard lifecycle transitions cleanly.
- Computes active elapsed duration derived from `WorkoutTime` without background service or ticking persistence.
- Provides timestamp-derived Rest Timer state.
- Gracefully handles OCC conflicts, committed-readback failures, and unknown outcomes with safe state reconciliation.
- Invalidates and clears memory upon auth change without cross-user leak.

### Non-Goals
- Active Workout Screen and UI widgets (deferred to W7C-2).
- Route registration `/workout/active` (deferred to W7C-2).
- Offline SQLite mutation queue (deferred to W7B-2B).
- PR/RIR analytics or history views (deferred to W8/W10).
- Hosted Supabase deployment.

## 2. Codebase Exploration

### Verified Evidence
- Merged W7A domain aggregate `WorkoutSession`, `PerformedSet`, `WorkoutTime`, `WorkoutExecutionReadiness`.
- Merged W7B-2A `WorkoutSessionRepository`, `WorkoutSessionRecord`, `WorkoutSessionPersistenceException`, `WorkoutSessionCommittedReadbackException`.
- Composition root `workoutSessionRepositoryProvider` in `apps/app/lib/app/composition/workout_providers.dart`.
- Standard controller pattern: `ChangeNotifier` with immutable state, `_version` guard, and `_disposed` check.

## 3. Architecture Design

### Chosen Approach
- Controller: `ActiveWorkoutController extends ChangeNotifier`.
- State: `ActiveWorkoutState` immutable model with typed `ActiveWorkoutStatus`, `WorkoutSessionRecord?`, `ActiveRestTimerState?`, active elapsed duration, and action pending flags.
- Command serialization: `_isActionInFlight` prevents overlapping async calls.
- Pure clock derivation: `DateTime Function() clock` injected for testability; active duration derived from `time.elapsedActiveDuration(now)`.

### Ownership and Data Flow
```text
UI (Future W7C-2) -> ActiveWorkoutController -> WorkoutSessionRepository -> SupabaseWorkoutSessionGateway -> Supabase RPCs
```

### Alternative Rejected
- Separate Routine vs Program session engines: Rejected to preserve canonical `WorkoutSession` identity across all execution contexts.
- Permanent background ticking service: Rejected; duration is purely derived from authoritative session timestamps (`startedAtUtc`, `pausedAtUtc`, `accumulatedPausedDuration`), making background ticking unnecessary.
- Automatic rest timer start without user confirmation: Deferred to W7C-2 owner UI approval; controller provides timing calculation primitives without premature interaction locking.

## 4. Implementation Plan

- [x] Create `ActiveWorkoutState` and `ActiveRestTimerState` models.
- [x] Create `ActiveWorkoutController` with command serialization and recovery.
- [x] Export controller and state in `controllers.dart`.
- [x] Wire `activeWorkoutControllerProvider` in `apps/app/lib/app/composition/workout_providers.dart`.
- [x] Write unit tests in `active_workout_controller_test.dart`.
- [x] Write provider lifecycle tests in `active_workout_controller_provider_test.dart`.
- [ ] Push branch and open PR for independent review.

## 5. Quality Review

### Acceptance Evidence (substantive scope)

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Session restore | `active_workout_controller.dart` | `restores active running session`, `restores paused session` tests pass | Local Flutter test runner | None |
| Start validation | `active_workout_controller.dart` | `starts session from routine with execution readiness check` passes | Local Flutter test runner | None |
| Duplicate start protection | `active_workout_controller.dart` | `rejects start when session is already running` passes | Local Flutter test runner | None |
| Command serialization | `active_workout_controller.dart` | `serializes commands and rejects concurrent second tap` passes | Local Flutter test runner | None |
| Performed set logging & removal | `active_workout_controller.dart` | `logs performed set`, `removes performed set` pass | Local Flutter test runner | None |
| OCC & readback recovery | `active_workout_controller.dart` | `committed mutation readback failure`, `staleRevisionConflict` pass | Local Flutter test runner | None |
| Auth invalidation & isolation | `active_workout_controller.dart`, provider | `invalidates controller when auth changes` passes | Local Flutter test runner | None |

## 6. Final Handoff

### Changed Files
- `apps/features/workout/lib/src/presentation/controllers/active_workout_state.dart` (new)
- `apps/features/workout/lib/src/presentation/controllers/active_workout_controller.dart` (new)
- `apps/features/workout/lib/src/presentation/controllers/controllers.dart` (modified)
- `apps/app/lib/app/composition/workout_providers.dart` (modified)
- `apps/features/workout/test/presentation/active_workout_controller_test.dart` (new)
- `apps/app/test/app/active_workout_controller_provider_test.dart` (new)
- `.ai/tasks/w7c-1-active-workout-controller.md` (new)

### Final Status

`READY FOR REVIEW`
