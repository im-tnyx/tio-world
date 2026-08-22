# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1/O2/O3/O4/O5 complete; O6 Workout ACTIVE  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O5 Nutrition:** #63 ✅ / CI #1507  
**O6 Workout:** #69 ACTIVE  
**O6A:** #70 ACTIVE  
**Account verification:** #8 parallel lane  
**O11 cleanup:** #54 BLOCKED until O10  
**PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Latest exact validated source checkpoint

```text
b017f6c31c9c89a6df1ba6b670ea0ea04d635941
Flutter CI #1507 / run 32583620248
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O5E runtime/source checkpoint. Later docs/tracker commits do not replace it unless changed runtime source is rerun through full CI.

## Canonical owners

```text
users                      → stable account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + ordered active_tabs
user_devices               → device owner
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep/bed/wake targets
user_nutrition_profiles    → nutrition context only
user_nutrition_targets     → calories/macros/fiber + customization state
user_workout_profiles      → workout context/capability
user_workout_targets       → workout goals/schedule/plan constraints
onboarding_drafts          → draft/resume orchestration only
```

Applied migrations are immutable. Legacy duplicate/mixed columns remain until verified O11 cleanup.

## Execution order

```text
O1 App Mode durability                           ✅ #11 / CI #1240
O2 common User Profile owner + section           ✅ #53 / CI #1279
O3 Body Goal section + Body/Profile parity       ✅ #55 / CI #1354
O4 Wellness placement + canonical owner          ✅ #58 / CI #1441
O5 Nutrition Profile + Targets                   ✅ #63 / CI #1507
   O5A canonical owner contracts                 ✅ #64 / CI #1449
   O5B nutritionProfile runtime/draft/resume     ✅ #65 / CI #1460
   O5C nutritionGoals runtime + legacy Targets   ✅ #66 / CI #1481
   O5D canonical persistence cutover             ✅ #67 / CI #1505
   O5E integrated acceptance                     ✅ #68 / CI #1507
→ O6 Workout Profile + Targets                   ACTIVE #69
   → O6A canonical Workout owner contracts       ACTIVE #70
   O6B workoutProfile runtime/draft/resume
   O6C workoutTargets runtime + ordered goals/legacy resume
   O6D canonical persistence cutover
   O6E integrated acceptance
→ O7 Health Connections
→ O8 Review + edit-back + resume
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                   BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## Validated through O5

```text
Workout:
userProfile → bodyGoal → wellnessGoals → workoutPreferences → nutritionGoals → review

Nutrition:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → nutritionGoals → review

Hybrid:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → workoutIntro
→ optional workoutPreferences → nutritionGoals → review
```

O5E validates canonical Nutrition ownership across all active branches, exact allergy provenance, recommendation/customization state, legacy Nutrition resume, failure/retry ordering and idempotence on source `b017f6c3...` / CI #1507.

## O6 — ACTIVE #69

The current Workout runtime still uses one broad `workoutPreferences` section/repository. Source/schema audit shows it mixes two durable concepts:

```text
user_workout_profiles
  workout_location
  available_equipment
  experience_level
  focus_areas
  health_concerns

user_workout_targets
  primary_workout_goal + rank
  supporting_workout_goal + rank
  training_days
  preferred_duration_mins
  split_program
  special_event
  special_event_date
```

Unified Goal selection remains the source for ordered Workout goal intent. Only training intents map to Workout Targets; Body-direction intents remain Body-owned.

Mode/branch rule:

```text
Workout          → Workout Profile + Targets
Nutrition        → neither
Hybrid setupNow  → Workout Profile + Targets
Hybrid later     → neither; preserve stored Workout data
```

## O6A — ACTIVE #70

Focused task: `.ai/tasks/product-onboarding-o6a-canonical-workout-contracts.md`.

O6A adds explicit canonical domain/repository boundaries and adapters only. It must not change onboarding runtime identity, UI, completion composition or schema. The broad `WorkoutPreferencesRepository` remains compatibility-only until later O6 cutover.

## Guardrails

- no UI/navigation/runtime step change in O6A;
- no fabricated semantic defaults, Workout goals or event dates;
- no applied migration edits or legacy-column drops;
- no permanent dual write;
- Body goals remain Body-owned;
- Hybrid `Later` preserves stored Workout rows;
- O6B does not start until #70 exact full CI green;
- O11/#54 stays blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Handoff

**Execute O6A #70 only. Frozen predecessor checkpoint: `b017f6c31c9c89a6df1ba6b670ea0ea04d635941` / Flutter CI #1507.**