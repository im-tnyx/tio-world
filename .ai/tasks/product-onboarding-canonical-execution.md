# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1/O2/O3/O4 complete; O5A Nutrition contracts ACTIVE  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O1 App Mode:** #11 ✅  
**O2 User Profile:** #53 ✅  
**O3 Body Goal:** #55 ✅ / CI #1354  
**O4 Wellness:** #58 ✅ / CI #1441  
**O5 Nutrition:** #63 ACTIVE  
**O5A:** #64 ACTIVE  
**Account verification:** #8 parallel lane  
**O11 cleanup:** #54 BLOCKED until O10  
**PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Current validated foundation

```text
O1 durable App Mode / active_tabs                ✅ CI #1240
O2 common User Profile end-to-end                ✅ CI #1279
O3 canonical Body Goal end-to-end                ✅ CI #1354
O4 canonical Wellness end-to-end                 ✅ CI #1441
```

O4 final exact source checkpoint:

```text
d70de933dc0cc01f1c6544d37f625fb01937b309
Flutter CI #1441 / run 32570394147
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Later docs/tracker commits do not replace this runtime/source checkpoint unless full CI is rerun on changed runtime source.

## Canonical owners

```text
users                      → stable account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + ordered active_tabs
user_devices               → device owner
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep/bed/wake targets
user_nutrition_profiles    → nutrition context only
user_nutrition_targets     → calories/macros/fiber + customization state
user_workout_profiles      → workout context
user_workout_targets       → workout targets
onboarding_drafts          → draft/resume orchestration only
```

Applied migrations are immutable. Legacy duplicate/mixed columns remain until verified O11 cleanup.

## Execution order

```text
O1 App Mode durability                         ✅ #11 / CI #1240
O2 common User Profile owner + section         ✅ #53 / CI #1279
O3 Body Goal section + Body/Profile parity     ✅ #55 / CI #1354
O4 Wellness placement + canonical owner        ✅ #58 / CI #1441
→ O5 Nutrition Profile + Targets               ACTIVE #63
   → O5A canonical owner contracts             ACTIVE #64
   O5B nutritionProfile runtime/draft/resume
   O5C nutritionGoals runtime + legacy Targets compatibility
   O5D canonical persistence cutover + mixed writer shutdown
   O5E integrated acceptance
→ O6 Workout Intro/Profile/Targets
→ O7 Health Connections
→ O8 Review + edit-back + resume
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                 BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## O4 — VALIDATED

O4 final contract:

```text
wellnessGoals: Bridge → Step Target → Sleep Target → Water Target

Profile → Body → Wellness → Workout(if active) → Nutrition Targets → completion

public.user_wellness_targets = durable Wellness owner
```

O4D also preserved missing-value provenance so legacy absent Wellness fields map to canonical null rather than current UI defaults.

## O5 — ACTIVE #63

Focused parent task: `.ai/tasks/product-onboarding-o5-nutrition.md`.

### Verified live Nutrition owner schema

```text
public.user_nutrition_profiles
  preferred_diet
  allergies[]
  disliked_foods[]
  medical_conditions[]
  + transitional legacy/mixed columns still physically present

public.user_nutrition_targets
  calories_kcal
  protein_grams
  carbohydrate_grams
  fat_grams
  fiber_grams
  customization_state
  customized_fields[]
  recommendation_metadata
```

Live target customization state is constrained to:

```text
unknown | recommended | custom | mixed
```

Both live tables have RLS enabled.

### Verified current source gap

```text
NutritionOnboardingDraft = empty
nutritionProfile / nutritionGoals IDs = defined but inactive
Nutrition preference UI = compatibility-only
active Nutrition Target = legacy targets section
Nutrition domain = mixed TargetsSetupData / TargetsSetupRepository only
```

Current `SupabaseTargetsSetupRepository` still writes numeric target data to `user_nutrition_profiles.macro_targets`, may fall back to `user_targets`, and attempts anonymous authentication when signed out. O5 must replace this as the canonical Product Onboarding path without destructive schema cleanup.

## O5A — ACTIVE #64

Focused task: `.ai/tasks/product-onboarding-o5a-canonical-nutrition-contracts.md`.

O5A establishes backend-neutral contracts only:

```text
NutritionProfileData
NutritionProfileRepository
InMemoryNutritionProfileRepository
SupabaseNutritionProfileRepository

NutritionTargetsData
NutritionTargetCustomizationState
NutritionTargetsRepository
InMemoryNutritionTargetsRepository
SupabaseNutritionTargetsRepository
```

O5A does not change runtime flow, onboarding draft fields, UI, mode eligibility, migrations, or the legacy compatibility writer.

Canonical Profile API must expose only current Nutrition context fields, never the physically present Body/Profile/Wellness legacy mirrors. Canonical Targets adapter must target only `user_nutrition_targets`, preserve nullable semantics, parse customization state strictly, and fail closed when signed out without auth mutation.

## Mode eligibility boundary

Current Product Onboarding includes legacy Nutrition Target in all selected-mode flow plans. Post-onboarding Nutrition Settings #46 is Nutrition/Hybrid only. O5A intentionally does not resolve this product distinction. O5B/O5C must make an explicit Product Onboarding eligibility decision before runtime activation.

## Guardrails

- preserve current screens/picker contracts during O5A;
- no fabricated semantic defaults;
- no permanent dual-write synchronization;
- no applied migration edits or legacy-column drops;
- canonical owner repositories never authenticate users themselves;
- legacy reads may remain compatibility-only until their owner cutover is proven;
- no O5B until #64 exact full CI green;
- O11/#54 stays blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Handoff

**Execute O5A #64 only. Do not activate Nutrition runtime sections or cut over persistence until the canonical contracts are validated.**
