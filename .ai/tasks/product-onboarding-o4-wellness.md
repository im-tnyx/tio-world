# Product Onboarding O4 — Canonical Wellness

**Status:** In progress — O4A/O4B validated; O4C NEXT  
**Tracker:** GitHub Issue #58  
**O4A:** #59 ✅ closed / CI #1365  
**O4B:** #60 ✅ validated / CI #1405  
**O4C:** NEXT  
**Parent:** #40  
**Canonical ownership:** #44  
**Predecessor:** #55 O3 ✅ CI #1354  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Validated foundation

O3 final:
```text
75237e6c31222f4b08f3cdd41353121aa1ca3afc
Flutter CI #1354 / run 32562632629 ✅
```

O4A canonical Wellness repository contract:
```text
f244b4913143ba8f76439a8b2554fd095d7e1973
Flutter CI #1365 / run 32563623833
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O4B runtime Wellness section/resume:
```text
fc795e6411fe303d6381441c3ba872f99d522977
Flutter CI #1405 / run 32567404925
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Canonical durable owner

```text
user_wellness_targets
→ steps_target
→ water_target_ml
→ sleep_target_minutes
→ bed_time
→ wake_up_time
```

O4A established the backend-neutral repository boundary in `tio_feature_progress`. O4B aligned runtime/navigation/progress/resume semantics to Wellness.

## Execution

```text
O4A canonical Wellness domain/repository contract             ✅ #59 / CI #1365
O4B wellnessGoals runtime section/navigation/progress/resume  ✅ #60 / CI #1405
→ O4C canonical Wellness persistence + Nutrition mirror cutoff NEXT
→ O4D integrated Wellness read/write/resume/failure acceptance BLOCKED
```

Only one O4 sub-slice is active at a time.

## Current runtime

```text
wellnessGoals
  Bridge
  → Step Target
  → Sleep Target
  → Water Target

targets
  Nutrition Target
```

Existing `TargetsOnboardingDraft` / `TargetStepId` remain serialized compatibility containers. Runtime ownership is now Wellness without UI redesign.

## O4C verified starting gap

`PersistOnboardingOwnerDataUseCase` currently persists Profile, Body, optional Workout, then Nutrition Targets. It does not yet receive or call `WellnessTargetsRepository`.

`TargetsSetupMapper` still carries Steps/Water/Sleep/Bed/Wake fields into Nutrition `TargetsSetupData`, and `SupabaseTargetsSetupRepository` still writes them to `user_nutrition_profiles` with a legacy `user_targets` fallback.

The canonical `SupabaseWellnessTargetsRepository` is already available and writes only `public.user_wellness_targets`, preserving nulls and failing closed for signed-out writes.

O4C must therefore:

```text
Onboarding Wellness draft
→ canonical Wellness mapper
→ WellnessTargetsRepository.upsert
→ user_wellness_targets

Nutrition target calculation
← may consume Wellness values as inputs

Nutrition persistence
→ must stop durable Steps/Water/Sleep/Bed/Wake mirror writes
```

Compatibility reads may remain where required until later owner cutovers. No physical schema cleanup belongs in O4C.

## Guardrails

- no UI redesign;
- no fabricated semantic defaults;
- no permanent dual-write synchronization;
- no applied migration edits or legacy-column drops;
- do not remove compatibility reads before downstream consumers are proven canonical;
- no O5 until O4D integrated acceptance;
- no O11 cleanup until O10.

## Current work

**Create and execute one focused O4C persistence cutover task/issue.**