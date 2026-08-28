# Product Onboarding O5E — Integrated Canonical Nutrition Acceptance

**Status:** Completed / validated  
**Tracker:** GitHub Issue #68  
**Parent O5:** #63 ✅ / CI #1507  
**Predecessor O5D:** #67 ✅ / CI #1505  
**Successor O6:** #69 ACTIVE  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged

## Exact validated O5E checkpoint

```text
b017f6c31c9c89a6df1ba6b670ea0ea04d635941
Flutter CI #1507 / run 32583620248
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Validated mode ownership

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

Eligibility remains resolved from active `OnboardingFlowPlan` identities.

## Validated integrated contracts

### Nutrition Profile

Canonical write/read preserves:

```text
unanswered allergies → null
explicit None        → {}
selected restrictions→ stable storage strings
```

`dislikedFoods` and `medicalConditions` remain unknown when Product Onboarding has no Nutrition-specific source. Common Profile health conditions are not mirrored.

### Nutrition Targets

Canonical write/read preserves calories, macros, fiber, recommendation metadata and supported customization states. Onboarding-generated recommendations remain `recommended` with empty `customizedFields`.

### Legacy resume

Legacy `targets + nutritionTarget` normalizes/resumes under active `nutritionGoals`. Product Onboarding completion remains canonical-only and does not restore the legacy mixed writer.

### Failure/retry

Validated order remains:

```text
Profile → Body → Wellness → Nutrition Profile(if active)
→ Workout(if active) → Nutrition Targets
→ App Mode/preferences → completion
```

Nutrition Profile failure blocks all later owners/publication; Workout failure blocks Nutrition Targets/publication; Nutrition Targets failure blocks mode/preferences/completion. Retry succeeds safely and a completed retry does not duplicate canonical Nutrition writes.

### Production composition

Existing app provider coverage continues to validate direct `nutritionProfileRepositoryProvider` and `nutritionTargetsRepositoryProvider` composition, including Supabase adapter selection when available.

## Acceptance

- [x] all four active mode/branch ownership paths pass;
- [x] Nutrition Profile canonical write/read preserves null vs explicit-empty vs selected restrictions;
- [x] Nutrition Targets canonical write/read preserves current recommendation outputs;
- [x] supported customization states round-trip without normalization;
- [x] legacy `targets + nutritionTarget` resume lands on `nutritionGoals`;
- [x] no Product Onboarding legacy mixed completion write returns;
- [x] Nutrition Profile failure blocks all later owners/publication;
- [x] Workout failure blocks Nutrition Targets/publication;
- [x] Nutrition Targets failure blocks App Mode/preferences/completion;
- [x] retry/idempotence behavior is proven;
- [x] production composition uses direct canonical Nutrition providers;
- [x] no UI/navigation/formula/eligibility/schema changes;
- [x] four CI gates green on one exact source SHA.

## Exit

O5E is frozen at `b017f6c31c9c89a6df1ba6b670ea0ea04d635941` / Flutter CI #1507. O5 #63 is complete. O6 #69 is active; O11 remains blocked until O10.