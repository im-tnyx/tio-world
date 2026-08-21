# Canonical Body Owner Repository Cutover

**Status:** In progress  
**Primary owner:** `apps/features/progress` + onboarding composition  
**Affected platforms:** Flutter phone app / Supabase persistence

## 1. Discovery

### User Outcome

Make the live canonical Body tables the authoritative persistence path without changing UI or inventing goal semantics.

### Success Criteria

- `body_weight_logs` owns persisted current weight.
- `user_body_goals` owns explicit Body Goal, Target Weight, Goal Pace and lifecycle.
- onboarding completion writes Body data through a Progress-owned Body repository.
- Maintain/Recomposition never persist Target Weight or Goal Pace in the canonical Body owner.
- no BMI/delta inference and no `Build muscle = Gain weight` mapping.
- Profile/Settings eventually read and mutate the same canonical Body owner.
- mirrored legacy Body writes are stopped only after canonical read/write parity is proven; no permanent dual-write synchronization.

### Scope

Current repository cutover sequence:

**Body Cutover A — validated canonical write foundation**
- Progress-owned Body domain/repository contract;
- Supabase implementation over `body_weight_logs` + `user_body_goals`;
- app provider and onboarding completion wiring;
- explicit Goal-to-Body mapping;
- focused mapper/repository/completion tests.

**Body Cutover B — next**
- canonical Body read API for current weight + active Body Goal;
- Profile/Profile Settings consume latest canonical Body state;
- Profile Settings current-weight mutation writes canonical Body owner;
- then remove onboarding/Profile/Nutrition Body mirror writes after parity proof.

### Non-Goals

- UI changes;
- Wellness/Nutrition/Workout target repository split;
- legacy column drops;
- recommendation formula changes;
- measurement picker work;
- protected backend implementation.

## 2. Codebase Exploration

### Verified Evidence

Schema/live contract:
- live migrations `20260821161923_create_canonical_owner_tables` and `20260821162207_backfill_canonical_owner_data` are applied.
- `body_weight_logs` is the canonical current-weight/history table.
- `user_body_goals` is the canonical Body Goal/Target Weight/Goal Pace lifecycle table.

Pre-cutover legacy paths still present:
- `SupabaseProfileSetupRepository` still contains `current_weight_kg`, `target_weight_kg`, `goals`, `primary_goal` compatibility writes to `users`.
- `SupabaseTargetsSetupRepository` still contains Body mirrors in `user_nutrition_profiles`.
- `ProfileSettingsWriteMapper` still writes `current_weight_kg` to `users`.

Implemented Body Cutover A:
- `apps/features/progress/lib/src/domain/body_setup.dart` defines `BodySetupRepository`, `BodySetupData`, `BodyGoalSetupData`, `BodyGoalType`.
- `SupabaseBodySetupRepository` persists onboarding current-weight state to `body_weight_logs` and reconciles active Body Goal lifecycle in `user_body_goals`.
- same-type active goal updates in place; changed Body goal supersedes the previous active row.
- training-only/no-Body selection can retire an active Body Goal rather than inventing a Body direction.
- Maintain/Recomposition follow-up Target Weight/Goal Pace are rejected before database writes.
- onboarding `BodySetupMapper` maps only explicit Body intents; training intents are not inferred as Body goals.
- Target Weight is consumed only when its stored direction matches the active explicit loss/gain direction.
- `PersistOnboardingOwnerDataUseCase` now requires and persists the Body owner.
- app composition injects `bodySetupRepositoryProvider` into onboarding completion.
- router diff was verified to contain only the intended Body provider read + repository injection for this cutover.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Body repository lives in Progress | Approved + implemented | Weight/progress is canonical owner and avoids Profile/Nutrition ownership | #44 contract |
| Onboarding uses canonical Body repository directly | Approved + implemented | Onboarding is orchestration, not owner | #40/#44 |
| Unified Goal is split explicitly into Body semantics | Approved + implemented | Prevent mixed `ProfileGoal` ownership and semantic inference | #40/#44 |
| Settings compatibility remains temporarily | Deferred to Cutover B | Removing legacy mutation/read paths before canonical read parity can produce stale/default UI state | next sub-slice |
| Permanent dual-write synchronization | Rejected | Legacy mirrors are temporary compatibility only and must be removed after parity proof | #44 contract |

## 4. Architecture Design

```text
Onboarding draft
  -> BodySetupMapper
  -> BodySetupRepository (Progress domain)
  -> SupabaseBodySetupRepository
  -> body_weight_logs + user_body_goals
```

Current transition state:

```text
Onboarding
  -> canonical Body write                 VALIDATED
  -> existing Profile/Nutrition mirrors   TEMPORARY compatibility

Profile / Settings
  -> legacy Body read/write               STILL PRESENT
  -> canonical Body read/write            NEXT
```

The transition must end with one authoritative Body read/write path; the temporary mirrors are not the final architecture.

## 5. Implementation Plan

### Body Cutover A — canonical write foundation

- [x] add Progress Body domain model/repository + Supabase implementation
- [x] export public Progress contract and add Supabase dependency
- [x] add onboarding dependency on Progress
- [x] add Body mapper from explicit `GoalIntentSelection` + Profile/Targets draft
- [x] persist Body owner in `PersistOnboardingOwnerDataUseCase`
- [x] wire app provider/completion coordinator
- [x] add Body mapper matrix tests
- [x] add Body repository contract/validation tests
- [x] migrate onboarding owner/completion tests to required Body repository dependency
- [x] validate full Flutter/Dart CI

### Body Cutover B — read/write parity + mirror removal

- [ ] add canonical Body read model/repository API for latest weight + active goal
- [ ] make Profile/Profile Settings display canonical current weight
- [ ] make Profile Settings current-weight save mutate canonical Body owner
- [ ] expose canonical active Target Weight/Body Goal wherever product UI needs it
- [ ] invalidate/refresh canonical Body providers after Settings mutation
- [ ] stop Profile onboarding persistence from writing Body Goal/Target Weight mirrors
- [ ] stop Nutrition onboarding persistence from writing current/target weight/Goal Pace mirrors
- [ ] stop Profile Settings from writing `users.current_weight_kg`
- [ ] prove stale-read/default regressions are absent
- [ ] run full Flutter/Dart CI again

## 6. Quality Review

### Validation Run

Validated source/test checkpoint:

```text
9031dc5e51a71b1bcef905bd93088f36396d3c01
Flutter CI #1135
run 32505095642

Analyze Flutter packages  ✅
Analyze Dart packages     ✅
Test Flutter packages     ✅
Test Dart packages        ✅
```

Earlier CI #1133 exposed only two stale onboarding test constructor calls missing the newly required `bodyRepository`; both were migrated without weakening the production dependency. CI #1135 then passed all four gates.

### Review Findings and Resolution

- Repository validation was moved before Body database mutations so an invalid Maintain/Recomposition follow-up cannot write current weight first and fail afterward.
- The canonical Body repository does not infer Body goals from BMI, target-current delta, or training-only intent.
- Full multi-owner transactional finalization is not claimed by this slice; this task only validates the Body owner boundary and onboarding integration.

## 7. Final Handoff

### Changed Ownership

Canonical Body persistence is now established under `apps/features/progress` and wired into Product Onboarding completion.

### Known Limitations

- Profile/Profile Settings still read current weight from legacy Profile state.
- Profile Settings still writes `users.current_weight_kg`.
- Profile/Nutrition compatibility repositories still contain mirrored Body fields.
- Therefore Body Cutover A is a validated write foundation, not the final single-owner cutover.

### Next Unblocked Work

**Body Cutover B — canonical read/write parity for Profile + Settings, then remove mirrored legacy Body writes.**

Do not change Target Weight recommendation constants or invent measurement-picker UI during this repository work.

### Final Status

`PARTIAL` — Body Cutover A validated by CI #1135; full cutover remains in progress until Cutover B removes legacy read/write ownership.
