# Product Onboarding O4 — Canonical Wellness

**Status:** In progress — O4A/O4B/O4C validated; O4D ACTIVE  
**Tracker:** GitHub Issue #58  
**O4A:** #59 ✅ closed / CI #1365  
**O4B:** #60 ✅ closed / CI #1405  
**O4C:** #61 ✅ validated / CI #1428  
**O4D:** #62 ACTIVE  
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

O4C canonical persistence cutover:
```text
2cd34d70df124efd332dbbf2b7975dcef5f29631
Flutter CI #1428 / run 32569633640
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Later task/tracker-only commits do not replace O4C's exact validated runtime/source SHA.

## Canonical durable owner

```text
user_wellness_targets
→ steps_target
→ water_target_ml
→ sleep_target_minutes
→ bed_time
→ wake_up_time
```

O4A established the backend-neutral repository boundary. O4B aligned runtime/navigation/progress/resume semantics to Wellness. O4C wired Product Onboarding persistence to the canonical owner and stopped active Nutrition Wellness mirror writes.

## Execution

```text
O4A canonical Wellness domain/repository contract             ✅ #59 / CI #1365
O4B wellnessGoals runtime section/navigation/progress/resume  ✅ #60 / CI #1405
O4C canonical Wellness persistence + Nutrition mirror cutoff ✅ #61 / CI #1428
→ O4D integrated Wellness read/write/resume/failure acceptance ACTIVE #62
```

Only one O4 sub-slice is active at a time.

## Current runtime and persistence

```text
wellnessGoals
  Bridge
  → Step Target
  → Sleep Target
  → Water Target

Product Onboarding owner persistence
  Profile
  → Body
  → Wellness
  → Workout (when active)
  → Nutrition Targets
  → completion
```

Existing `TargetsOnboardingDraft` / `TargetStepId` remain serialized compatibility containers. Runtime semantic ownership is Wellness without UI redesign.

Active Nutrition persistence no longer writes Steps/Water/Sleep/Bed/Wake mirrors to `user_nutrition_profiles`; legacy `user_targets` fallback is Nutrition-only. Compatibility reads may remain for older rows until later cutovers/O11.

## O4D current objective

Focused task: `.ai/tasks/product-onboarding-o4d-integrated-wellness-acceptance.md`  
Tracker: #62.

O4D must prove:

- canonical fresh write/read round-trip;
- canonical owner truth beats stale legacy Nutrition mirrors;
- legacy Wellness cursor/value resume remains lossless;
- later checkpoint preservation remains correct;
- concrete compatibility/UI defaults are not silently promoted to fabricated canonical truth for legacy missing-value cases;
- canonical null/unknown semantics remain meaning-preserving where representable;
- signed-out and owner failure paths fail closed;
- Wellness failure blocks every downstream write/completion publication in the same call;
- Nutrition calculations keep required inputs without regaining durable Wellness ownership;
- production repository composition remains canonical;
- exact full four-gate CI is green on one O4D source SHA.

Production source changes are permitted only when an integrated acceptance test exposes a real semantic gap.

## Guardrails

- no UI redesign or section reorder;
- no fabricated semantic defaults;
- no permanent dual-write synchronization;
- no applied migration edits or legacy-column drops;
- do not remove compatibility reads before downstream consumers are proven canonical;
- no O5 until #62 O4D integrated acceptance;
- no O11 cleanup until O10;
- PR #50 remains Draft/open/unmerged.

## Current work

**Execute #62 O4D integrated canonical Wellness acceptance from validated O4C source checkpoint `2cd34d70df124efd332dbbf2b7975dcef5f29631`.**