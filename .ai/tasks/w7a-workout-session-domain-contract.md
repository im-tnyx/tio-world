# Feature Task — W7A: WorkoutSession, PerformedSet and Execution-Readiness Domain Foundation

**Status:** Review
**Primary owner:** Antigravity (AI Coding Assistant)
**Affected platforms:** Flutter mobile (`apps/app`), shared pure-Dart domain (`apps/shared`), workout feature (`apps/features/workout`)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** User prompt explicit instruction: "Status: Owner-approved W7A bounded implementation; Primary Linear: TNYX-84; Parent: TNYX-76".
**Approved product/UI/data-shape boundaries:**
- Pure-Dart models in `apps/shared/lib/src/workout/`: `WorkoutSession`, `WorkoutSessionStatus`, `WorkoutTime`, `PerformedSet`, `WorkoutSessionSnapshot`, `SessionExerciseSnapshot`.
- Domain readiness validation policy in `apps/features/workout/lib/src/domain/`: `WorkoutExecutionReadiness`, `WorkoutReadinessValidator` for `weightReps` measurement profile.
- PR (Personal Record) and RIR (Reps in Reserve) audited and documented as separate planned exploratory metrics (no permanent contracts, speculative persistence, calculation engine, or UI).
**Explicit non-changes:**
- No Start Workout button or Routine-card Play action.
- No Active Workout screen or navigation routes.
- No Supabase migrations, RPCs, table/column alterations, or hosted schema changes.
- No live rest timer UI.
- No Workout History UI.
- No Wear OS / watchOS execution changes.
- No GitHub #715 JSONB consolidation.
- No unapproved UI redesign.

## Active Handoff

**Planning owner:** Antigravity
**Implementation owner:** Antigravity
**Review owner:** Antigravity (self-review) / `im-tio` (code review)
**Implementation ownership state:** Complete (review fixes implemented)
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-11-05 20:30 UTC+05:30
**Branch:** `feat/tnyx-84-w7a-workout-session-domain`
**HEAD SHA (PR #730 base):** `d625f0453f5e945792c256847dc1cbe809f5ebef`
**Observed working-tree state:** Review findings resolved, regression tests added, clean analysis
**Observed uncommitted/dirty files:** `workout_time.dart`, `workout_session.dart`, test suites, task brief
**PR / tracker:**
- Primary Linear: `TNYX-84` (W7 Active Workout)
- Parent Linear: `TNYX-76` (W. Workout Foundation)
- Related Linear issues:
  - `TNYX-81`: W4 Programs & Routines
  - `TNYX-85`: W8 Workout History
  - `TNYX-87`: W10 Workout Settings
- Slice Label Clarification: W7B and W7C are internal implementation slice labels for W7 Active Workout, NOT synonyms for `TNYX-85` or `TNYX-87`.
- GitHub: PR #730, Backlog #48, Context #526, Consolidation #715
**Current implementation state:** Complete, review findings fixed and verified
**Relevant execution surface:** `apps/shared/lib/src/workout/`, `apps/features/workout/lib/src/domain/`
**Validation completed at SHA:** Feature branch working tree: 144 shared workout tests passed (100%), 68 feature domain tests passed (100%), 0 analyze errors.
**Validation remaining:** Remote GitHub Actions CI on PR #730
**Current blocker:** None (awaiting PR re-review from `im-tio`)
**Open review finding IDs:**
- Resolved: Bugbot Monotonicity finding on `workout_time.dart` (addressed with `lastTransitionAtUtc` chronological guards and constructor validation).
- Resolved: `im-tio` P2 finding on `workout_session.dart` (addressed with snapshot exercise occurrence validation, `exerciseRef` match, set ID uniqueness, and slot uniqueness).
**Next exact action:** Commit review fixes, push to branch, verify remote CI, reply to PR #730 review comments, request re-review.

## 1. Discovery

### User Outcome
Establish a robust, immutable pure-Dart domain foundation for active workout sessions, performed sets, duration/pause accounting, historical snapshots, and execution readiness before any UI or Supabase persistence is implemented.

### Success Criteria
1. Pure-Dart domain models in `apps/shared`:
   - `WorkoutSessionId` reused from existing contract.
   - `WorkoutSessionStatus`: `active`, `paused`, `completed`, `discarded` with legal transition rules.
   - `WorkoutTime`: UTC timestamps, monotonic elapsed time, pause-excluded active duration accounting, chronological transition enforcement via `lastTransitionAtUtc`.
   - `PerformedSet`: separate from `SetPrescription`, stable UUID identity, canonical `loadKg`, non-negative `reps`, occurrence index for repeated exercises.
   - `WorkoutSessionSnapshot` & `SessionExerciseSnapshot`: defensive immutable snapshot freezing routine name, program id, exercise order, and set prescriptions at start time.
   - `WorkoutSession`: composite aggregate root enforcing lifecycle invariants, snapshot exercise occurrence checks, `exerciseRef` matching, set UUID uniqueness, and slot collision rejection.
2. Execution readiness in `apps/features/workout`:
   - Deterministic validation for the initial approved `weightReps` profile.
   - Rejection reasons: empty routine, no executable sets, missing exercise, unsupported profile (distance/duration/etc.), invalid ownership/program context.
3. PR & RIR audit and sequencing documented as separate planned exploratory metrics without premature code or unapproved permanent contracts.
4. Comprehensive test coverage and 0 static analysis errors.

### Scope
- `apps/shared/lib/src/workout/workout_session_status.dart`
- `apps/shared/lib/src/workout/workout_time.dart`
- `apps/shared/lib/src/workout/performed_set.dart`
- `apps/shared/lib/src/workout/workout_session_snapshot.dart`
- `apps/shared/lib/src/workout/workout_session.dart`
- `apps/shared/lib/src/workout/workout.dart` (exports)
- `apps/features/workout/lib/src/domain/workout_execution_readiness.dart`
- `apps/features/workout/lib/src/domain/workout_readiness_validator.dart`
- `apps/features/workout/lib/workout.dart` (exports)
- Unit tests under `apps/shared/test/workout/` and `apps/features/workout/test/domain/`

### Non-Goals
- Any UI screen, card, button or widget.
- Supabase persistence, migrations, RPCs.
- Active workout timer background service.
- PR calculation engine or notifications.
- RIR UI capture.

## 2. Codebase Exploration

### Verified Evidence
- `WorkoutSessionId` already exists as canonical UUID-backed value object in `apps/shared/lib/src/workout/workout_session_id.dart`.
- `SetPrescription` represents planned Routine configuration with `reps`, `repsMax`, `loadKg`, `distanceMeters`, `durationSeconds`, `restSeconds`.
- `RoutineComposition` and `RoutineExercise` represent ordered template entries with canonical `ExerciseRef`.
- `ExerciseType` defines measurement-profile storage identities (`weightReps`, `distanceDuration`, `duration`, etc.).
- Testing framework uses standard Dart `test` in `apps/shared` and `flutter_test` in `apps/features/workout`.

## 3. Clarification — PR and RIR Contract Audit

> [!NOTE]
> PR and RIR are separate planned exploratory metrics. The formulas and candidate ranges below reflect exploratory planning documentation and are not an unapproved permanent contract or premature implementation.

### PR (Personal Record) Audit
- **Contract Boundary:** PR is a *derived historical computation* computed from confirmed `completed` sessions only. It is never an input field on `PerformedSet` or `SetPrescription`.
- **Identity Scope:** PR is scoped by `(userId, ExerciseRef, ExerciseType)`.
- **Eligibility:**
  - `RoutineSetType.warmUp` sets are excluded.
  - Skipped sets (`isSkipped == true`) are excluded.
  - Sets with 0 reps are excluded.
  - `RoutineSetType.normal`, `failure`, and `drop` sets are eligible if completed.
- **Comparison Rules:**
  - Max Load (Heaviest Weight): highest canonical `loadKg`.
  - Max Volume: highest `loadKg * reps`.
  - Max Reps: highest `reps` at a given `loadKg`.
  - Estimated 1RM: calculated using standard formulas (e.g., Epley: $w \cdot (1 + r/30)$).
- **Ties & Recalculation:** Chronologically earlier set retains precedence. Edits or deletions of past workouts trigger server-side recalculation over remaining completed sessions.

### RIR (Reps in Reserve) Audit
- **Contract Boundary:** RIR is an *optional user-entered effort metric* on `PerformedSet` (actual performance), strictly distinct from `SetPrescription` (template) and `WorkoutProfile` / `WorkoutTargets` (onboarding/goals).
- **Semantics:** Integer in range `[0, 10]`.
  - `null` = not recorded / omitted by user.
  - `0` = absolute muscular failure (no further reps possible with good form).
  - Collapsing `null` to `0` is strictly forbidden.
- **RIR vs RPE:** RPE is rate of perceived exertion (typically 1-10 or 6-10 scale). $RIR = 10 - RPE$ for equivalent load. GitHub #48 confirms a future user setting will let athletes choose RIR vs RPE display preference.
- **Sequencing:** W7A audits the contract; W7B or active workout slice introduces the optional field on persistence/UI when set logging is wired.

## 4. Architecture Design

```text
RoutineTemplate -> WorkoutReadinessValidator -> WorkoutExecutionReadiness
                                                       ↓ (if ready)
                                          WorkoutSession.start(
                                            snapshot: WorkoutSessionSnapshot.fromRoutine(...),
                                            time: WorkoutTime.start(...),
                                          )
                                                       ↓
                                            WorkoutSession (active)
                                            ├── logSet(PerformedSet)
                                            ├── pause(atUtc)
                                            ├── resume(atUtc)
                                            ├── complete(atUtc)
                                            └── discard(atUtc, reason)
```

## 5. Review Findings & Invariant Hardening

### Bugbot Monotonicity Fix
- **Issue:** Cursor Bugbot identified that `WorkoutTime` only checked `utc >= startedAtUtc` on `pause` and `finish`. If resumed at 10:15, a backdated pause at 10:12 could be accepted, corrupting `accumulatedPausedDuration`.
- **Resolution:**
  - Added `lastTransitionAtUtc` to track the exact instant of the latest state change (start, pause, resume).
  - Enforced `utc >= lastTransitionAtUtc` on `pause()`, `resume()`, and `finish()`.
  - Validated direct constructor: `lastTransitionAtUtc` must be within `[startedAtUtc, finishedAtUtc ?? now]`, and `accumulatedPausedDuration` cannot exceed elapsed wall-clock time minus active pause duration.
  - Removed duration clamping: malformed timings throw `ArgumentError` instead of masking corrupted data.

### `im-tio` P2 Snapshot & Set Invariants Fix
- **Issue:** Independent review identified that `WorkoutSession.logSet` and direct construction did not verify that `sessionExerciseIndex` corresponded to a valid snapshot exercise, that `exerciseRef` matched that snapshot occurrence, that set IDs were unique, or that duplicate set IDs did not claim the same slot.
- **Resolution:**
  - Added `_validateSinglePerformedSet`:
    - `sessionExerciseIndex` must be within `[0, snapshot.exercises.length - 1]`.
    - `set.exerciseRef` must strictly equal `snapshot.exercises[sessionExerciseIndex].exerciseRef`.
  - Added `_validatePerformedSets`:
    - Enforced unique `id` across all performed sets.
    - Enforced slot uniqueness: two different set IDs cannot share the same `(sessionExerciseIndex, setIndex)`.
  - Updated `logSet()`:
    - Verifies snapshot bounds and `exerciseRef` match.
    - Preserves in-place edits (same set ID updating its own record).
    - Rejects slot collisions when a different set ID attempts to claim an occupied `(sessionExerciseIndex, setIndex)` slot.

## 6. Implementation Plan
- [x] Create feature branch `feat/tnyx-84-w7a-workout-session-domain`.
- [x] Implement `WorkoutSessionStatus` and legal transitions.
- [x] Implement `WorkoutTime` with monotonic pause accounting and chronological guards.
- [x] Implement `PerformedSet` with UUID identity and canonical fields.
- [x] Implement `SessionExerciseSnapshot` and `WorkoutSessionSnapshot`.
- [x] Implement `WorkoutSession` aggregate root with snapshot and slot invariants.
- [x] Implement `WorkoutExecutionReadiness` and `WorkoutReadinessValidator`.
- [x] Add comprehensive regression tests in `apps/shared/test/workout/` and `apps/features/workout/test/domain/`.
- [x] Run `dart analyze` and tests.
- [x] Open GitHub PR #730.
- [x] Resolve Cursor Bugbot monotonicity finding.
- [x] Resolve `im-tio` P2 snapshot & set invariant finding.
- [ ] Push review fixes to GitHub PR #730.
- [ ] Verify remote CI and request re-review.
