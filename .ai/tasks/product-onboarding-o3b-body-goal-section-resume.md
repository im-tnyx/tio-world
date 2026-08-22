# Product Onboarding O3B — `bodyGoal` Runtime Section + Legacy Resume

**Status:** In progress  
**Tracker:** GitHub Issue #55  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting checkpoint

O3A typed Body Goal flow contract is validated:

```text
4878ebc0045be9c3d6921aafffcf9f4791df0fd9
Flutter CI #1290 / run 32556313431
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Outcome

Activate `OnboardingStepId.bodyGoal` / `OnboardingSectionId.bodyGoal` in the Product Onboarding runtime, reuse the existing Goal/Current Weight/Target Weight screens, and migrate legacy `profileBasics` checkpoints without changing serialized answer fields or canonical Body persistence.

## Active order

For every selected App Mode, the first two Product Onboarding top-level sections become:

```text
profileBasics → userProfile
bodyGoal      → bodyGoal
```

Then existing mode-specific Workout/Targets/Review ordering continues unchanged.

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

Active `bodyGoal` child plan:

```text
goal
currentWeight
targetWeight?  ← GoalWeightFollowUpPolicy
```

Persisted answer fields stay where they are for migration safety; section ownership/navigation changes now, durable storage ownership was already canonical before O3.

## Legacy resume contract

Old snapshots may have:

```text
current_step_id = profileBasics
profile.currentStepId = goal | currentWeight | targetWeight
```

Those snapshots must resume at top-level `bodyGoal` with the same nested child and answers preserved.

Old `profileBasics` snapshots on common Profile children remain at `userProfile`.

Snapshots already on later top-level steps remain on their later step. Existing Body answers remain preserved; no destructive reset or schema/version bump.

If an old/invalid Target Weight child is no longer eligible under the current explicit goal direction, reconcile to the nearest valid Body Goal child rather than retaining a semantically invalid target.

## Scope

- split active common Profile child plan from legacy mixed Profile order;
- add `bodyGoal` to active top-level flow after `profileBasics`;
- add Body Goal progress identity;
- add Body Goal section renderer that reuses existing screens;
- update controller next/back/goal validation for Body Goal child navigation;
- migrate legacy `profileBasics + body child` snapshots to `bodyGoal`;
- preserve existing draft serialization and canonical Body repositories;
- add focused flow/controller/renderer/progress/resume tests;
- no Goal Pace relocation yet (O3C);
- no O4 activation.

## Acceptance

- [ ] all active mode plans place `bodyGoal` immediately after `profileBasics`;
- [ ] `profileBasics` remains `userProfile` and only traverses common Profile children;
- [ ] `bodyGoal` traverses Goal → Current Weight → eligible Target Weight;
- [ ] existing Goal/weight screens render under `bodyGoal` without redesign;
- [ ] Back from first Body Goal child returns to final common Profile child;
- [ ] completion of final common Profile child enters Body Goal at Goal;
- [ ] completion of final Body Goal child enters the next mode-specific top-level section;
- [ ] legacy `profileBasics + goal/currentWeight/targetWeight` resumes at `bodyGoal` preserving answers;
- [ ] later legacy checkpoints preserve their later top-level location and Body answers;
- [ ] invalid/removed Target Weight reconciles safely;
- [ ] continuous progress denominator remains the same for equivalent eligibility, with Body Goal items typed separately;
- [ ] Goal Pace stays in Targets until O3C;
- [ ] no persistence/schema/UI changes;
- [ ] full Flutter analyze + Dart analyze + Flutter tests + Dart tests green on exact O3B checkpoint.

## Guardrails

- no Body direction inference from numbers/BMI/training-only goals;
- no legacy-column drop or applied migration edit;
- no permanent dual-write synchronization;
- Current Weight remains canonical Body-owned;
- Body Goal/Target/Pace remain canonical `user_body_goals` owned;
- O3C starts only after O3B exact full CI is green;
- O4 stays blocked until O3D.

## Current work

**Implement the runtime section/navigation/resume split with focused tests, then validate the exact branch head.**
