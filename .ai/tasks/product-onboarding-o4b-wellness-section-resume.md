# Product Onboarding O4B — Wellness Runtime Section + Legacy Targets Resume

**Status:** Validated  
**Tracker:** #60 ✅ closed  
**Parent O4:** #58  
**Predecessor:** #59 O4A ✅ CI #1365  
**Successor:** O4C canonical Wellness persistence  
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

## Final validated checkpoint

```text
fc795e6411fe303d6381441c3ba872f99d522977
Flutter CI #1405 / run 32567404925
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Outcome

Activated `OnboardingStepId.wellnessGoals` / `OnboardingSectionId.wellnessGoals` as the runtime owner of existing Wellness-facing target screens while retaining serialized compatibility in `TargetsOnboardingDraft`.

## Validated runtime contract

```text
wellnessGoals
  bridge
  stepTarget
  sleepTarget
  waterTarget

targets
  nutritionTarget
```

## Validated compatibility contract

- `targets + bridge/stepTarget/sleepTarget/waterTarget` actual legacy cursor → `wellnessGoals` with same child/value state;
- `targets + goalPace` remains O3C migration → `bodyGoal/goalPace`;
- `targets + nutritionTarget` remains `targets`;
- later top-level checkpoints stay later when nested Wellness values are dormant;
- no serialized value rewrite/schema-version bump was required.

## Completed scope

- [x] added typed `WellnessFlowPlan` + builder;
- [x] activated top-level `wellnessGoals` immediately after `bodyGoal` in every selected-mode flow;
- [x] reduced active `TargetsFlowPlan` to `nutritionTarget` while preserving full legacy order;
- [x] added Wellness progress ownership and lookup/flattening;
- [x] added `WellnessSection` reusing Bridge/Step/Sleep/Water screens unchanged;
- [x] activated renderer/export;
- [x] split controller next/back/reconcile/completion invalidation between Wellness and Targets;
- [x] added focused flow/progress/controller/renderer/resume coverage;
- [x] migrated stale existing expectations only where O4B semantics required it.

## Acceptance

- [x] all selected-mode flows place `wellnessGoals` after `bodyGoal`;
- [x] active Wellness order is Bridge → Steps → Sleep → Water;
- [x] active Targets order is Nutrition Target only;
- [x] existing screens render under Wellness unchanged;
- [x] Body ↔ Wellness ↔ later top-level next/back transitions are correct;
- [x] Wellness edits invalidate `wellnessGoals`, not `targets`;
- [x] Nutrition Target remains Targets-owned;
- [x] legacy actual Targets Wellness cursors migrate losslessly;
- [x] later checkpoints remain later;
- [x] progress denominator/order stays equivalent and continuous;
- [x] no persistence/schema/UI changes were introduced by O4B;
- [x] full four-gate CI green on exact O4B source SHA.

## Guardrails preserved

- canonical Wellness persistence was intentionally not wired in O4B;
- Nutrition Wellness mirror cutoff remains O4C work;
- no migration edits or legacy-column drops;
- no UI redesign;
- no O5 until O4D integrated acceptance;
- no destructive cleanup before O11.

## Final handoff

O4B is validated. O4C may start from exact source checkpoint `fc795e6411fe303d6381441c3ba872f99d522977` / Flutter CI #1405.

O4C must wire Product Onboarding Wellness values through the canonical `WellnessTargetsRepository` and stop Nutrition persistence from remaining the durable owner of Steps/Water/Sleep/Bed/Wake values, while preserving compatibility reads and avoiding destructive schema cleanup.