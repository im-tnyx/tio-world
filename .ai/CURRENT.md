# Current State

Last verified from current branch/runtime trackers and live Supabase schema: 2026-08-22.

Runtime source remains behavior truth. For Product Onboarding sequencing, read `.ai/tasks/product-onboarding-canonical-execution.md` first.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o5-nutrition.md`
4. `.ai/tasks/product-onboarding-o5a-canonical-nutrition-contracts.md`
5. GitHub Issues #64/#63/#40/#44 and Draft PR #50
6. `.ai/tasks/product-onboarding-o4d-integrated-wellness-acceptance.md` for validated predecessor evidence

## Canonical persistence owners

```text
users                      → account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + active_tabs
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep/bed/wake targets
user_nutrition_profiles    → nutrition context only
user_nutrition_targets     → calories/macros/fiber + customization state
user_workout_profiles      → workout context/capability
user_workout_targets       → workout goals/plan constraints
onboarding_drafts          → draft/resume orchestration only
```

Legacy mixed columns remain temporarily. Destructive cleanup is O11/#54 and stays blocked until O10 acceptance.

## Validated Product Onboarding foundation

```text
O1 durable App Mode / active_tabs               ✅ #11 / CI #1240
O2 common User Profile owner + userProfile      ✅ #53 / CI #1279
O3 canonical Body Goal end-to-end               ✅ #55 / CI #1354
O4 Canonical Wellness end-to-end                ✅ #58 / CI #1441
```

O4 final exact validated runtime/source checkpoint:

```text
d70de933dc0cc01f1c6544d37f625fb01937b309
Flutter CI #1441 / run 32570394147
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Task/tracker commits after this SHA do not replace the validated runtime checkpoint unless runtime source changes and full CI is rerun.

## Current sequence

```text
O1 App Mode                                     ✅
O2 User Profile                                 ✅
O3 Body Goal                                    ✅
O4 Wellness                                     ✅ #58 / CI #1441
→ O5 Nutrition Profile + Targets                ACTIVE #63
   → O5A canonical owner contracts              ACTIVE #64
   O5B nutritionProfile runtime/draft/resume
   O5C nutritionGoals runtime + legacy Targets compatibility
   O5D canonical persistence cutover
   O5E integrated acceptance
→ O6 Workout
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                  BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## Current O5A objective

Create canonical Nutrition owner contracts in `tio_feature_nutrition` for the already-live tables without changing Product Onboarding UI/runtime flow:

```text
NutritionProfileRepository
        ↓
public.user_nutrition_profiles
        ↓
preferred_diet / allergies / disliked_foods / medical_conditions only

NutritionTargetsRepository
        ↓
public.user_nutrition_targets
        ↓
calories / protein / carbs / fat / fiber
+ customization_state / customized_fields / recommendation_metadata
```

Live `user_nutrition_targets.customization_state` accepts:

```text
unknown | recommended | custom | mixed
```

## Verified current gaps

- `NutritionOnboardingDraft` is empty;
- future `nutritionProfile` / `nutritionGoals` identities exist but are not active;
- current Nutrition preference renderer is compatibility-only;
- active Nutrition Target still lives under legacy `targets`;
- current `TargetsSetupRepository` is a mixed compatibility contract;
- current Supabase Targets writer stores macro data in `user_nutrition_profiles.macro_targets`, may fall back to `user_targets`, and attempts anonymous auth when signed out.

O5A adds new canonical contracts/adapters only. It does not cut over the legacy writer yet.

## Guardrails

- preserve current UI/runtime placement during O5A;
- no applied migration edits or schema changes in O5A;
- no legacy-column drops;
- no permanent dual-write synchronization;
- no fabricated diet/allergy/target defaults;
- canonical signed-out writes fail closed with no auth mutation;
- do not expose Body/Profile/Wellness legacy columns through the canonical Nutrition Profile API;
- do not start O5B until #64 is exact full-CI green;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.
