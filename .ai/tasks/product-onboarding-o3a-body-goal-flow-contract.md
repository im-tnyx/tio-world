# Product Onboarding O3A — Body Goal Flow Contract

**Status:** In progress  
**Tracker:** GitHub Issue #55  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting checkpoint

O2 common User Profile is complete:

```text
7e7119aa4dfe9cb53b1078376aa93e950f987adb
Flutter CI #1279 / run 32555540391
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Outcome

Define a typed, mode-aware Body Goal child-flow contract over the existing onboarding answer fields before changing runtime navigation.

O3A is contract-first. It must not yet activate `OnboardingStepId.bodyGoal` in the production top-level flow; that runtime cutover belongs to O3B after this contract is validated.

## Existing compatibility state

Current serialized onboarding drafts already carry the required answers without a schema migration:

```text
OnboardingDraft.goalSelection                 → unified goal intent
ProfileOnboardingDraft.currentWeightKg        → Current Weight answer
ProfileOnboardingDraft.targetWeightKg         → Target Weight answer
ProfileOnboardingDraft.targetWeightDirection  → direction provenance
TargetsOnboardingDraft.goalPaceKgPerWeek      → Goal Pace answer
```

Canonical persistence already maps them separately:

```text
Current Weight             → body_weight_logs
Body Goal/Target/Pace      → user_body_goals
```

O3A therefore adds navigation semantics, not a new durable owner.

## Body Goal child-flow contract

Use existing `ProfileStepId` screen identities for compatibility during O3:

```text
goal
currentWeight
[targetWeight when direction requires it]
```

Goal Pace remains in the existing Targets child flow during O3A. O3C owns its final Body Goal placement so O3A does not mix two runtime migrations.

Target Weight inclusion must continue to use `GoalWeightFollowUpPolicy` and remain mode/goal-selection aware. Never infer Body direction from current/target numbers or BMI.

## Scope

- add typed `BodyGoalFlowPlan`;
- add `BuildBodyGoalFlowPlanUseCase`;
- reuse existing `GoalWeightFollowUpPolicy` for conditional Target Weight;
- export the new contract through onboarding domain barrels;
- add focused unit tests for ordering, conditional target weight and reconciliation;
- no renderer/controller/top-level flow activation yet;
- no persistence/schema changes;
- no UI changes;
- no O4 activation.

## Acceptance

- [ ] Body Goal flow has stable child order `goal → currentWeight → targetWeight?`;
- [ ] Target Weight appears only when existing follow-up policy requires it;
- [ ] training-only/non-directional selections do not fabricate Target Weight requirement;
- [ ] reconcile keeps a still-eligible child;
- [ ] reconcile clamps an ineligible `targetWeight` to nearest previous Body Goal child;
- [ ] existing runtime Product Onboarding behavior remains unchanged in O3A;
- [ ] no draft/schema/persistence-owner changes;
- [ ] focused tests added;
- [ ] full Flutter analyze + Dart analyze + Flutter tests + Dart tests green on exact O3A checkpoint.

## Guardrails

- preserve existing Goal/weight screen UI and picker contracts;
- preserve existing draft field serialization;
- Current Weight remains Body-owned;
- no Goal inference from numbers/BMI;
- no legacy-column cleanup;
- O3B runtime activation starts only after O3A validation.

## Current work

**Implement and validate the typed Body Goal flow contract only.**
