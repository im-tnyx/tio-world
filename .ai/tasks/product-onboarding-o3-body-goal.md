# Product Onboarding O3 — Canonical Body Goal Section

**Status:** In progress — O3C Goal Pace placement ACTIVE  
**Tracker:** GitHub Issue #55  
**Focused O3C:** GitHub Issue #56  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Predecessor:** #53 O2 common User Profile ✅  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Validated foundation

O2 final:

```text
7e7119aa4dfe9cb53b1078376aa93e950f987adb
Flutter CI #1279 / run 32555540391 ✅
```

O3A typed Body Goal child-flow contract:

```text
4878ebc0045be9c3d6921aafffcf9f4791df0fd9
Flutter CI #1290 / run 32556313431
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O3B runtime `bodyGoal` section + legacy resume:

```text
3df7dbd61a57340f7d6f767361d3ceaa49cc83fb
Flutter CI #1319 / run 32558694870
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Outcome

Give Body Goal its own Product Onboarding section while keeping one canonical Body owner, preserving user-facing Goal/weight behavior, and placing Goal Pace with its actual Body owner.

Canonical ownership:

```text
body_weight_logs  → Current Weight / history
user_body_goals   → Body Goal + Target Weight + Goal Pace
user_profiles     → common Profile only
```

No new durable owner is introduced by O3.

## Existing compatibility containers

During O3 the serialized draft remains readable through established fields:

```text
OnboardingDraft.goalSelection
ProfileOnboardingDraft.currentWeightKg
ProfileOnboardingDraft.targetWeightKg
ProfileOnboardingDraft.targetWeightDirection
TargetsOnboardingDraft.goalPaceKgPerWeek
```

These are migration-safe draft containers, not durable ownership declarations.

## Execution

```text
O3A typed Body Goal child-flow contract                         ✅ CI #1290
→ O3B activate bodyGoal top-level section + renderer/navigation ✅ CI #1319
→ O3C Goal Pace placement + Profile/Body separation parity      ACTIVE #56
→ O3D integrated canonical Body read/write/resume + full CI
```

Only one O3 sub-slice is active at a time.

## O3B established runtime boundary

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

Existing Goal/current/target screens are reused without redesign. Legacy `profileBasics + Body child` checkpoints migrate to `bodyGoal`; later checkpoints stay later and preserve dormant compatible Body values.

## O3C — ACTIVE

Tracker: #56  
Focused task: `.ai/tasks/product-onboarding-o3c-goal-pace-parity.md`.

Current mismatch:

```text
canonical durable owner: user_body_goals
runtime location:        Targets / TargetStepId.goalPace
value container:         TargetsOnboardingDraft.goalPaceKgPerWeek
```

Target runtime boundary for eligible explicit weight-direction flows:

```text
bodyGoal
  Goal
  → Current Weight
  → Target Weight
  → Goal Pace
```

For non-directional/ineligible flows:

```text
bodyGoal
  Goal
  → Current Weight
```

Target Weight and Goal Pace must use the same `GoalWeightFollowUpPolicy`. The existing `GoalPaceScreen` must be reused without redesign. Active Targets navigation must stop traversing Goal Pace, while serialized pace value compatibility remains safe.

## O3 acceptance

- [x] Body Goal child-flow contract validated;
- [x] active top-level Product Onboarding flow uses `OnboardingStepId.bodyGoal` / `OnboardingSectionId.bodyGoal`;
- [x] common `userProfile` section no longer semantically owns Goal/Current Weight/Target Weight;
- [x] existing Goal/current/target weight screens are reused without redesign;
- [x] legacy `profileBasics` serialized checkpoints reconcile without losing Body answers;
- [ ] Goal Pace renders/navigates under Body Goal with shared eligibility;
- [ ] active Targets flow no longer semantically owns Goal Pace;
- [ ] legacy/current `targets + goalPace` resume reconciles without pace loss;
- [ ] Current Weight persists only through canonical Body weight owner;
- [ ] Body Goal/Target Weight/Goal Pace persist only through canonical Body Goal owner;
- [ ] full integrated O3 acceptance + Flutter/Dart CI green;
- [ ] O4 remains blocked until O3D.

## Guardrails

- no legacy-column drops; #54/O11 remains blocked until O10;
- no applied migration edits;
- no permanent dual-write synchronization;
- no Profile owner expansion into Body concepts;
- no UI redesign;
- preserve existing picker/unit contracts;
- no Body direction inference from measurements/BMI/training-only goals;
- do not activate Wellness/Nutrition/Workout future sections during O3.

## Current work

**Execute O3C on #56 from the exact green O3B checkpoint. O3D and O4 remain blocked until their predecessors have exact full-CI evidence.**
