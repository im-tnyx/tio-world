# Product Onboarding O6A — Canonical Workout Owner Contracts

**Status:** Active  
**Tracker:** GitHub Issue #70  
**Parent O6:** #69  
**Predecessor O5E:** #68 ✅ / CI #1507  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting validated checkpoint

```text
b017f6c31c9c89a6df1ba6b670ea0ea04d635941
Flutter CI #1507 / run 32583620248
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Objective

Establish explicit Workout-owned domain/repository contracts for the already-live canonical tables without changing Product Onboarding runtime or completion composition yet:

```text
WorkoutProfileRepository → public.user_workout_profiles
WorkoutTargetsRepository → public.user_workout_targets
```

## Workout Profile contract

Add `WorkoutProfileData` for Workout-specific context/capability:

```text
workoutLocation
availableEquipment
experienceLevel
focusAreas
healthConcerns
```

Use stable storage strings already proven by current Workout enums/schema. Collections must parse strictly; malformed stored values fail closed rather than being silently dropped.

## Workout Targets contract

Add `WorkoutTargetsData` for:

```text
primaryWorkoutGoal
primaryGoalRank
supportingWorkoutGoal
supportingGoalRank
trainingDays
preferredDurationMins
splitProgram
specialEvent
specialEventDate
```

Canonical Workout goal storage values:

```text
build_muscle
get_stronger
improve_endurance
stay_fit
```

Ranks are nullable but when present must be 1 or 2, require their goal, and distinct known goals/ranks must remain consistent with live constraints. Duration must be positive when present. `specialEventDate` remains nullable.

O6A does not yet map unified onboarding `GoalIntentSelection`; that belongs to O6C. The canonical model must be ready to preserve original rank semantics later.

## Repository requirements

### In-memory

- deterministic `read` / `upsert`;
- preserve nullable/empty semantics;
- validate Workout Targets before storing.

### Supabase

- signed-out `read` returns null;
- signed-out `upsert` throws before table access;
- no `signInAnonymously` or other auth mutation;
- Profile adapter touches only canonical Workout Profile columns;
- Targets adapter touches only canonical Workout Targets columns;
- strict enum/collection/rank/numeric/date parsing;
- malformed rows throw instead of fabricating values;
- no fallback write to legacy `user_workout_preferences` from canonical adapters.

## Compatibility boundary

Existing `WorkoutPreferencesRepository`, `WorkoutPreferencesData`, `SupabaseWorkoutPreferencesRepository`, and current Product Onboarding completion wiring remain unchanged in O6A. Their later cutover is O6D.

## Implementation slices

1. Add canonical Workout Profile model/repository.
2. Add canonical Workout Targets goal model/storage mapping + target model/repository.
3. Add in-memory canonical repositories.
4. Add signed-in fail-closed Supabase canonical Profile adapter.
5. Add signed-in fail-closed Supabase canonical Targets adapter.
6. Export contracts/adapters from Workout package barrels.
7. Add model/in-memory/Supabase contract tests.
8. Run full four-gate CI on one exact source SHA.

## Guardrails

- no onboarding UI/navigation/runtime step change;
- no completion persistence cutover yet;
- no schema/migration change or applied migration edit;
- no broad compatibility repository deletion;
- no dual write;
- no anonymous auth mutation;
- no fabricated goal/event date/default;
- no Profile/Body/Wellness mirrors;
- O6B stays blocked until #70 exact full CI green;
- O11 remains blocked until O10.

## Acceptance

- [ ] canonical Workout Profile model/repository exists;
- [ ] canonical Workout Targets model/repository exists;
- [ ] Workout target goal storage mapping is strict/lossless;
- [ ] in-memory repositories preserve canonical data;
- [ ] Supabase Profile adapter is strict and Profile-only;
- [ ] Supabase Targets adapter is strict and Targets-only;
- [ ] signed-out canonical adapters fail closed without auth mutation;
- [ ] malformed canonical rows fail closed;
- [ ] broad `WorkoutPreferencesRepository` remains unchanged compatibility behavior;
- [ ] no runtime/UI/schema change;
- [ ] four CI gates green on one exact source SHA.

## Exit

Freeze exact O6A source SHA + CI evidence, close #70 completed, update #69/#40/#44/#50 and durable trackers, then activate O6B `workoutProfile` runtime/draft/resume ownership.