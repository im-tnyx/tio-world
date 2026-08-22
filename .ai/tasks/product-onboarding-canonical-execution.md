# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1/O2/O3/O4/O5A/O5B/O5C/O5D complete; O5E integrated Nutrition acceptance ACTIVE  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O5 Nutrition:** #63 ACTIVE  
**O5D:** #67 ✅ / CI #1505  
**O5E:** #68 ACTIVE  
**Account verification:** #8 parallel lane  
**O11 cleanup:** #54 BLOCKED until O10  
**PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Latest exact validated source checkpoint

```text
7af5ab0cb1bc37a84af568763a2214977dd57c0c
Flutter CI #1505 / run 32582725736
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O5D runtime/source checkpoint. Later docs/tracker commits do not replace it unless changed runtime source is rerun through full CI.

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
O1 App Mode durability                           ✅ #11 / CI #1240
O2 common User Profile owner + section           ✅ #53 / CI #1279
O3 Body Goal section + Body/Profile parity       ✅ #55 / CI #1354
O4 Wellness placement + canonical owner          ✅ #58 / CI #1441
→ O5 Nutrition Profile + Targets                 ACTIVE #63
   O5A canonical owner contracts                 ✅ #64 / CI #1449
   O5B nutritionProfile runtime/draft/resume     ✅ #65 / CI #1460
   O5C nutritionGoals runtime + legacy Targets   ✅ #66 / CI #1481
   O5D canonical persistence cutover             ✅ #67 / CI #1505
   → O5E integrated acceptance                   ACTIVE #68
→ O6 Workout Intro/Profile/Targets
→ O7 Health Connections
→ O8 Review + edit-back + resume
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                   BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## Validated through O5D

```text
Workout:
userProfile → bodyGoal → wellnessGoals → workoutPreferences → nutritionGoals → review

Nutrition:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → nutritionGoals → review

Hybrid:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → workoutIntro
→ optional workoutPreferences → nutritionGoals → review
```

`nutritionProfile` is Nutrition/Hybrid only. `nutritionGoals` is all-mode. Legacy `targets + nutritionTarget` resumes under stable `nutritionGoals` without changing UI/calculation behavior.

O5D validated direct canonical completion writes:

```text
NutritionProfileRepository → user_nutrition_profiles
NutritionTargetsRepository → user_nutrition_targets
```

Product Onboarding completion no longer depends on `TargetsSetupRepository`. The legacy mixed repository may remain compatibility-only for other consumers until later cleanup.

Target fail-closed owner order:

```text
Profile → Body → Wellness → Nutrition Profile(if active)
→ Workout(if active) → Nutrition Targets → App preferences → completion
```

## O5E — ACTIVE #68

Focused task: `.ai/tasks/product-onboarding-o5e-integrated-nutrition-acceptance.md`.

O5E freezes the integrated Nutrition contract before O6:

- mode matrix for canonical Nutrition Profile/Targets ownership;
- canonical read/write round-trip and exact provenance semantics;
- legacy draft/resume compatibility without legacy completion writes;
- failure/retry ordering and idempotence;
- recommendation/customization state preservation;
- production canonical repository composition;
- exact four-gate CI acceptance.

## Guardrails

- no UI/navigation/formula/mode-eligibility change;
- no fabricated semantic defaults;
- no applied migration edits or legacy-column drops;
- no permanent dual write;
- no Nutrition recreation of Body/Wellness/Profile mirrors;
- O6 does not start until #68 exact full CI green;
- O11/#54 stays blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Handoff

**Execute O5E #68 only. Frozen predecessor checkpoint: `7af5ab0cb1bc37a84af568763a2214977dd57c0c` / Flutter CI #1505.**