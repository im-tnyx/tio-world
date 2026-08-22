# Product Onboarding O3C — Goal Pace Placement + Body/Profile Parity

**Status:** Validated  
**Tracker:** GitHub Issue #56 ✅ closed  
**Parent O3 tracker:** #55  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Successor:** #57 O3D ACTIVE  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Final checkpoint

```text
b47495e23f055c7d95eeccbca03b71c35aa38962
Flutter CI #1345 / run 32561257485
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Outcome

Goal Pace now belongs to the canonical Body Goal runtime boundary while preserving existing UI, draft serialization compatibility, canonical Body persistence, and direction-safe follow-up policy.

Canonical durable ownership remains:

```text
body_weight_logs → Current Weight/history
user_body_goals  → Body Goal + Target Weight + Goal Pace
user_profiles    → common Profile only
```

## Validated runtime flow

Eligible explicit weight direction:

```text
Body Goal
  Goal
  → Current Weight
  → Target Weight
  → Goal Pace
```

Ineligible/non-directional:

```text
Body Goal
  Goal
  → Current Weight
```

Active Targets is pace-free:

```text
Bridge
→ Step Target
→ Sleep Target
→ Water Target
→ Nutrition Target
```

## Compatibility behavior

Serialized pace value remains compatible through:

```text
TargetsOnboardingDraft.goalPaceKgPerWeek
```

Legacy/current `targets + goalPace` actual resume cursors normalize into canonical `bodyGoal + ProfileStepId.goalPace` without moving/duplicating the stored pace value. Later checkpoints remain later when pace is only dormant data.

## Validated acceptance

- [x] typed Body Goal runtime child contract represents Goal Pace;
- [x] eligible Body Goal order is Goal → Current Weight → Target Weight → Goal Pace;
- [x] ineligible Body Goal order is Goal → Current Weight;
- [x] Target Weight and Goal Pace use exact shared eligibility semantics;
- [x] existing `GoalPaceScreen` renders under `BodyGoalSection` without redesign;
- [x] Goal Pace validation is owned by Body Goal navigation and remains direction-safe;
- [x] active `TargetsFlowPlan` no longer traverses Goal Pace;
- [x] Targets Back/Next skip directly across the removed Goal Pace slot;
- [x] legacy/current `targets + goalPace` resume migrates without pace-value loss;
- [x] later checkpoints preserve later location and dormant pace value;
- [x] compatible dormant pace survives eligible → ineligible → same-direction transitions;
- [x] continuous progress slot ownership/order and denominator remain correct;
- [x] Goal Pace edits invalidate Body Goal completion, not Targets completion;
- [x] canonical Body writes remain single-owner with no permanent dual-write;
- [x] no applied migration, legacy-column drop, or UI redesign;
- [x] Flutter analyze + Dart analyze + Flutter tests + Dart tests all green on exact checkpoint.

## Guardrails retained

- no Body direction inference from measurements, BMI, target numbers, or training-only goals;
- no fabricated semantic defaults;
- no Profile owner expansion into Body concepts;
- no permanent dual-write synchronization;
- no applied migration edits;
- no legacy-column drops; O11/#54 stays blocked until O10;
- O4 remains blocked until O3D integrated acceptance.

## Exit

**O3C is complete. O3D integrated canonical Body acceptance is active on #57.**
