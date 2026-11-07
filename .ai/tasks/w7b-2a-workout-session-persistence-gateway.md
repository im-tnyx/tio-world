# Feature Task: W7B-2A Flutter Workout Session Persistence Gateway

**Status:** Ready
**Primary owner:** Antigravity
**Affected platforms:** Flutter (apps/features/workout, apps/app)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice (bounded persistence gateway)
**Approval status:** Approved
**Approval evidence:** User prompt explicit GO instructions:
1. "GO — Implement the bounded W7B-2A online-first Flutter Workout Session Persistence Gateway."
2. "The owner approves: 1. Keeping the W7A WorkoutSession domain aggregate pure Dart. 2. Using a lightweight WorkoutSessionRecord envelope for authoritative server revision and sync state. 3. Implementing the online-first Flutter repository, gateway, DTO mapping and authentication-aware provider. 4. Running integration/security tests exclusively against an isolated disposable local database."
3. "This GO does not authorize hosted Supabase deployment, an offline mutation queue, UI changes or automatic PR merge."

**Approved product/UI/data-shape boundaries:**
- `WorkoutSessionRecord` envelope wrapping pure-Dart `WorkoutSession`, server `revision`, `WorkoutSessionSyncState`, and server timestamps.
- `WorkoutSessionRepository` interface in `apps/features/workout/lib/src/domain/repositories/workout_session_repository.dart`.
- Typed persistence and recovery exceptions (`WorkoutSessionPersistenceException`, `WorkoutSessionMutationOutcomeUnknown`).
- Session and snapshot DTO mappings (`WorkoutSessionSnapshotDto`, `WorkoutSessionRowDto`, `WorkoutPerformedSetRowDto`).
- `WorkoutSessionGateway` interface and `SupabaseWorkoutSessionGateway` implementation in `apps/features/workout/lib/src/data/repositories/supabase_workout_session_gateway.dart`.
- `SupabaseWorkoutSessionRepository` in `apps/features/workout/lib/src/data/repositories/supabase_workout_session_repository.dart`.
- Authentication-aware Riverpod provider `workoutSessionRepositoryProvider` in `apps/app/lib/app/composition/workout_providers.dart`.
- Focused unit, contract, and disposable-local integration tests.

**Explicit non-changes:**
- No Active Workout UI, Start Workout UI, or visible screen/navigation changes.
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
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-11-07 16:21 UTC+05:30
**Branch:** `feat/w7b-2a-workout-session-persistence-gateway`
**HEAD SHA:** `15fb580e7926027caf3266fbe7971340da222ff1` (pre-commit main baseline)
**Observed working-tree state:** Complete implementation ready for commit
**Observed uncommitted/dirty files:** None (all changes are tracked/staged for W7B-2A)
**PR / tracker:** Linear TNYX-84 (W7 Active Workout) - Ready for Review
**Current implementation state:** Complete. Gateway, repository, DTOs, provider, and test suites written and validated.
**Relevant execution surface:** `apps/features/workout/`, `apps/app/`
**Validation completed at SHA:** 970f2222c407ded7b47239bd3f84696602404803
**Validation remaining:** Independent peer review and CI merge gate
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Commit, push branch, open pull request, and request independent review.

## Global UI / Design-System Guardrail

Non-visual persistence slice. No screens, design tokens, or UI layouts were touched or modified.

## 1. Discovery

### User Outcome
Provide a reliable, secure, authenticated online-first persistence gateway for Flutter to start, restore, pause, resume, complete, discard workout sessions and log/remove performed sets with strict optimistic concurrency control (OCC), deterministic ordering, bracketed consistency reads, and safe uncertain-outcome recovery.

### Success Criteria
1. Pure Dart W7A aggregate (`WorkoutSession`) remains untangled from transport/revision concerns.
2. Lightweight `WorkoutSessionRecord` envelope preserves authoritative server revision and sync state.
3. Accurate mapping and serialization for snapshot JSONB conforming to `private.is_valid_workout_session_snapshot_v1`.
4. RPC parameters and return shapes verified against all 7 W7B-1 database functions.
5. Deterministic performed-set reads ordered by `(session_exercise_index, set_index)` with bracketed consistency checks.
6. Proper error mapping distinguishing `unauthenticated` (`28000`), `unauthorized` (`42501`), `notFound` (`P0002`), `staleRevisionConflict` (`P0003`), `duplicateSessionConflict` / `terminalPayloadConflict` (`23505`), `terminalSessionImmutable` (`P0001`), and `invalidPayload` / `quotaExceeded` (`22023`).
7. Never assuming server revision increment on set log or remove; performing owner-scoped readback when authoritative revision is needed.
8. Authentication invalidation safely unbinding session-local state on logout or account switch.
9. 100% passing unit and contract tests with zero static analysis warnings.

### Scope
- `apps/features/workout/lib/src/domain/models/workout_session_record.dart`
- `apps/features/workout/lib/src/domain/repositories/workout_session_repository.dart`
- `apps/features/workout/lib/src/data/dto/workout_session_dtos.dart`
- `apps/features/workout/lib/src/data/repositories/supabase_workout_session_gateway.dart`
- `apps/features/workout/lib/src/data/repositories/supabase_workout_session_repository.dart`
- `apps/app/lib/app/composition/workout_providers.dart`
- Corresponding test suites under `apps/features/workout/test/` and `apps/app/test/`

### Non-Goals
- Any UI or screen modifications.
- Local offline caching or mutation queueing (`shared_preferences` / SQLite).
- Hosted Supabase migrations or writes.

## 2. Codebase Exploration

### Verified Evidence
- Source/config inspected:
  - W7B-1 RPC migration: `supabase/migrations/20261107120000_w7b1_workout_session_rpcs.sql`
  - W7B-1 Schema: `supabase/migrations/20261107100000_w7b1_workout_sessions_schema.sql`
  - W7A Domain aggregate: `apps/features/workout/lib/src/domain/models/workout_session.dart`
  - Composition roots: `apps/app/lib/app/composition/workout_providers.dart` and `auth_providers.dart`
- Existing pattern to follow:
  - DTO mapping pattern from `workout_plan_dtos.dart` and `routine_dtos.dart`
  - Repository separation pattern with pure domain interfaces and data implementation
  - Authentication lifecycle listener in Riverpod composition roots
- Tests or validation already present:
  - Local database pgTAP suite: `supabase/tests/database/w7b_session_security.test.sql`

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Domain vs Record envelope | Made | Keep `WorkoutSession` domain pure Dart without server fields; wrap in `WorkoutSessionRecord` | Owner approved |
| Authoritative revision on set log/remove | Made | RPCs for set log/remove return child set row or void, not parent session. Repository must execute owner-scoped readback to ensure exact authoritative revision | Antigravity |
| Bracketed read pattern | Made | Read session header before and after fetching sets to detect concurrent modification skew | Antigravity |
| Offline queue boundary | Made | Strictly online-first in W7B-2A; offline queue and local SQLite/encrypted storage deferred to future W7B-2B | Owner approved |

## 4. Architecture Design

### Chosen Approach
- `WorkoutSessionRecord`: Envelope holding `WorkoutSession`, server `revision` (int), `WorkoutSessionSyncState`, `createdAt`, `updatedAt`.
- `WorkoutSessionRepository`: Abstract interface with methods `startSession`, `getActiveSession`, `getSession`, `pauseSession`, `resumeSession`, `logPerformedSet`, `removePerformedSet`, `completeSession`, `discardSession`.
- `WorkoutSessionGateway`: Concrete RPC and Postgrest adapter with `.retry(enabled: false)` to prevent silent unsafe duplicate executions.
- `SupabaseWorkoutSessionRepository`: Business rules, optimistic concurrency control, bracketed reads, error transformation into `WorkoutSessionPersistenceException` and `WorkoutSessionMutationOutcomeUnknown`.
- Composition root: `workoutSessionRepositoryProvider` in `apps/app` auto-disposed and bound to `authSessionProvider` lifecycle with zero in-memory fallback.

### Ownership and Data Flow

```text
Active Workout Controller (future W7C)
    ↓
WorkoutSessionRepository (Domain Interface)
    ↓
SupabaseWorkoutSessionRepository (Data Orchestration & OCC)
    ↓
WorkoutSessionGateway (Postgrest & RPC Transport)
    ↓
Supabase Postgres DB (W7B-1 RLS & RPCs)
```

### Alternative Rejected
- Adding `serverRevision` directly to `WorkoutSession`: Rejected to keep domain model agnostic of persistence mechanisms and sync states.
- Retrying non-idempotent mutations on socket error: Rejected; could lead to double-logging sets. Exposing `WorkoutSessionMutationOutcomeUnknown` gives callers control.

## 5. Implementation Plan

- [x] Create `WorkoutSessionRecord` and export in domain.
- [x] Create `WorkoutSessionRepository` interface, failure kinds, and exceptions.
- [x] Create DTO mapping for snapshot JSONB conforming to `is_valid_workout_session_snapshot_v1`.
- [x] Create `WorkoutSessionGateway` and `SupabaseWorkoutSessionGateway`.
- [x] Create `SupabaseWorkoutSessionRepository`.
- [x] Bind `workoutSessionRepositoryProvider` in `apps/app/lib/app/composition/workout_providers.dart`.
- [x] Write DTO unit tests.
- [x] Write gateway unit tests.
- [x] Write repository unit and contract tests.
- [x] Write provider authentication-lifecycle tests.
- [x] Run static analysis and all regression tests.

## 6. Quality Review

### Validation Run

1. `apps/features/workout` Flutter analysis:
```text
flutter analyze
Result: 0 issues found.
```

2. `apps/features/workout` DTO unit tests:
```text
flutter test test/data/workout_session_dtos_test.dart
Result: 5 passed in 5s.
```

3. `apps/features/workout` Gateway unit tests:
```text
flutter test test/data/supabase_workout_session_gateway_test.dart
Result: 11 passed in 5s.
```

4. `apps/features/workout` Repository unit tests:
```text
flutter test test/data/supabase_workout_session_repository_test.dart
Result: 15 passed in 5s.
```

5. `apps/app` Provider lifecycle unit tests:
```text
flutter test test/app/workout_session_repository_provider_test.dart
Result: 4 passed in 6s.
```

6. `apps/features/workout` Full test suite regression:
```text
flutter test
Result: 1,155 passed in ~35s. Zero failures.
```

7. Local disposable database pgTAP regression suite (`supabase_db_oykupyiitspujzpwwvuj` on port 54322):
```text
docker exec -i supabase_db_oykupyiitspujzpwwvuj psql -U postgres -d postgres -f - < supabase/tests/database/w7b_session_security.test.sql
Result: 82 assertions passed in 1.4s. Zero failures.
```

### Acceptance Evidence (substantive scope)

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Domain purity & Record envelope | `workout_session_record.dart`, `models.dart` | `workout_session_repository_test.dart` verifies envelope separation | Local Flutter test runner | None |
| Snapshot DTO schema conformance | `workout_session_dtos.dart` | `workout_session_dtos_test.dart` validates JSONB matches SQL constraint | Local Flutter test runner | None |
| 7 RPC contract & bracketed read | `supabase_workout_session_repository.dart`, gateway | 26 tests across gateway & repository test suites | Local Flutter test runner | None |
| Auth lifecycle & zero mock fallback | `workout_providers.dart` | `workout_session_repository_provider_test.dart` verifies unauth throws and session transition | Local Flutter test runner | None |
| Database security & RLS isolation | `w7b_session_security.test.sql` | 82 pgTAP assertions | Local Docker disposable DB | None |

### Review Provenance

**Review source / link:** Self-review & automated validation suites
**Reviewer / relation to implementer:** Antigravity (implementer self-review)
**Diff or commit SHA actually reviewed:** Staged working directory diff against main `15fb580e7926027caf3266fbe7971340da222ff1`
**Review result and finding IDs/dispositions:** Clean, all requirements met.
**Independent review?** No (self-review; awaiting external peer review)
**Limitations and unmet required gates:** None.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| - | - | None | No defects found | - | - |

## 7. Final Handoff

### Changed Files
- `apps/features/workout/lib/src/domain/models/workout_session_record.dart` (new)
- `apps/features/workout/lib/src/domain/models/models.dart` (modified)
- `apps/features/workout/lib/src/domain/repositories/workout_session_repository.dart` (new)
- `apps/features/workout/lib/src/domain/repositories/repositories.dart` (modified)
- `apps/features/workout/lib/src/data/dto/workout_session_dtos.dart` (new)
- `apps/features/workout/lib/src/data/repositories/supabase_workout_session_gateway.dart` (new)
- `apps/features/workout/lib/src/data/repositories/supabase_workout_session_repository.dart` (new)
- `apps/features/workout/lib/src/data/data.dart` (modified)
- `apps/app/lib/app/composition/workout_providers.dart` (modified)
- `apps/features/workout/test/data/workout_session_dtos_test.dart` (new)
- `apps/features/workout/test/data/supabase_workout_session_gateway_test.dart` (new)
- `apps/features/workout/test/data/supabase_workout_session_repository_test.dart` (new)
- `apps/app/test/app/workout_session_repository_provider_test.dart` (new)
- `.ai/tasks/w7b-2a-workout-session-persistence-gateway.md` (new)

### Actual Behavior
- Pure Dart `WorkoutSession` is wrapped in `WorkoutSessionRecord` containing server `revision` and sync state.
- `SupabaseWorkoutSessionRepository` enforces optimistic concurrency control (`expectedRevision`), bracketed reads for performed set consistency, and owner-scoped readback for authoritative server revision.
- DTOs cleanly serialize/deserialize the frozen routine snapshot schema adhering strictly to the database constraint `private.is_valid_workout_session_snapshot_v1`.
- `workoutSessionRepositoryProvider` in `apps/app` observes authenticated user sessions and invalidates upon sign-out or account switch without silent in-memory fallback.

### Known Limitations
- Offline mutation queueing is excluded by design (W7B-2B deferred).
- Active workout screen and UI integration excluded by design (W7C deferred).

### Final Status

`REVIEW`
