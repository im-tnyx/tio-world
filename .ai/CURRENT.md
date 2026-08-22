# Current State

Last verified from current branch/runtime trackers: 2026-08-22.

This is the concise handoff for the next agent. Runtime source remains behavior truth. For Product Onboarding sequencing, read `.ai/tasks/product-onboarding-canonical-execution.md` first.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o3-body-goal.md`
4. active focused task `.ai/tasks/product-onboarding-o3d-integrated-body-acceptance.md`
5. GitHub Issues #57, #55 and Draft PR #50

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
O3C Goal Pace placement/parity                  ✅ #56 / CI #1345
```

O3C exact source checkpoint:

```text
b47495e23f055c7d95eeccbca03b71c35aa38962
Flutter CI #1345 / run 32561257485
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Later documentation commits do not redefine this validated O3C source checkpoint.

## Current Product Onboarding sequence

```text
O1 App Mode                                     ✅
O2 User Profile                                 ✅
→ O3 Body Goal section + Profile/Body parity    ACTIVE #55
   O3A typed Body Goal child-flow contract      ✅ #1290
   O3B bodyGoal runtime section + resume        ✅ #1319
   O3C Goal Pace placement/parity               ✅ #56 / #1345
   O3D integrated Body acceptance               ACTIVE #57
→ O4 Wellness                                   BLOCKED by O3D
→ O5 Nutrition
→ O6 Workout
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                  BLOCKED #54
```

Only one Product Onboarding sub-slice is active. Independent Account/Settings lanes remain parallel and do not change this sequencing.

## Current O3 runtime boundary

```text
userProfile
  name
  gender
  age
  measurementUnits
  height
  activity
  healthConditions

eligible bodyGoal
  Goal
  → Current Weight
  → Target Weight
  → Goal Pace

ineligible bodyGoal
  Goal
  → Current Weight

Targets
  Bridge
  → Step Target
  → Sleep Target
  → Water Target
  → Nutrition Target
```

Existing Goal/current/target/pace screens are reused. Legacy `profileBasics + Body child` and `targets + goalPace` actual cursors migrate to canonical `bodyGoal` semantics; later checkpoints remain later when Body values are dormant.

## Active slice — O3D integrated canonical Body acceptance

Tracker: GitHub Issue #57  
Parent O3 tracker: #55  
Focused task: `.ai/tasks/product-onboarding-o3d-integrated-body-acceptance.md`

Acceptance path:

```text
OnboardingDraft
→ BodySetupMapper
→ BodySetupRepository / BodyRepository
→ canonical BodyState
```

O3D must prove:
- directional Current Weight/Body Goal/Target/Pace round-trip;
- explicit intent, never numbers/BMI, controls direction;
- Maintain/Recomposition discard dormant Target/Pace from canonical write;
- training-only goals do not fabricate Body Goal;
- repeated onboarding setup preserves one onboarding weight snapshot semantic;
- same goal retry preserves starting-weight/started-at semantics;
- changed goal type does not leave competing active state;
- Body persistence failure blocks confirmed App Mode/completed onboarding publication;
- O3C Goal Pace resume and pace-free Targets stay intact;
- one exact full Flutter/Dart CI checkpoint is green before O4.

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
- no O4 source work before O3D exact full CI green.
