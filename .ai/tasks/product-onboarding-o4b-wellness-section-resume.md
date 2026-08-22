# Product Onboarding O4B — Wellness Runtime Section + Legacy Targets Resume

**Status:** In progress  
**Tracker:** #60  
**Parent O4:** #58  
**Predecessor:** #59 O4A ✅ CI #1365  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged

## Starting checkpoint

```text
f244b4913143ba8f76439a8b2554fd095d7e1973
Flutter CI #1365 / run 32563623833
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Outcome

Activate `OnboardingStepId.wellnessGoals` / `OnboardingSectionId.wellnessGoals` as the runtime owner of existing Wellness-facing target screens while retaining serialized compatibility in `TargetsOnboardingDraft`.

## Runtime contract

```text
wellnessGoals
  bridge
  stepTarget
  sleepTarget
  waterTarget

targets
  nutritionTarget
```

## Compatibility contract

- `targets + bridge/stepTarget/sleepTarget/waterTarget` actual legacy cursor → `wellnessGoals` with same child/value state;
- `targets + goalPace` remains O3C migration → `bodyGoal/goalPace`;
- `targets + nutritionTarget` remains `targets`;
- later top-level checkpoints stay later when nested Wellness values are dormant;
- no serialized value rewrite/schema-version bump required.

## Scope

- add typed `WellnessFlowPlan` + builder;
- activate top-level `wellnessGoals` immediately after `bodyGoal` in every selected-mode flow;
- reduce active `TargetsFlowPlan` to `nutritionTarget` while preserving full legacy order;
- add `WellnessProgressItem` and progress lookup/flattening;
- add `WellnessSection` that reuses Bridge/Step/Sleep/Water screens unchanged;
- activate renderer/export;
- split controller next/back/reconcile/completion invalidation between Wellness and Targets;
- add focused flow/progress/controller/renderer/resume tests;
- update stale existing expectations only where O4B semantics require it.

## Explicitly out of scope

- canonical Wellness persistence wiring;
- Nutrition Wellness mirror cutoff;
- migration edits or column drops;
- visual redesign;
- O5 Nutrition activation.

## Acceptance

- [ ] all selected-mode flows place `wellnessGoals` after `bodyGoal`;
- [ ] active Wellness order is Bridge → Steps → Sleep → Water;
- [ ] active Targets order is Nutrition Target only;
- [ ] existing screens render under Wellness unchanged;
- [ ] Body ↔ Wellness ↔ later top-level next/back transitions are correct;
- [ ] Wellness edits invalidate `wellnessGoals`, not `targets`;
- [ ] Nutrition Target remains Targets-owned;
- [ ] legacy actual Targets Wellness cursors migrate losslessly;
- [ ] later checkpoints remain later;
- [ ] progress denominator/order stays equivalent and continuous;
- [ ] no persistence/schema/UI changes;
- [ ] full four-gate CI green on one exact O4B source SHA.

## Guardrails

- no O4C until exact O4B full CI green;
- no O5 until O4D integrated acceptance;
- no destructive cleanup before O11.

## Current work

**Implement runtime Wellness ownership only.**

### Latest WIP checkpoint — not validated

```text
72cf4fd6b41b491f72a012225ad546a0ed970044
Flutter CI #1402 / run 32567221904 — pending at checkpoint
```

Implemented through this checkpoint:

- selected-mode plans place Wellness immediately after Body Goal;
- `WellnessFlowPlan` owns Bridge → Steps → Sleep → Water;
- active `TargetsFlowPlan` owns Nutrition Target only;
- actual legacy Targets Wellness cursors normalize losslessly to Wellness while Goal Pace retains Body migration;
- Wellness renderer/progress/controller/resume ownership is active without UI redesign or serialized value relocation;
- stale O3/Targets regression suites have been migrated to the O4B boundary, including flow plan, progress, Goal Pace compatibility, controller navigation, renderer, and durable resume coverage.

Recent CI evidence:

```text
CI #1393 / run 32565992066
Flutter analyze ❌ — one prefer_const_constructors lint only
Dart analyze    skipped
Flutter tests   skipped
Dart tests      skipped
```

The lint was fixed in `5eaf85afd4663bd167cafe30e8c8644ec53454b3`. O4B remains **in progress** until one later exact SHA is green across all four gates.
