# Product Onboarding O3A — Body Goal Flow Contract

**Status:** Validated  
**Tracker:** GitHub Issue #55  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Final checkpoint

```text
4878ebc0045be9c3d6921aafffcf9f4791df0fd9
Flutter CI #1290 / run 32556313431
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Validated predecessor O2:

```text
7e7119aa4dfe9cb53b1078376aa93e950f987adb
Flutter CI #1279 / run 32555540391 ✅
```

## Outcome

A typed, mode-aware Body Goal child-flow contract now exists over the existing onboarding answer fields without changing production runtime navigation, serialized drafts, persistence, schema or UI.

## Existing compatibility state preserved

```text
OnboardingDraft.goalSelection                 → unified goal intent
ProfileOnboardingDraft.currentWeightKg        → Current Weight answer
ProfileOnboardingDraft.targetWeightKg         → Target Weight answer
ProfileOnboardingDraft.targetWeightDirection  → direction provenance
TargetsOnboardingDraft.goalPaceKgPerWeek      → Goal Pace answer
```

Canonical persistence remains:

```text
Current Weight             → body_weight_logs
Body Goal/Target/Pace      → user_body_goals
```

## Validated Body Goal child-flow contract

```text
BodyGoalFlowPlan
  goal
  currentWeight
  targetWeight?  ← GoalWeightFollowUpPolicy
```

Existing `ProfileStepId` identities are deliberately reused for draft/resume compatibility during O3.

Goal Pace remains in the existing Targets child flow until O3C.

## Implementation

Added:
- `apps/features/onboarding/lib/src/domain/models/body_goal_flow_plan.dart`;
- `apps/features/onboarding/lib/src/domain/usecases/build_body_goal_flow_plan_use_case.dart`;
- domain model/use-case barrel exports;
- `apps/features/onboarding/test/domain/build_body_goal_flow_plan_use_case_test.dart`.

## Acceptance

- [x] Body Goal flow has stable child order `goal → currentWeight → targetWeight?`;
- [x] Target Weight appears only when existing follow-up policy requires it;
- [x] training-only/non-directional selections do not fabricate Target Weight requirement;
- [x] reconcile keeps a still-eligible child;
- [x] reconcile clamps an ineligible `targetWeight` to nearest previous Body Goal child;
- [x] existing runtime Product Onboarding behavior remains unchanged in O3A;
- [x] no draft/schema/persistence-owner changes;
- [x] focused tests added;
- [x] full Flutter analyze + Dart analyze + Flutter tests + Dart tests green on exact O3A checkpoint.

## Exit

**O3A is complete. O3B may now activate the top-level `bodyGoal` runtime section and prove legacy `profileBasics` resume compatibility.**
