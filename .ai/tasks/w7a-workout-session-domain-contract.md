# Feature Task — W7A: WorkoutSession, PerformedSet and Execution-Readiness Domain Foundation

**Status:** Validated
**Primary owner:** Antigravity (AI Coding Assistant)
**Affected platforms:** Flutter mobile (`apps/app`), shared pure-Dart domain (`apps/shared`), workout feature (`apps/features/workout`)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** User prompt explicit instruction: "Status: Owner-approved W7A bounded implementation; Primary Linear: TNYX-84; Parent: TNYX-76".
**Approved product/UI/data-shape boundaries:**
- Pure-Dart models in `apps/shared/lib/src/workout/`: `WorkoutSession`, `WorkoutSessionStatus`, `WorkoutTime`, `PerformedSet`, `WorkoutSessionSnapshot`, `SessionExerciseSnapshot`.
- Domain readiness validation policy in `apps/features/workout/lib/src/domain/`: `WorkoutExecutionReadiness`, `WorkoutReadinessValidator` for `weightReps` measurement profile.
- PR (Personal Record) and RIR (Reps in Reserve) audited and documented as future contracts (no speculative persistence, calculation engine, or UI).
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
**Review owner:** Antigravity (self-review)
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-11-05 19:42 UTC+05:30
**Branch:** `feat/tnyx-84-w7a-workout-session-domain`
**HEAD SHA:** `225c2be2d5570f787f25a323877cef0f66e7ba37` (base)
**Observed working-tree state:** Implementation complete, tests pass, ready for commit & PR
**Observed uncommitted/dirty files:** W7A domain files, tests, and doc updates
**PR / tracker:** Linear TNYX-84, Parent TNYX-76; GitHub #48, #526, #715
**Current implementation state:** Complete and verified
**Relevant execution surface:** `apps/shared/lib/src/workout/`, `apps/features/workout/lib/src/domain/`
**Validation completed at SHA:** Feature branch working tree: 138 shared workout tests passed (100%), 68 feature domain tests passed (100%), 0 analyze errors.
**Validation remaining:** Remote CI run on opened PR
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Commit, push branch, create PR, and summarize report

## 1. Discovery

### User Outcome
Establish a robust, immutable pure-Dart domain foundation for active workout sessions, performed sets, duration/pause accounting, historical snapshots, and execution readiness before any UI or Supabase persistence is implemented.

### Success Criteria
1. Pure-Dart domain models in `apps/shared`:
   - `WorkoutSessionId` reused from existing contract.
   - `WorkoutSessionStatus`: `active`, `paused`, `completed`, `discarded` with legal transition rules.
   - `WorkoutTime`: UTC timestamps, monotonic elapsed time, pause-excluded active duration accounting.
   - `PerformedSet`: separate from `SetPrescription`, stable UUID identity, canonical `loadKg`, non-negative `reps`, occurrence index for repeated exercises.
   - `WorkoutSessionSnapshot` & `SessionExerciseSnapshot`: defensive immutable snapshot freezing routine name, program id, exercise order, and set prescriptions at start time.
   - `WorkoutSession`: composite aggregate root enforcing lifecycle invariants.
2. Execution readiness in `apps/features/workout`:
   - Deterministic validation for the initial approved `weightReps` profile.
   - Rejection reasons: empty routine, no executable sets, missing exercise, unsupported profile (distance/duration/etc.), invalid ownership/program context.
3. PR & RIR audit and sequencing documentation completed without premature code.
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

## 5. Implementation Plan
- [x] Create feature branch `feat/tnyx-84-w7a-workout-session-domain`.
- [ ] Implement `WorkoutSessionStatus` and legal transitions.
- [ ] Implement `WorkoutTime` with pause accounting and UTC validation.
- [ ] Implement `PerformedSet` with UUID identity and canonical fields.
- [ ] Implement `SessionExerciseSnapshot` and `WorkoutSessionSnapshot`.
- [ ] Implement `WorkoutSession` aggregate root.
- [ ] Implement `WorkoutExecutionReadiness` and `WorkoutReadinessValidator`.
- [ ] Add comprehensive tests in `apps/shared/test/workout/` and `apps/features/workout/test/domain/`.
- [ ] Run `dart analyze` and tests.
- [ ] Push branch and open GitHub PR.
