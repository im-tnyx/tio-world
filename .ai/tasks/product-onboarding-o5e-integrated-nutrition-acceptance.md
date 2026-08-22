# Product Onboarding O5E — Integrated Canonical Nutrition Acceptance

**Status:** Active  
**Tracker:** GitHub Issue #68  
**Parent O5:** #63  
**Predecessor O5D:** #67 ✅ / CI #1505  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting validated checkpoint

```text
7af5ab0cb1bc37a84af568763a2214977dd57c0c
Flutter CI #1505 / run 32582725736
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This exact SHA is the frozen O5D runtime/source baseline. Later task/tracker-only commits do not replace it.

## Objective

Freeze Product Onboarding O5 as one integrated canonical Nutrition contract before O6 begins.

O5E must prove that the already-implemented Nutrition Profile runtime, Nutrition Goals runtime, and O5D canonical persistence cutover behave coherently across fresh, resume, retry, and mode-specific flows.

No new UI, navigation, recommendation formula, mode eligibility, persistence schema, or migration belongs in O5E.

## Acceptance matrix

### Mode ownership

```text
Workout
  Nutrition Profile  ❌
  Nutrition Targets  ✅

Nutrition
  Nutrition Profile  ✅
  Nutrition Targets  ✅

Hybrid setupNow
  Nutrition Profile  ✅
  Workout             ✅
  Nutrition Targets   ✅

Hybrid later
  Nutrition Profile  ✅
  Workout             ❌
  Nutrition Targets   ✅
```

Eligibility remains resolved from the active `OnboardingFlowPlan`, not ad hoc mode conditionals.

## Integrated contracts

### 1. Nutrition Profile round-trip

Prove canonical write/read preservation for:

```text
preferredDiet
allergies = null            // unanswered
allergies = {}              // explicit None
allergies = {stable values} // selected restrictions
```

`dislikedFoods` and `medicalConditions` must remain unknown unless a real Nutrition-specific source collects them. Common Profile health conditions must not be mirrored.

### 2. Nutrition Targets round-trip

Reuse the existing recommendation calculation and prove canonical persistence/read of:

```text
caloriesKcal
proteinGrams
carbohydrateGrams
fatGrams
fiberGrams
customizationState
customizedFields
recommendationMetadata
```

Onboarding-generated recommendations remain:

```text
customizationState = recommended
customizedFields = {}
```

Repository read/write tests must preserve supported `recommended`, `custom`, and `mixed` states without normalizing or fabricating semantics.

### 3. Legacy resume compatibility

Legacy draft identities/values remain interpretation-only compatibility:

```text
targets + nutritionTarget
→ active nutritionGoals
```

Resume must not restore Product Onboarding completion writes through `TargetsSetupRepository.saveTargetsSetup`.

### 4. Failure/retry ordering

Preserve the O5D owner order:

```text
Profile
→ Body
→ Wellness
→ Nutrition Profile (if active)
→ Workout (if active)
→ Nutrition Targets
→ App Mode/preferences
→ completion
```

Prove:

- Nutrition Profile failure blocks Workout, Nutrition Targets, App Mode/preferences and completion;
- Workout failure blocks Nutrition Targets, App Mode/preferences and completion;
- Nutrition Targets failure blocks App Mode/preferences and completion;
- retry after owner failure is safe and semantically idempotent;
- completed retry does not duplicate semantic owner state.

### 5. Production composition

Prove the app continues to inject canonical Nutrition owners directly:

```text
nutritionProfileRepositoryProvider
nutritionTargetsRepositoryProvider
```

Legacy `targetsSetupRepositoryProvider` may remain for compatibility consumers outside Product Onboarding completion but is not an onboarding completion dependency.

## Implementation slices

1. Add/extend one focused O5E integrated acceptance test matrix rather than duplicating every lower-level O5A-D test.
2. Cover Workout, Nutrition, Hybrid setupNow and Hybrid later ownership.
3. Cover canonical Profile null/empty/selected restriction provenance through write/read.
4. Cover canonical Nutrition Targets recommendation output + customization-state preservation.
5. Cover legacy draft resume into `nutritionGoals` while asserting canonical completion ownership.
6. Cover fail-closed owner order and retry/idempotence.
7. Cover production canonical provider composition.
8. Run full four-gate CI on one exact O5E source SHA.

## Guardrails

- no UI/navigation/formula/eligibility change;
- no schema/migration change or applied migration edit;
- no legacy-column drop;
- no permanent dual write;
- no Profile/Body/Wellness mirrors in Nutrition owners;
- do not remove compatibility readers needed outside Product Onboarding completion;
- O6 does not start until O5E exact full CI green;
- O11/#54 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Acceptance

- [ ] all four active mode/branch ownership paths pass;
- [ ] Nutrition Profile canonical write/read preserves null vs explicit-empty vs selected restrictions;
- [ ] Nutrition Targets canonical write/read preserves current recommendation outputs;
- [ ] supported customization states round-trip without normalization;
- [ ] legacy `targets + nutritionTarget` resume lands on `nutritionGoals`;
- [ ] no Product Onboarding legacy mixed completion write returns;
- [ ] Nutrition Profile failure blocks all later owners/publication;
- [ ] Workout failure blocks Nutrition Targets/publication;
- [ ] Nutrition Targets failure blocks App Mode/preferences/completion;
- [ ] retry/idempotence behavior is proven;
- [ ] production composition uses direct canonical Nutrition providers;
- [ ] no UI/navigation/formula/eligibility/schema changes;
- [ ] four CI gates green on one exact source SHA.

## Exit

Freeze exact O5E source SHA + CI evidence, close #68 completed, mark O5 #63 complete, update #40/#44/#50 and durable trackers, then activate O6 Workout. O11 remains blocked until O10.