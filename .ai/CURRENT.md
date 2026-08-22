# Current State

Last verified from current branch/runtime trackers: 2026-08-22.

This is the concise handoff for the next agent. Runtime source remains behavior truth. For Product Onboarding sequencing, read `.ai/tasks/product-onboarding-canonical-execution.md` first.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o3-body-goal.md`
4. active focused task `.ai/tasks/product-onboarding-o3c-goal-pace-parity.md`
5. GitHub Issues #56, #55 and Draft PR #50

## Canonical persistence owners

```text
users                      → account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + active_tabs
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep
user_nutrition_profiles    → diet/allergy/food context
user_nutrition_targets     → calories/macros/fiber + target state
user_workout_profiles      → workout context/capability
user_workout_targets       → workout goals/plan constraints
onboarding_drafts          → draft/resume orchestration only
```

Legacy mixed columns remain temporarily. Destructive cleanup is O11/#54 and stays blocked until O10 acceptance.

## Validated Product Onboarding foundation

```text
O1 durable App Mode / active_tabs               ✅ #11 / CI #1240
O2 common User Profile owner + userProfile      ✅ #53 / CI #1279
O3A Body Goal typed child-flow contract         ✅ #55 / CI #1290
O3B bodyGoal runtime section + legacy resume    ✅ #55 / CI #1319
```

O3B exact source checkpoint:

```text
3df7dbd61a57340f7d6f767361d3ceaa49cc83fb
Flutter CI #1319 / run 32558694870
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Later documentation commits do not redefine this validated O3B source checkpoint.

## Current Product Onboarding sequence

```text
O1 App Mode                                     ✅
O2 User Profile                                 ✅
→ O3 Body Goal section + Profile/Body parity    ACTIVE #55
   O3A typed Body Goal child-flow contract      ✅ #1290
   O3B bodyGoal runtime section + resume        ✅ #1319
   O3C Goal Pace placement/parity               ACTIVE #56
   O3D integrated Body acceptance               NEXT after O3C
→ O4 Wellness
→ O5 Nutrition
→ O6 Workout
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                  BLOCKED #54
```

Only one Product Onboarding sub-slice is active. Independent Account/Settings lanes remain parallel and do not change this sequencing.

## Established O3B runtime boundary

```text
userProfile
  name
  gender
  age
  measurementUnits
  height
  activity
  healthConditions

bodyGoal
  goal
  currentWeight
  targetWeight?  ← GoalWeightFollowUpPolicy
```

Existing Goal/current/target screens are reused. Pre-O3 `profileBasics + Body child` checkpoints migrate to `bodyGoal`; common Profile checkpoints remain `userProfile`; later checkpoints remain later and preserve compatible dormant Body values. Durable resume preservation is Body Goal-aware.

## Active slice — O3C Goal Pace placement/parity

Tracker: GitHub Issue #56  
Parent O3 tracker: #55  
Focused task: `.ai/tasks/product-onboarding-o3c-goal-pace-parity.md`

Current mismatch:

```text
canonical owner: user_body_goals
runtime child:   Targets / TargetStepId.goalPace
value container: TargetsOnboardingDraft.goalPaceKgPerWeek
```

Current active Targets order before O3C cutover:

```text
bridge → stepTarget → sleepTarget → waterTarget → goalPace? → nutritionTarget
```

Target O3C runtime boundary:

```text
eligible Body Goal:
Goal → Current Weight → Target Weight → Goal Pace

ineligible Body Goal:
Goal → Current Weight

Targets after cutover:
Bridge → Step Target → Sleep Target → Water Target → Nutrition Target
```

Target Weight and Goal Pace must share the exact `GoalWeightFollowUpPolicy`. Reuse the existing `GoalPaceScreen`; no visual redesign. Preserve `TargetsOnboardingDraft.goalPaceKgPerWeek` as a draft compatibility value unless a narrower safe adapter is required. Do not create duplicate durable writes.

Resume rules to preserve:
- an actual `targets + goalPace` resume cursor must migrate to canonical Body Goal Goal Pace without losing pace;
- a later top-level checkpoint stays later when pace is only dormant stored data;
- compatible dormant pace may survive ineligible transitions and restore on same-direction eligibility;
- active flow eligibility, not stored numbers, determines whether Goal Pace is traversed.

## Guardrails

- Current Weight remains `body_weight_logs` owned;
- Body Goal/Target/Pace remain `user_body_goals` owned;
- no Body direction inference from numbers/BMI/training-only goals;
- no Profile owner expansion into Body concepts;
- no fabricated semantic defaults;
- no applied migration edit;
- no legacy-column drop;
- no permanent dual-write synchronization;
- no UI redesign;
- no O3D until O3C exact full CI is green;
- no O4 activation before O3D.
