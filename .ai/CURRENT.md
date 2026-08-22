# Current State

Last verified from current branch/runtime trackers: 2026-08-22.

Runtime source remains behavior truth. For Product Onboarding sequencing, read `.ai/tasks/product-onboarding-canonical-execution.md` first.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o4-wellness.md`
4. `.ai/tasks/product-onboarding-o4b-wellness-section-resume.md`
5. GitHub Issues #60/#58 and Draft PR #50

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
```

O4A exact checkpoint:

```text
f244b4913143ba8f76439a8b2554fd095d7e1973
Flutter CI #1365 / run 32563623833
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Current sequence

```text
O1 App Mode                                     ✅
O2 User Profile                                 ✅
O3 Body Goal                                    ✅
→ O4 Wellness                                   ACTIVE #58
   O4A canonical repository contract            ✅ #59 / CI #1365
   O4B runtime section/navigation/resume        ACTIVE #60
   O4C persistence + Nutrition mirror cutoff    BLOCKED
   O4D integrated acceptance                    BLOCKED
→ O5 Nutrition                                  BLOCKED by O4
→ O6 Workout
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                  BLOCKED #54
```

## O4B target runtime

```text
wellnessGoals
  Bridge
  → Step Target
  → Sleep Target
  → Water Target

targets
  Nutrition Target
```

Stable compatibility storage remains in `TargetsOnboardingDraft` / `TargetStepId`. O4B moves runtime ownership only; no persistence cutover occurs in this slice.

Legacy actual `targets + bridge/stepTarget/sleepTarget/waterTarget` cursors migrate to `wellnessGoals`. Legacy `targets + goalPace` continues to migrate to Body Goal. `targets + nutritionTarget` remains Targets. Later checkpoints remain later when nested values are dormant.

## Guardrails

- reuse existing Wellness screens without visual redesign;
- no Wellness persistence wiring in O4B;
- no Nutrition Wellness mirror cutoff until O4C;
- no migration edits or legacy-column drops;
- no permanent dual-write;
- no O4C until O4B exact full CI green;
- no O5 source work before O4 integrated acceptance.
