# Product Onboarding O6 — Canonical Workout Profile + Targets

**Status:** Active  
**Tracker:** GitHub Issue #69  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Predecessor O5:** #63 ✅ / CI #1507  
**Active slice:** O6A #70  
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

## Source/schema audit

Current `WorkoutPreferencesRepository` and `WorkoutPreferencesData` mix context/capability and schedule/plan targets. The live schema already exposes separate durable owners:

```text
public.user_workout_profiles
public.user_workout_targets
```

Current broad Supabase writer also attempts anonymous auth and contains a fallback to legacy `user_workout_preferences`; canonical O6 owner adapters must be signed-in fail-closed and must not mutate auth.

## Canonical owner split

### Workout Profile

```text
workout_location
available_equipment
experience_level
focus_areas
health_concerns
```

Profile means Workout-specific context/capability/preference only. No common Profile, Body or Wellness mirrors.

### Workout Targets

```text
primary_workout_goal
primary_goal_rank
supporting_workout_goal
supporting_goal_rank
training_days
preferred_duration_mins
split_program
special_event
special_event_date
```

Training goal values only:

```text
build_muscle
get_stronger
improve_endurance
stay_fit
```

Source is the ordered unified Goal selection. Preserve original rank 1/2 when a training intent appears. Body-direction intents remain Body-owned. `special_event_date` remains unknown until a real source exists.

## Mode / branch ownership

```text
Workout
  Workout Profile  ✅
  Workout Targets  ✅

Nutrition
  Workout Profile  ❌
  Workout Targets  ❌

Hybrid setupNow
  Workout Profile  ✅
  Workout Targets  ✅

Hybrid later
  Workout Profile  ❌
  Workout Targets  ❌
  preserve stored Workout data
```

Hybrid `Later` is not a delete/reset instruction.

## Execution order

```text
→ O6A canonical Workout Profile + Targets contracts           ACTIVE #70
→ O6B workoutProfile runtime/draft/navigation/resume
→ O6C workoutTargets runtime + ordered goal mapping + legacy resume
→ O6D canonical persistence cutover + broad writer shutdown
→ O6E integrated read/write/resume/failure acceptance
```

Only one O6 sub-slice is active at a time.

## Guardrails

- no UI redesign implied by owner split;
- no applied migration edits;
- no legacy-column drops;
- no permanent dual write;
- no fabricated Workout goals/event dates/defaults;
- no Body goals in Workout owner rows;
- preserve Hybrid `Later` stored data;
- O7 waits for O6E exact full CI green;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Current work

**Execute O6A #70 only from `.ai/tasks/product-onboarding-o6a-canonical-workout-contracts.md`.**