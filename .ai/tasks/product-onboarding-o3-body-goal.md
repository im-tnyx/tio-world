# Product Onboarding O3 — Canonical Body Goal Section

**Status:** In progress — O3A flow contract ACTIVE  
**Tracker:** GitHub Issue #55  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Predecessor:** #53 O2 common User Profile ✅  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting checkpoint

O2 final:

```text
7e7119aa4dfe9cb53b1078376aa93e950f987adb
Flutter CI #1279 / run 32555540391
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Outcome

Give Body Goal its own Product Onboarding section while keeping one canonical Body owner and preserving existing user-facing Goal/weight behavior.

Canonical ownership:

```text
body_weight_logs  → Current Weight / history
user_body_goals   → Body Goal + Target Weight + Goal Pace
user_profiles     → common Profile only
```

No new durable owner is introduced by O3.

## Existing compatibility container

Before O3, onboarding draft serialization stores Body-related answers in established fields:

```text
OnboardingDraft.goalSelection
ProfileOnboardingDraft.currentWeightKg
ProfileOnboardingDraft.targetWeightKg
ProfileOnboardingDraft.targetWeightDirection
TargetsOnboardingDraft.goalPaceKgPerWeek
```

These fields remain readable throughout O3. Runtime section migration must not require an unsafe draft/schema rewrite.

## Execution

```text
O3A typed Body Goal child-flow contract                         ACTIVE
→ O3B activate bodyGoal top-level section + renderer/navigation
→ O3C Goal Pace placement + Profile/Body separation parity
→ O3D integrated canonical Body read/write/resume + full CI
```

Only one O3 sub-slice is active at a time.

### O3A — ACTIVE

Focused task: `.ai/tasks/product-onboarding-o3a-body-goal-flow-contract.md`.

Contract-first scope:
- typed `BodyGoalFlowPlan`;
- mode-aware `BuildBodyGoalFlowPlanUseCase`;
- existing `ProfileStepId.goal/currentWeight/targetWeight` reused for draft compatibility;
- Target Weight inclusion remains governed by `GoalWeightFollowUpPolicy`;
- runtime top-level flow remains unchanged until O3A is validated.

## O3 acceptance

- [ ] Body Goal child-flow contract validated;
- [ ] active top-level Product Onboarding flow uses `OnboardingStepId.bodyGoal` / `OnboardingSectionId.bodyGoal`;
- [ ] common `userProfile` section no longer semantically owns Goal/Current Weight/Target Weight;
- [ ] existing Goal/current/target weight screens are reused without redesign;
- [ ] legacy `profileBasics` serialized checkpoints reconcile without losing Body answers;
- [ ] Current Weight persists only through canonical Body weight owner;
- [ ] Body Goal/Target Weight/Goal Pace persist only through canonical Body Goal owner;
- [ ] Goal Pace is placed with Body Goal without breaking wellness/nutrition target flow;
- [ ] no inferred Body direction from numbers/BMI/training-only goals;
- [ ] full integrated O3 acceptance + Flutter/Dart CI green;
- [ ] O4 remains blocked until O3D.

## Guardrails

- no legacy-column drops; #54/O11 remains blocked until O10;
- no applied migration edits;
- no permanent dual-write synchronization;
- no Profile owner expansion into Body concepts;
- no UI redesign;
- preserve existing picker/unit contracts;
- do not activate Wellness/Nutrition/Workout future sections during O3.

## Current work

**Validate O3A typed Body Goal flow contract. Then start O3B runtime section activation only from the exact green O3A checkpoint.**
