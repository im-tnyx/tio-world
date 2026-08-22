# Product Onboarding O4D — Integrated Canonical Wellness Acceptance

**Status:** Active  
**Tracker:** GitHub Issue #62  
**Parent O4:** #58  
**Predecessor O4C:** #61 ✅ Flutter CI #1428  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting validated checkpoint

```text
2cd34d70df124efd332dbbf2b7975dcef5f29631
Flutter CI #1428 / run 32569633640
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the exact validated O4C runtime/source checkpoint. Later tracking or documentation commits do not replace it unless full CI is rerun on their source content.

## Goal

Prove the complete canonical Wellness path end-to-end before O4 closes:

```text
Product Onboarding Wellness compatibility state
        ↓
WellnessTargetsMapper
        ↓
WellnessTargetsRepository
        ↓
SupabaseWellnessTargetsRepository
        ↓
public.user_wellness_targets
        ↓
canonical readback / resume / retry / failure semantics
```

Canonical owner fields:

```text
steps_target
water_target_ml
sleep_target_minutes
bed_time
wake_up_time
```

Nutrition may consume Wellness values as calculation inputs only. It must not regain durable ownership.

## Proven by O4C

- canonical Wellness write step exists in owner persistence ordering after Body and before Workout/Nutrition;
- missing/failing Wellness owner fails closed;
- production app composition exposes `WellnessTargetsRepository` backed by `SupabaseWellnessTargetsRepository` when Supabase is available;
- active Nutrition `user_nutrition_profiles` writes no longer include Wellness mirrors;
- legacy `user_targets` fallback writes Nutrition-only target data;
- compatibility Wellness reads remain available where older rows still require them;
- full workspace CI is green on the exact O4C source checkpoint above.

## Primary acceptance matrix

### A. Fresh canonical write/read

- write distinct non-default Steps/Water/Sleep/Bed/Wake values through Product Onboarding owner persistence;
- read them back through canonical Wellness repository/state;
- prove lossless units and time-minute conversion semantics;
- prove Nutrition mirrors are not written as a side effect.

### B. Canonical truth beats stale legacy mirrors

Seed canonical Wellness values and conflicting legacy Nutrition Wellness mirrors.

Expected:

```text
canonical user_wellness_targets = authoritative
legacy Nutrition mirror          = compatibility-only
```

No merge may silently replace canonical values with stale mirrors.

### C. Resume compatibility

Prove legacy serialized cursors still reconcile correctly:

```text
targets + bridge       → wellnessGoals + bridge
targets + stepTarget   → wellnessGoals + stepTarget
targets + sleepTarget  → wellnessGoals + sleepTarget
targets + waterTarget  → wellnessGoals + waterTarget
```

Values must remain lossless. Later top-level checkpoints must remain later when nested Wellness state is dormant.

### D. Missing/default provenance safety

`TargetsOnboardingDraft` is compatibility storage with concrete UI defaults while canonical `WellnessTargetsData` uses nullable unknown/unset semantics.

Explicitly test legacy/missing-field hydration. A missing historical Wellness value must not become canonical truth merely because current UI storage has a default.

Do not assume this is already safe. If a fix is required, prefer a narrow provenance/eligibility guard over schema churn.

### E. Failure ordering and auth

- canonical Wellness write failure blocks Workout, Nutrition Targets, confirmed App Mode, and completion publication in that call;
- signed-out canonical Wellness write fails closed;
- no anonymous-auth or synthetic-user side effect is allowed;
- retry after a failure remains deterministic and does not create Nutrition Wellness mirrors.

### F. Nutrition calculation continuity

Where Nutrition recommendation/target calculation requires Steps/Water/Sleep inputs, prove those inputs still reach calculation code without restoring durable Wellness mirror ownership.

## Acceptance

- [ ] fresh Wellness values round-trip through canonical owner losslessly;
- [ ] canonical readback is authoritative over stale legacy mirrors;
- [ ] legacy Wellness resume cursors migrate losslessly;
- [ ] later checkpoint preservation remains correct;
- [ ] missing legacy Wellness values do not become fabricated canonical defaults;
- [ ] canonical null/unknown semantics remain meaning-preserving where representable;
- [ ] Wellness owner failure blocks every downstream publication/write in the same call;
- [ ] signed-out write fails closed with no anonymous-auth side effect;
- [ ] retry semantics remain deterministic;
- [ ] Nutrition calculations remain correct without Wellness durable ownership leakage;
- [ ] production composition resolves the canonical Wellness repository correctly;
- [ ] active Nutrition writes remain free of Wellness mirrors;
- [ ] legacy `user_targets` remains non-authoritative for Wellness writes;
- [ ] no UI redesign, section reorder, applied migration edit, column drop, or permanent dual-write;
- [ ] Flutter analyze green on one exact O4D source SHA;
- [ ] Dart analyze green on the same SHA;
- [ ] Flutter tests green on the same SHA;
- [ ] Dart tests green on the same SHA.

## Likely focused files

```text
apps/features/onboarding/test/domain/
apps/features/progress/test/
apps/features/nutrition/test/data/
apps/app/test/app/
```

Production source changes are allowed only if an integrated acceptance test exposes a real semantic gap. Do not preemptively redesign storage contracts.

## Out of scope

- O5 Nutrition Profile/Targets source work;
- post-onboarding Wellness Settings redesign;
- physical removal/renaming of compatibility `TargetsOnboardingDraft` storage unless proven unavoidable;
- onboarding schema-version bump unless required by a meaning-preserving fix;
- applied migration edits;
- legacy column DROP/rename;
- broad Nutrition redesign;
- permanent dual-write synchronization.

## Exit

O4D closes only on one exact source SHA where the full integrated Wellness acceptance matrix and all four workspace CI gates are green.

After that:

```text
O4 Wellness ✅
→ O5 Nutrition Profile + Targets may start
```

O11/#54 remains blocked until O10 regardless of O4 completion.