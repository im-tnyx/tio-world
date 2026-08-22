# Product Onboarding O6 — Canonical Workout Profile + Targets

**Status:** Active — O6A/O6B validated; O6C ACTIVE  
**Tracker:** GitHub Issue #69  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Predecessor O5:** #63 ✅ / CI #1507  
**O6A:** #70 ✅ / CI #1509  
**O6B:** #71 ✅ / CI #1511  
**Active slice:** O6C #72  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Latest validated source checkpoint

```text
48f0d1ff562fee7dda5647476ff706d1886dde11
Flutter CI #1511 / run 32585811984
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O6B source/runtime checkpoint. Later tracker-only commits do not replace it.

## Canonical durable owners

```text
user_workout_profiles → workout context/capability
user_workout_targets  → workout goals/schedule/plan constraints
```

O6A established explicit canonical contracts/adapters. O6B activated canonical top-level `workoutProfile` while preserving historical `workoutPreferences` read compatibility and the existing child flow.

## Execution order

```text
O6A canonical Workout Profile + Targets contracts          ✅ #70 / CI #1509
O6B workoutProfile runtime + legacy top-level resume       ✅ #71 / CI #1511
→ O6C workoutTargets runtime + ordered goals + schema v4   ACTIVE #72
O6D canonical persistence cutover + broad writer shutdown
O6E integrated acceptance
```

Only one O6 sub-slice is active at a time.

## O6C active split

```text
workoutProfile
  gymAccess
  equipment (home only)
  experienceLevel
  focusAreas
  healthConcerns

workoutTargets
  trainingDays
  workoutDuration
  workoutSplit
  specialEvent
```

`healthConcerns` moves next to Profile-owned context; the screen itself is unchanged.

Mode ownership:

```text
Workout          → Profile + Targets
Nutrition        → neither
Hybrid setupNow  → Profile + Targets
Hybrid later     → neither; preserve stored Workout data
```

Unified Goal selection remains the only source of ordered Workout training goals. Only Build Muscle/Get Stronger/Improve Endurance/Stay Fit map to `user_workout_targets`; original rank 1/2 is preserved and Body-direction intents are omitted.

O6C advances draft schema to v4 so O6B broad `workoutProfile` drafts can migrate safely to the split without incorrectly completing new partial Targets state.

## Guardrails

- no visual redesign or field/value change;
- only owner-driven `healthConcerns` screen regrouping;
- no canonical completion persistence cutover until O6D;
- no applied migration edits or legacy-column drops;
- no permanent dual write;
- no fabricated Workout goals/dates/defaults;
- Hybrid `Later` preserves stored data;
- O7 waits for O6E green;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Current work

**Execute O6C #72 only from `.ai/tasks/product-onboarding-o6c-workout-targets-runtime.md`.**