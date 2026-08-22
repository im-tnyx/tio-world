# Product Onboarding O3C — Goal Pace Placement + Body/Profile Parity

**Status:** In progress  
**Tracker:** GitHub Issue #56  
**Parent O3 tracker:** #55  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting checkpoint

O3B `bodyGoal` runtime section + legacy resume is validated:

```text
3df7dbd61a57340f7d6f767361d3ceaa49cc83fb
Flutter CI #1319 / run 32558694870
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Outcome

Move Goal Pace from active Targets navigation into the canonical Body Goal runtime boundary while preserving the existing Goal Pace screen, draft serialization compatibility, canonical Body persistence, and direction-safe follow-up policy.

Canonical durable ownership remains:

```text
body_weight_logs → Current Weight/history
user_body_goals  → Body Goal + Target Weight + Goal Pace
user_profiles    → common Profile only
```

O3C changes runtime placement/semantic ownership only. It does not introduce a new durable owner.

## Existing compatibility contract

Current serialized draft state stores pace as:

```text
TargetsOnboardingDraft.goalPaceKgPerWeek
TargetStepId.goalPace
```

Current Goal/weight child cursor compatibility uses:

```text
ProfileOnboardingDraft.currentStepId
  goal
  currentWeight
  targetWeight
```

O3C must keep old snapshots readable. Do not require a destructive DTO/schema rewrite merely to move Goal Pace on screen.

## Target runtime flow

When `GoalWeightFollowUpPolicy` enables weight follow-ups:

```text
Body Goal
  Goal
  → Current Weight
  → Target Weight
  → Goal Pace
```

When weight follow-ups are not eligible:

```text
Body Goal
  Goal
  → Current Weight
```

Target Weight and Goal Pace must share the same explicit goal-direction eligibility. No numeric/BMI inference.

Active Targets navigation after cutover:

```text
Bridge
→ Step Target
→ Sleep Target
→ Water Target
→ Nutrition Target
```

Goal Pace must no longer be an active Targets child after O3C.

## Compatibility cursor strategy

Prefer a typed Body Goal runtime identity that can represent all four Body children without changing persisted answer fields.

Migration adapters may read the existing compatibility cursors:
- Goal/Current Weight/Target Weight from `ProfileOnboardingDraft.currentStepId`;
- Goal Pace from legacy/current `TargetStepId.goalPace` when the top-level checkpoint semantics require migration.

Do not duplicate pace values across draft owners. `TargetsOnboardingDraft.goalPaceKgPerWeek` may remain the compatibility value container during O3C while runtime semantic ownership moves to Body Goal.

## Scope

- introduce/extend the typed Body Goal runtime child contract so Goal Pace is representable;
- keep Target Weight + Goal Pace eligibility driven by the same `GoalWeightFollowUpPolicy`;
- reuse `GoalPaceScreen` under `BodyGoalSection` without visual redesign;
- move Goal Pace next/back and validation behavior into Body Goal;
- remove Goal Pace from active `TargetsFlowPlan` traversal;
- keep `TargetsOnboardingDraft.goalPaceKgPerWeek` serialization/value compatibility unless a narrower safe adapter is necessary;
- reconcile `targets + goalPace` checkpoints into Body Goal Goal Pace when that cursor is the actual resume location;
- keep later top-level checkpoints later when pace is only dormant stored data;
- preserve existing pace data across eligible → ineligible → same-direction transitions;
- preserve canonical `BodySetupMapper`/Body repository single-owner persistence;
- adjust progress identity/order without changing equivalent eligible-flow denominator;
- update Review/mapper semantics only where required by ownership parity;
- add focused domain/controller/renderer/progress/resume tests;
- run full Flutter/Dart CI on the exact O3C source checkpoint.

## Acceptance

- [ ] typed Body Goal runtime child contract represents Goal Pace;
- [ ] eligible Body Goal order is Goal → Current Weight → Target Weight → Goal Pace;
- [ ] ineligible Body Goal order is Goal → Current Weight;
- [ ] Target Weight and Goal Pace use exact shared eligibility semantics;
- [ ] existing `GoalPaceScreen` renders under `BodyGoalSection` without redesign;
- [ ] Goal Pace validation is owned by Body Goal navigation and remains direction-safe;
- [ ] active `TargetsFlowPlan` no longer traverses Goal Pace;
- [ ] Targets Back/Next skip directly across the removed Goal Pace slot;
- [ ] legacy/current `targets + goalPace` resume migrates without pace-value loss;
- [ ] later checkpoints preserve later location and dormant pace value;
- [ ] eligible/ineligible/same-direction changes preserve compatible dormant pace data;
- [ ] opposite direction never silently reinterprets incompatible Body intent;
- [ ] continuous progress order and denominator remain correct;
- [ ] canonical Body writes remain single-owner with no permanent dual-write;
- [ ] no applied migration, legacy-column drop, or UI redesign;
- [ ] Flutter analyze + Dart analyze + Flutter tests + Dart tests all green on one exact O3C checkpoint.

## Guardrails

- no Body direction inference from measurements, BMI, target numbers, or training-only goals;
- no fabricated semantic defaults;
- no Profile owner expansion into Body concepts;
- no permanent dual-write synchronization;
- no applied migration edits;
- no legacy-column drops; O11/#54 stays blocked until O10;
- no O3D source work until O3C exact full CI is green;
- no O4 activation until O3D integrated acceptance.

## Validation

Focused validation should cover at minimum:

```text
BodyGoalFlowPlan / builder eligibility + order
controller Body Goal next/back + validation
BodyGoalSection GoalPaceScreen reuse
Targets plan/navigation without Goal Pace
progress ordering/denominator parity
legacy targets+goalPace resume migration
later-checkpoint dormant pace preservation
Body mapper/persistence single-owner regression
```

Then require full workspace CI.

## Exit criteria

O3C is complete only when the exact source SHA has:

```text
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

and #56/#55/#40/#44/PR #50 plus `.ai` handoff files record that exact checkpoint.

## Current work

**Audit the safest typed Body Goal child identity, then relocate Goal Pace runtime navigation/rendering from Targets to Body Goal without changing durable ownership or serialized pace value.**
