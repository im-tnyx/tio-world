# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1/O2 complete; O3C Goal Pace placement ACTIVE  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O1 App Mode:** #11 ✅ closed  
**O2 User Profile:** #53 ✅ closed  
**O3 Body Goal:** #55 ACTIVE  
**O3C Goal Pace:** #56 ACTIVE  
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
O3A Body Goal typed child-flow contract          ✅ CI #1290
O3B bodyGoal runtime section + legacy resume     ✅ CI #1319
```

O3B final source checkpoint:

```text
3df7dbd61a57340f7d6f767361d3ceaa49cc83fb
Flutter CI #1319 / run 32558694870
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Canonical owners

```text
users                      → stable account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + ordered active_tabs
user_devices               → device owner
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep
user_nutrition_profiles    → nutrition context
user_nutrition_targets     → nutrition targets
user_workout_profiles      → workout context
user_workout_targets       → workout targets
onboarding_drafts          → draft/resume orchestration only
```

Onboarding orchestrates; it does not own durable domain data. Applied migrations are immutable and legacy duplicate columns remain until verified O11 cleanup.

## Execution order

```text
O1 App Mode durability                         ✅ #11 / CI #1240
O2 common User Profile owner + section         ✅ #53 / CI #1279
→ O3 Body Goal section + Profile/Body parity   ACTIVE #55
   O3A typed Body Goal child-flow contract     ✅ CI #1290
   O3B bodyGoal runtime section + resume       ✅ CI #1319
   O3C Goal Pace placement/parity              ACTIVE #56
   O3D integrated Body acceptance              NEXT after O3C
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

### O3A — VALIDATED

Typed `BodyGoalFlowPlan` + mode-aware builder established Goal/Current Weight/eligible Target Weight as a distinct child contract. Exact full CI: #1290.

### O3B — VALIDATED

Active top-level flow now places `bodyGoal` immediately after common `userProfile`; existing Goal/current/target screens are reused; legacy mixed-Profile Body cursors reconcile safely; continuous progress and durable resume preservation are Body Goal-aware. Exact full CI: #1319.

### O3C — ACTIVE

Tracker: #56  
Focused task: `.ai/tasks/product-onboarding-o3c-goal-pace-parity.md`.

Current mismatch:

```text
Goal Pace durable owner = user_body_goals
Goal Pace runtime child  = Targets / TargetStepId.goalPace
Goal Pace draft value    = TargetsOnboardingDraft.goalPaceKgPerWeek
```

Target runtime for eligible explicit weight direction:

```text
Body Goal:
Goal → Current Weight → Target Weight → Goal Pace
```

Non-directional/ineligible:

```text
Body Goal:
Goal → Current Weight
```

Active Targets flow after O3C must skip Goal Pace. Preserve serialized pace value compatibility and reuse the existing `GoalPaceScreen`; no destructive draft/schema migration and no UI redesign.

Legacy/current `targets + goalPace` actual resume cursors must migrate to canonical Body Goal Goal Pace without losing the value. Later top-level checkpoints stay later when pace is only dormant data.

## Guardrails

- preserve existing onboarding UI and picker contracts;
- one canonical owner per concept;
- no Body direction inference from measurements/BMI/training-only goals;
- no fabricated semantic defaults;
- no anonymous-auth side effects for canonical writes;
- no permanent dual-write synchronization;
- no applied migration edits;
- no legacy-column drop before O10/O11;
- do not start O3D until O3C exact full CI is recorded;
- do not start O4 until O3D integrated acceptance.

## Handoff

**O3C is ACTIVE on #56 from validated O3B source `3df7dbd6…` / CI #1319. Execute Goal Pace runtime relocation only, then require exact full Flutter/Dart CI before O3D.**
