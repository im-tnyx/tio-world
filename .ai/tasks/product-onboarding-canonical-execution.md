# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1/O2/O3/O4/O5A complete; O5B Nutrition Profile ACTIVE  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O1 App Mode:** #11 ✅  
**O2 User Profile:** #53 ✅  
**O3 Body Goal:** #55 ✅ / CI #1354  
**O4 Wellness:** #58 ✅ / CI #1441  
**O5 Nutrition:** #63 ACTIVE  
**O5A:** #64 ✅ / CI #1449  
**O5B:** #65 ACTIVE  
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
O5A canonical Nutrition owner contracts          ✅ CI #1449
```

Latest exact validated source checkpoint:

```text
3b2cc8b896186eb291bf577bcaaadda21b8a1b8e
Flutter CI #1449 / run 32571519752
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
   O5A canonical owner contracts               ✅ #64 / CI #1449
   → O5B nutritionProfile runtime/draft/resume ACTIVE #65
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

```text
wellnessGoals: Bridge → Step Target → Sleep Target → Water Target
Profile → Body → Wellness → Workout(if active) → Nutrition Targets → completion
public.user_wellness_targets = durable Wellness owner
```

O4D preserved missing-value provenance so legacy absent Wellness fields map to canonical null rather than current UI defaults.

## O5A — VALIDATED #64

Canonical Nutrition contracts now exist in `tio_feature_nutrition`:

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

Profile canonical API exposes only Nutrition context and preserves nullable collection semantics. Targets adapter targets only `user_nutrition_targets`. Canonical signed-out writes fail closed and never mutate authentication.

Existing mixed `TargetsSetupRepository` remains compatibility-only and untouched until O5D.

## O5B — ACTIVE #65

Focused task: `.ai/tasks/product-onboarding-o5b-nutrition-profile-runtime.md`.

### Mode eligibility

Historical approved onboarding architecture and #46 align on:

```text
Workout   ❌ nutritionProfile
Nutrition ✅ nutritionProfile
Hybrid    ✅ nutritionProfile
```

Dormant answers survive mode changes. O5B intentionally leaves the existing legacy all-mode Nutrition Target under `targets`; O5C handles Nutrition Goal ownership/mode semantics separately.

### Approved O5B first-run fields

```text
Diet Type:
Vegetarian | Non-Vegetarian | Vegan | Eggitarian | Other

Food Allergies & Restrictions:
None | Lactose | Gluten | Nuts | Seafood | Other
```

`None` is exclusive. Unanswered remains distinct from explicit None.

Do not collect Diet Style, disliked foods, Nutrition-specific medical conditions, or free-text Other details in O5B because their canonical first-run semantics are not unambiguous/approved.

### Runtime target

```text
Nutrition:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → targets → review

Hybrid:
userProfile → bodyGoal → wellnessGoals → nutritionProfile
→ workoutIntro → optional workoutPreferences → targets → review

Workout:
unchanged
```

O5B adds typed onboarding-local option/draft contracts and additive DTO resume support. Canonical persistence remains O5D work.

## Guardrails

- read and follow design-system/UI governance before O5B presentation changes;
- reuse current selection/card/header/progress patterns; no visual redesign;
- no fabricated semantic defaults;
- no canonical persistence cutover in O5B;
- no Nutrition Goal migration until O5C;
- no applied migration edits or legacy-column drops;
- no legacy mixed writer changes;
- no O5C until #65 exact full CI green;
- O11/#54 stays blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Handoff

**Execute O5B #65 only. The validated runtime baseline is `3b2cc8b896186eb291bf577bcaaadda21b8a1b8e` / Flutter CI #1449.**
