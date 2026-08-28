# Product Onboarding O5 — Canonical Nutrition Profile + Targets

**Status:** Completed / validated  
**Tracker:** GitHub Issue #63  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Predecessor O4:** #58 ✅ / CI #1441  
**O5A:** #64 ✅ / CI #1449  
**O5B:** #65 ✅ / CI #1460  
**O5C:** #66 ✅ / CI #1481  
**O5D:** #67 ✅ / CI #1505  
**O5E:** #68 ✅ / CI #1507  
**Successor O6:** #69 ACTIVE  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged

## Exact validated O5 checkpoint

```text
b017f6c31c9c89a6df1ba6b670ea0ea04d635941
Flutter CI #1507 / run 32583620248
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Canonical owners

```text
public.user_nutrition_profiles → Nutrition context only
public.user_nutrition_targets  → calories/macros/fiber + customization state/metadata
```

Body, common Profile and Wellness remain separate canonical owners.

## Completed execution

```text
O5A canonical Nutrition Profile + Targets repository contracts ✅ #64 / CI #1449
O5B nutritionProfile runtime/draft/navigation/resume           ✅ #65 / CI #1460
O5C nutritionGoals runtime + legacy Targets compatibility      ✅ #66 / CI #1481
O5D canonical persistence cutover + mixed writer shutdown      ✅ #67 / CI #1505
O5E integrated read/write/resume/failure/customization         ✅ #68 / CI #1507
```

## Frozen O5 result

- `nutritionProfile` is active for Nutrition/Hybrid only.
- `nutritionGoals` is active for Workout/Nutrition/Hybrid.
- unanswered allergies persist as canonical `null`; explicit None persists as empty set.
- selected restrictions persist as stable storage strings.
- canonical Nutrition Targets preserve the existing recommendation outputs and customization state.
- onboarding-generated targets are `recommended` with empty `customizedFields`.
- legacy `targets + nutritionTarget` draft identity resumes under `nutritionGoals`.
- Product Onboarding completion depends directly on `NutritionProfileRepository` and `NutritionTargetsRepository`.
- Product Onboarding completion no longer depends on or calls `TargetsSetupRepository.saveTargetsSetup`.
- Nutrition Profile, Workout and Nutrition Targets failure boundaries block later completion publication.
- retry and completed-idempotence behavior are covered.
- production canonical Nutrition providers remain directly composed.

## Guardrails retained after O5

- no legacy-column drop until O11 after O10;
- legacy Nutrition readers may remain compatibility-only outside Product Onboarding completion;
- no permanent dual write;
- no Body/Wellness/Profile mirrors in canonical Nutrition owners.

## Exit

O5 is frozen at `b017f6c31c9c89a6df1ba6b670ea0ea04d635941` / Flutter CI #1507. O6 Workout is ACTIVE on #69 with O6A #70 as the only active sub-slice.