# Product Onboarding O4C — Canonical Wellness Persistence Cutover

**Status:** Validated  
**Tracker:** #61 ✅ closing/closed  
**Parent O4:** #58  
**Predecessor:** #60 O4B ✅ CI #1405  
**Successor:** #62 O4D integrated Wellness acceptance ACTIVE  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Validated source checkpoint

```text
2cd34d70df124efd332dbbf2b7975dcef5f29631
Flutter CI #1428 / run 32569633640
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the exact validated O4C runtime/source checkpoint. Later task/tracker-only commits do not replace it unless full CI is rerun on changed runtime source.

## Outcome

O4C cut Product Onboarding Wellness persistence to the canonical Wellness owner:

```text
OnboardingDraft.targets compatibility values
        ↓
WellnessTargetsMapper
        ↓
WellnessTargetsRepository.upsert
        ↓
SupabaseWellnessTargetsRepository
        ↓
public.user_wellness_targets
```

Canonical owner fields:

```text
steps_target
water_target_ml
sleep_target_minutes
bed_time
wake_up_time
```

Owner persistence ordering is now:

```text
Profile
→ Body
→ Wellness
→ Workout (when active)
→ Nutrition Targets
→ completion publication
```

A Wellness owner failure stops every later owner/completion action in that call.

## Completed scope

- [x] added `WellnessTargetsMapper` for onboarding Wellness compatibility values;
- [x] added canonical Wellness repository dependency to `PersistOnboardingOwnerDataUseCase`;
- [x] added `OwnerPersistenceTarget.wellness` and fail-closed ordering;
- [x] added app-level canonical Wellness repository composition;
- [x] production Supabase path resolves Wellness persistence through `SupabaseWellnessTargetsRepository`;
- [x] removed active Steps/Water/Sleep/Bed/Wake mirrors from `user_nutrition_profiles` writes;
- [x] constrained legacy `user_targets` fallback to Nutrition-owned writes only;
- [x] retained compatibility Wellness reads needed for old Nutrition rows;
- [x] retained Wellness values as Nutrition calculation inputs without durable ownership leakage;
- [x] added/updated mapper, coordinator and Nutrition repository regression coverage;
- [x] updated older integrated Profile acceptance fixtures for the new fail-closed Wellness owner contract;
- [x] full four-gate CI green on one exact source SHA.

## Validation history

### First source attempt

Flutter CI #1426 exposed a Dart constructor/type-inference composition error. It was fixed without relaxing owner semantics.

### Second source attempt

Flutter CI #1427 reached Flutter tests and exposed two stale O2E Profile acceptance fixtures that created the owner coordinator without a canonical Wellness repository. The production fail-closed guard correctly rejected them.

The fixtures were updated to inject `InMemoryWellnessTargetsRepository` explicitly for their success paths.

### Final validation

```text
2cd34d70df124efd332dbbf2b7975dcef5f29631
Flutter CI #1428 / run 32569633640
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Guardrails preserved

- no Wellness UI redesign or runtime section reorder;
- no applied migration edit;
- no legacy DB column drop/rename;
- no permanent dual-write synchronization;
- no O5 Nutrition Profile/Targets work;
- compatibility reads remain compatibility-only;
- signed-out canonical owner behavior remains fail-closed;
- PR #50 remains Draft/open/unmerged.

## Known compatibility boundary for O4D

`TargetsOnboardingDraft` remains serialized compatibility storage with concrete UI defaults, while canonical `WellnessTargetsData` has nullable unknown/unset semantics.

O4C does not perform broad draft/schema relocation. O4D #62 must explicitly prove legacy/missing-value provenance so old or absent Wellness values are not silently promoted into fabricated canonical truth. If an integrated test exposes a real gap, use the narrowest meaning-preserving fix.

## Final handoff

O4C is validated and frozen at `2cd34d70df124efd332dbbf2b7975dcef5f29631` / Flutter CI #1428.

Next active work:

```text
#62 O4D — Integrated Canonical Wellness Read/Write/Resume/Failure Acceptance
```

O5 remains blocked until O4D is green. O11/#54 remains blocked until O10.