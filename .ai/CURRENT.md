# Current State

Last verified from current branch/runtime trackers: 2026-08-22.

Runtime source remains behavior truth. For Product Onboarding sequencing, read `.ai/tasks/product-onboarding-canonical-execution.md` first.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o4-wellness.md`
4. `.ai/tasks/product-onboarding-o4d-integrated-wellness-acceptance.md`
5. GitHub Issues #62/#58/#40/#44 and Draft PR #50
6. `.ai/tasks/product-onboarding-o4c-wellness-persistence-cutover.md` for validated predecessor evidence

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
O4C canonical Wellness persistence cutover      ✅ #61 / CI #1428
```

O4C exact validated runtime/source checkpoint:

```text
2cd34d70df124efd332dbbf2b7975dcef5f29631
Flutter CI #1428 / run 32569633640
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Later task/tracker-only commits do not replace this exact validated runtime checkpoint unless full CI is rerun on changed runtime source.

## Current sequence

```text
O1 App Mode                                     ✅
O2 User Profile                                 ✅
O3 Body Goal                                    ✅
→ O4 Wellness                                   ACTIVE #58
   O4A canonical repository contract            ✅ #59 / CI #1365
   O4B runtime section/navigation/resume        ✅ #60 / CI #1405
   O4C canonical persistence cutover            ✅ #61 / CI #1428
   → O4D integrated acceptance                  ACTIVE #62
→ O5 Nutrition                                  BLOCKED by O4D
→ O6 Workout
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                  BLOCKED #54
```

## Current O4D objective

Prove the complete canonical Wellness contract end-to-end:

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
canonical read / resume / retry / failure behavior
```

O4C already stopped active Nutrition Wellness mirror writes. O4D must now prove canonical truth, legacy resume compatibility, failure ordering, signed-out fail-closed behavior, Nutrition calculation continuity, and the missing/default provenance boundary.

Specific risk to test rather than assume:

```text
TargetsOnboardingDraft
  concrete compatibility/UI defaults

WellnessTargetsData
  nullable unknown/unset semantics
```

Legacy snapshots missing Wellness values must not silently become fabricated canonical truth.

## Guardrails

- one Product Onboarding sub-slice active at a time;
- no O5 source work before #62 O4D exact full CI green;
- no UI redesign or section reorder in O4D;
- no applied migration edits or legacy-column drops;
- no permanent dual-write synchronization;
- no fabricated canonical semantic defaults;
- Wellness failure must block downstream publication in the same call;
- no O11 destructive cleanup before O10;
- PR #50 remains Draft/open/unmerged.