# Current State

Last verified from current branch/runtime trackers and live Supabase schema: 2026-08-22.

Runtime source remains behavior truth. For Product Onboarding sequencing, read `.ai/tasks/product-onboarding-canonical-execution.md` first.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o5-nutrition.md`
4. `.ai/tasks/product-onboarding-o5b-nutrition-profile-runtime.md`
5. GitHub Issues #65/#63/#40/#44 and Draft PR #50
6. `.ai/tasks/product-onboarding-o5a-canonical-nutrition-contracts.md` for validated predecessor evidence

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
O5A canonical Nutrition owner contracts         ✅ #64 / CI #1449
```

Latest exact validated runtime/source checkpoint:

```text
3b2cc8b896186eb291bf577bcaaadda21b8a1b8e
Flutter CI #1449 / run 32571519752
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
   O5A canonical owner contracts                ✅ #64 / CI #1449
   → O5B nutritionProfile runtime/draft/resume  ACTIVE #65
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

## O5A validated result

`tio_feature_nutrition` now exposes canonical backend-neutral Profile and Targets owner contracts and in-memory/Supabase adapters. Canonical signed-out writes fail closed without auth mutation. The legacy mixed `SupabaseTargetsSetupRepository` remains untouched until O5D.

## Current O5B objective

Activate Product Onboarding `nutritionProfile` for Nutrition + Hybrid only, immediately after Wellness, with two approved first-run concepts:

```text
Diet Type
  Vegetarian / Non-Vegetarian / Vegan / Eggitarian / Other

Food Allergies & Restrictions
  None / Lactose / Gluten / Nuts / Seafood / Other
```

`None` is exclusive. Unanswered is distinct from explicit None.

Mode eligibility:

```text
Workout   ❌ nutritionProfile
Nutrition ✅ nutritionProfile
Hybrid    ✅ nutritionProfile
```

Dormant Nutrition Profile values survive mode changes. Legacy Nutrition Target remains under `targets` unchanged until O5C.

Deferred in O5B: Diet Style, disliked foods, Nutrition-specific medical conditions, free-text Other details.

## Guardrails

- read `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md` before O5B presentation changes;
- reuse existing selection patterns; no visual redesign;
- no canonical persistence cutover in O5B;
- no migration/schema change or legacy-column drop;
- no legacy mixed writer change;
- no O5C until #65 exact full CI green;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.
