# Current State

Last verified from current branch/runtime trackers: 2026-08-22.

Runtime source remains behavior truth. For Product Onboarding sequencing, read `.ai/tasks/product-onboarding-canonical-execution.md` first.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o4-wellness.md`
4. `.ai/tasks/product-onboarding-o4c-wellness-persistence-cutover.md`
5. GitHub Issues #61/#58/#40/#44 and Draft PR #50
6. `.ai/tasks/product-onboarding-o4b-wellness-section-resume.md` only for validated predecessor evidence

## Canonical persistence owners

```text
users                      → account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + active_tabs
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep/bed/wake targets
user_nutrition_profiles    → diet/allergy/food context
user_nutrition_targets     → calories/macros/fiber + target state
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
O4A canonical Wellness repository contract      ✅ #59 / CI #1365
O4B Wellness runtime/navigation/resume           ✅ #60 / CI #1405
```

O4B exact runtime/source checkpoint:

```text
fc795e6411fe303d6381441c3ba872f99d522977
Flutter CI #1405 / run 32567404925
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Later pre-O4C branch commits are task/tracker handoff commits and do not replace the exact validated O4B runtime checkpoint above.

## Current sequence

```text
O1 App Mode                                     ✅
O2 User Profile                                 ✅
O3 Body Goal                                    ✅
→ O4 Wellness                                   ACTIVE #58
   O4A canonical repository contract            ✅ #59 / CI #1365
   O4B runtime section/navigation/resume        ✅ #60 / CI #1405
   → O4C canonical persistence cutover          ACTIVE #61
   O4D integrated acceptance                    BLOCKED by O4C
→ O5 Nutrition                                  BLOCKED by O4
→ O6 Workout
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                  BLOCKED #54
```

## Current O4C objective

```text
Onboarding Wellness values
        ↓
WellnessTargetsRepository
        ↓
public.user_wellness_targets
```

Current verified gap:

```text
PersistOnboardingOwnerDataUseCase
  Profile → Body → Workout(if active) → Nutrition Targets
  no Wellness owner write yet

SupabaseTargetsSetupRepository
  still writes Steps/Water/Sleep/Bed/Wake mirrors
  into user_nutrition_profiles
  and can fall back to user_targets
```

O4C must introduce canonical Wellness persistence and stop active Nutrition Wellness mirror writes while preserving required compatibility reads and calculation inputs.

## Guardrails

- one Product Onboarding sub-slice active at a time;
- no UI redesign in O4C;
- no applied migration edits or legacy-column drops;
- no permanent dual-write synchronization;
- canonical null means unknown/intentional clear, not UI default;
- Wellness persistence failure must fail closed before downstream completion;
- no O4D until exact O4C full CI green;
- no O5 source work before O4D integrated acceptance;
- no O11 destructive cleanup before O10.