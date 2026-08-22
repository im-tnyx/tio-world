# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1/O2 validated; O3A Body Goal flow contract ACTIVE  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O1 App Mode:** #11 ✅ closed  
**O2 User Profile:** #53 ✅ closed  
**O3 Body Goal:** #55 ACTIVE  
**Account verification:** #8 parallel lane  
**O11 cleanup:** #54 BLOCKED until O10  
**PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Current validated foundation

```text
Section/step identity foundation                 ✅ CI #945
Target Weight eligibility/draft                  ✅ CI #1079
Goal Pace ownership/skipped cleanup              ✅ CI #1090
Integrated Goal/weight acceptance                ✅ CI #1095
Canonical Body onboarding writes                 ✅ CI #1135
Canonical Body read/history                      ✅ CI #1153
Canonical owner schema + P1 Profile/App Prefs    ✅ LIVE
O1 durable App Mode / active_tabs                ✅ CI #1240
O2 common User Profile end-to-end                ✅ CI #1279
```

O1 final:

```text
c7925b77e9ccdc1dcd0b6ac1d9554f05972d13a7
Flutter CI #1240 / run 32552460378 ✅
```

O2 final:

```text
7e7119aa4dfe9cb53b1078376aa93e950f987adb
Flutter CI #1279 / run 32555540391
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O2 sequence:

```text
O2A narrow UserProfile contract                 ✅ #1252
O2B Supabase user_profiles adapter              ✅ #1252
O2C onboarding canonical Profile write          ✅ #1268
O2D userProfile section + legacy resume         ✅ #1275
O2E integrated canonical Profile acceptance     ✅ #1279
```

## Canonical owners

```text
users                      → account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + ordered active_tabs
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep
user_nutrition_profiles    → nutrition context
user_nutrition_targets     → nutrition targets
user_workout_profiles      → workout context
user_workout_targets       → workout targets
onboarding_drafts          → draft/resume orchestration only
```

Onboarding orchestrates; it does not own durable domain data. Applied migrations are immutable and legacy columns remain until verified O11 cleanup.

## Execution order

```text
O1 App Mode durability                         ✅ #11 / CI #1240
O2 common User Profile owner + section         ✅ #53 / CI #1279
→ O3 Body Goal section + Profile/Body parity   ACTIVE #55
   O3A typed Body Goal child-flow contract     ACTIVE
   O3B bodyGoal runtime section activation     NEXT after O3A
   O3C Goal Pace placement/parity
   O3D integrated Body acceptance
→ O4 Wellness placement + owner
→ O5 Nutrition Profile + Targets
→ O6 Workout Intro/Profile/Targets
→ O7 Health Connections
→ O8 Review + edit-back + resume
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                 BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## O2 — COMPLETE

Parent task: `.ai/tasks/product-onboarding-o2-user-profile-owner.md`  
Final task: `.ai/tasks/product-onboarding-o2e-integrated-profile-acceptance.md`  
Tracker: #53 closed.

Common Profile owner is `public.user_profiles` for:

```text
name
gender
date_of_birth
unit_preferences
height_cm
activity_level
health_conditions
other_health_condition
```

Current Weight, Body Goal, Target Weight and Goal Pace are explicitly outside common Profile ownership.

## O3 — Body Goal section + Profile/Body parity

Parent task: `.ai/tasks/product-onboarding-o3-body-goal.md`  
Tracker: #55.

Canonical Body owners stay unchanged:

```text
body_weight_logs → Current Weight/history
user_body_goals  → Body Goal + Target Weight + Goal Pace
```

Existing onboarding draft compatibility fields stay readable during O3:

```text
OnboardingDraft.goalSelection
ProfileOnboardingDraft.currentWeightKg
ProfileOnboardingDraft.targetWeightKg
ProfileOnboardingDraft.targetWeightDirection
TargetsOnboardingDraft.goalPaceKgPerWeek
```

### O3A — ACTIVE

Focused task: `.ai/tasks/product-onboarding-o3a-body-goal-flow-contract.md`.

Contract-first implementation adds:

```text
BodyGoalFlowPlan
  goal
  currentWeight
  targetWeight?  ← GoalWeightFollowUpPolicy
```

The child plan deliberately reuses existing `ProfileStepId` identities to preserve serialized draft compatibility. O3A does not activate the top-level `bodyGoal` runtime step, renderer, or controller navigation; that is O3B after O3A exact full CI is green.

Current O3A source includes:
- `body_goal_flow_plan.dart`;
- `build_body_goal_flow_plan_use_case.dart`;
- focused mode/conditional/reconciliation tests;
- barrel exports;
- no persistence/schema/UI changes.

## Guardrails

- preserve existing onboarding UI and picker contracts;
- one canonical owner per concept;
- no Body direction inference from measurements/BMI/training-only goals;
- no fabricated semantic defaults;
- no anonymous-auth side effects for canonical writes;
- no permanent dual-write synchronization;
- no applied migration edits;
- no legacy-column drop before O10/O11;
- do not start O3B until O3A exact full CI is recorded;
- do not start O4 until O3D integrated acceptance.

## Handoff

**O3A is ACTIVE on #55. Validate the latest exact branch head with full Flutter/Dart CI; only then start O3B runtime `bodyGoal` section activation.**
