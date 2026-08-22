# Product Onboarding O3B — `bodyGoal` Runtime Section + Legacy Resume

**Status:** Complete — validated  
**Tracker:** GitHub Issue #55  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting checkpoint

O3A typed Body Goal flow contract:

```text
4878ebc0045be9c3d6921aafffcf9f4791df0fd9
Flutter CI #1290 / run 32556313431
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Validated O3B checkpoint

```text
3df7dbd61a57340f7d6f767361d3ceaa49cc83fb
Flutter CI #1319 / run 32558694870
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the authoritative O3B source checkpoint. Later `.ai` evidence commits do not redefine the validated source SHA.

## Outcome

Activated `OnboardingStepId.bodyGoal` / `OnboardingSectionId.bodyGoal` in Product Onboarding runtime, reused the existing Goal/Current Weight/Target Weight screens, and made legacy `profileBasics` Body-child checkpoints resume safely without changing serialized answer fields or canonical Body persistence.

## Active order established

For every selected App Mode, the first two Product Onboarding top-level sections are:

```text
profileBasics → userProfile
bodyGoal      → bodyGoal
```

Then existing mode-specific Workout/Targets/Review ordering continues.

## Child ownership split

Active `userProfile` child plan:

```text
name
gender
age
measurementUnits
height
activity
healthConditions
```

Active `bodyGoal` child plan in O3B:

```text
goal
currentWeight
targetWeight?  ← GoalWeightFollowUpPolicy
```

Persisted answer fields remain compatibility containers; runtime section ownership is now separate.

## Legacy resume behavior validated

Old snapshots with:

```text
current_step_id = profileBasics
profile.currentStepId = goal | currentWeight | targetWeight
```

resume in top-level `bodyGoal` with Body answers preserved. Common Profile children stay in `userProfile`.

Later top-level checkpoints remain later. Dormant compatible Body values/cursors are preserved so a same-direction flow can restore them; the active `BodyGoalFlowPlan` owns whether Target Weight is traversable. An actually active invalid Target Weight checkpoint reconciles to the nearest valid Body child.

Durable resume preservation also understands Body Goal child ordering, including Back-navigation and pre-O3 `profileBasics` Body cursors.

## Acceptance

- [x] all active mode plans place `bodyGoal` immediately after `profileBasics`;
- [x] `profileBasics` remains `userProfile` and only traverses common Profile children;
- [x] `bodyGoal` traverses Goal → Current Weight → eligible Target Weight;
- [x] existing Goal/weight screens render under `bodyGoal` without redesign;
- [x] Back from first Body Goal child returns to final common Profile child;
- [x] completion of final common Profile child enters Body Goal at Goal;
- [x] completion of final Body Goal child enters the next mode-specific top-level section;
- [x] legacy `profileBasics + goal/currentWeight/targetWeight` resumes at `bodyGoal` preserving answers;
- [x] later legacy checkpoints preserve their later top-level location and Body answers;
- [x] active invalid/removed Target Weight reconciles safely while dormant compatible data remains recoverable;
- [x] continuous progress denominator remains equivalent, with Body Goal items typed separately;
- [x] Goal Pace stays in Targets for O3B and is delegated to O3C;
- [x] no persistence/schema/UI redesign introduced;
- [x] full Flutter analyze + Dart analyze + Flutter tests + Dart tests green on exact O3B checkpoint.

## Guardrails preserved

- no Body direction inference from numbers/BMI/training-only goals;
- no legacy-column drop or applied migration edit;
- no permanent dual-write synchronization;
- Current Weight remains canonical Body-owned;
- Body Goal/Target/Pace remain canonical `user_body_goals` owned;
- no O4 activation.

## Handoff

O3B is frozen at CI #1319. O3C is active on GitHub Issue #56 with focused task `.ai/tasks/product-onboarding-o3c-goal-pace-parity.md`.
