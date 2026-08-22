# Current State

Last verified from current branch/runtime trackers: 2026-08-22.

This is the concise handoff for the next agent. Runtime source remains behavior truth. For Product Onboarding sequencing, read `.ai/tasks/product-onboarding-canonical-execution.md` first.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o3-body-goal.md`
4. active focused task `.ai/tasks/product-onboarding-o3a-body-goal-flow-contract.md`
5. GitHub Issue #55 and Draft PR #50

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
```

O2 final checkpoint:

```text
7e7119aa4dfe9cb53b1078376aa93e950f987adb
Flutter CI #1279 / run 32555540391
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O2 sequence:

```text
O2A narrow UserProfile contract                 ✅ #1252
O2B Supabase user_profiles adapter              ✅ #1252
O2C onboarding canonical Profile write          ✅ #1268
O2D userProfile section + legacy resume         ✅ #1275
O2E integrated canonical Profile acceptance     ✅ #1279
```

Issue #53 is complete/closed. PR #50 remains Draft/open/unmerged.

## Current Product Onboarding sequence

```text
O1 App Mode                                     ✅
O2 User Profile                                 ✅
→ O3 Body Goal section + Profile/Body parity    ACTIVE #55
   O3A typed Body Goal child-flow contract      ACTIVE
   O3B bodyGoal runtime section activation      NEXT after O3A
   O3C Goal Pace placement/parity
   O3D integrated Body acceptance
→ O4 Wellness
→ O5 Nutrition
→ O6 Workout
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                  BLOCKED #54
```

Independent Account/Settings lanes remain parallel and do not change this sequencing.

## Active slice — O3A Body Goal flow contract

Tracker: GitHub Issue #55  
Parent task: `.ai/tasks/product-onboarding-o3-body-goal.md`  
Focused task: `.ai/tasks/product-onboarding-o3a-body-goal-flow-contract.md`

Audit baseline:
- prepared `OnboardingStepId.bodyGoal` and `OnboardingSectionId.bodyGoal` exist;
- current runtime still groups Goal/Current Weight/Target Weight inside legacy `ProfileFlowPlan`;
- Goal Pace currently lives in Targets draft/navigation;
- `BodySetupMapper` already persists Current Weight separately from Body Goal/Target/Pace through canonical Body owners and never infers Body intent from numbers/BMI.

O3A implementation is contract-first and intentionally does **not** activate the production top-level `bodyGoal` step yet:

```text
BodyGoalFlowPlan
  goal
  currentWeight
  targetWeight?  ← existing GoalWeightFollowUpPolicy
```

Added source:
- `apps/features/onboarding/lib/src/domain/models/body_goal_flow_plan.dart`;
- `apps/features/onboarding/lib/src/domain/usecases/build_body_goal_flow_plan_use_case.dart`;
- focused `build_body_goal_flow_plan_use_case_test.dart`;
- model/use-case barrel exports.

Runtime navigation, renderer, persistence and serialized draft format are unchanged in O3A. O3B starts only after exact O3A full CI is green.

## Guardrails

- preserve existing Goal/weight/Profile UI and picker contracts;
- Current Weight remains `body_weight_logs` owned;
- Body Goal/Target/Pace remain `user_body_goals` owned;
- no Body direction inference from numbers/BMI/training-only goals;
- no draft/schema migration in O3A;
- no legacy-column drop;
- no permanent dual-write synchronization;
- no O4 activation before O3D.
