# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1–O5 complete; O6 Workout ACTIVE  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O5 Nutrition:** #63 ✅ / CI #1507  
**O6 Workout:** #69 ACTIVE  
**O6A:** #70 ✅ / CI #1509  
**O6B:** #71 ✅ / CI #1511  
**O6C:** #72 ACTIVE  
**Account verification:** #8 parallel lane  
**O11 cleanup:** #54 BLOCKED until O10  
**PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Latest exact validated source checkpoint

```text
48f0d1ff562fee7dda5647476ff706d1886dde11
Flutter CI #1511 / run 32585811984
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O6B source/runtime checkpoint. Later docs/tracker commits do not replace it unless changed runtime source receives full CI.

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
→ O6 Workout Profile + Targets                   ACTIVE #69
   O6A canonical Workout owner contracts         ✅ #70 / CI #1509
   O6B workoutProfile runtime + legacy resume    ✅ #71 / CI #1511
   → O6C workoutTargets runtime + ordered goals  ACTIVE #72
   O6D canonical persistence cutover
   O6E integrated acceptance
→ O7 Health Connections
→ O8 Review + edit-back + resume
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                   BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## Validated through O6B

```text
Workout:
userProfile → bodyGoal → wellnessGoals → workoutProfile → nutritionGoals → review

Nutrition:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → nutritionGoals → review

Hybrid setupNow:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → workoutIntro
→ workoutProfile → nutritionGoals → review

Hybrid later:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → workoutIntro
→ nutritionGoals → review
```

Historical `workoutPreferences` durable identity is decode-only and normalizes to canonical `workoutProfile`; new writes use `workoutProfile`.

## O6C — ACTIVE #72

Focused task: `.ai/tasks/product-onboarding-o6c-workout-targets-runtime.md`.

Canonical runtime split:

```text
workoutProfile
  gymAccess
  equipment (home only)
  experienceLevel
  focusAreas
  healthConcerns
→ workoutTargets
  trainingDays
  workoutDuration
  workoutSplit
  specialEvent
```

This moves the existing optional Health Concerns screen next to Profile-owned context without changing the screen itself.

O6C advances onboarding draft schema to v4 to distinguish O6B broad Workout snapshots from new split partial completion. v2/v3 broad current/completed Workout state migrates forward; new v4 Profile completion never implicitly completes Targets.

Unified Goal selection maps to Workout Targets only for Build Muscle/Get Stronger/Improve Endurance/Stay Fit, preserving original rank 1/2. Body-direction goals remain Body-owned. `specialEventDate` remains null until a real source exists.

The broad `WorkoutPreferencesRepository` remains completion compatibility in O6C. Canonical completion repository cutover happens only in O6D.

## Guardrails

- no visual redesign/copy/field/value changes;
- only owner-driven Health Concerns regrouping;
- no fabricated semantic defaults, Workout goals or event dates;
- no canonical Workout persistence cutover until O6D;
- no applied migration edits or legacy-column drops;
- no permanent dual write;
- Hybrid `Later` preserves stored Workout data;
- O6D waits for #72 exact full CI green;
- O11/#54 stays blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Handoff

**Execute O6C #72 only. Frozen predecessor checkpoint: `48f0d1ff562fee7dda5647476ff706d1886dde11` / Flutter CI #1511.**