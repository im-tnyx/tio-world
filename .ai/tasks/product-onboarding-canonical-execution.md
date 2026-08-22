# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1 validated; O2 common User Profile owner is ACTIVE  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O1 App Mode:** #11 ✅ closed  
**O2 User Profile:** #53 ACTIVE  
**Account verification:** #8 parallel lane  
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
```

O1 final source:

```text
c7925b77e9ccdc1dcd0b6ac1d9554f05972d13a7
Flutter CI #1240 / run 32552460378 ✅
```

O1 evidence: `.ai/tasks/app-mode-o1f-integrated-acceptance.md`. Issue #11 is closed completed.

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

Onboarding is an orchestrator, never a durable domain owner. Applied migrations are immutable; legacy columns stay until cutover proof.

## Execution order

```text
O1 App Mode durability                         ✅ #11 / CI #1240
→ O2 common User Profile owner + section       ACTIVE #53
→ O3 Body Goal section + Profile/Body parity
→ O4 Wellness placement + owner
→ O5 Nutrition Profile + Targets
→ O6 Workout Intro/Profile/Targets
→ O7 Health Connections decision/integration
→ O8 Review + edit-back + resume
→ O9 truthful Plan Building/finalization
→ O10 full mode/device/persistence acceptance
```

Only one Product Onboarding slice is active at a time. Do not start the next slice before exact validation is recorded.

## O2 — ACTIVE

Focused task: `.ai/tasks/product-onboarding-o2-user-profile-owner.md`  
Tracker: #53.

Canonical common Profile fields:

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

Current Weight is Body-owned. Goal/Target Weight/Goal Pace and Account/contact data are not common Profile-owned.

Verified gap: current broad `ProfileSetupData` / `SupabaseProfileSetupRepository` still mix Profile with Account/avatar/plan, Goal and Body weight concepts and use legacy `users`. Do not repoint that broad contract wholesale.

O2 execution:

```text
O2A UserProfileData + UserProfileRepository
→ O2B SupabaseUserProfileRepository → public.user_profiles only
→ O2C Product Onboarding common Profile persistence cutover
→ O2D activate prepared userProfile identity using existing ProfileSection UI
→ O2E integrated read/write/resume acceptance + full CI
```

Current O2A/O2B source:

```text
6b79a8b9bae0baa71146fd7139bd9574c99bc0fd
Flutter CI #1251 / run 32553012219 — running
```

O2A/O2B source adds a narrow backend-neutral owner contract, authenticated strict Supabase adapter, canonical-only payload and focused tests. O2C waits for this checkpoint to be green.

## Later slices

O3 activates `bodyGoal` while keeping Body data in Body owners. O4 resolves Wellness placement. O5 separates Nutrition Profile/Targets. O6 separates Workout Profile/Targets with Hybrid Later preserving stored data. O7 is consent-first Health Connections. O8 makes Review/resume canonical. O9 performs truthful finalization before existing Congratulations. O10 runs final cross-mode/device/persistence acceptance.

## Guardrails

- preserve existing onboarding UI by default;
- preserve DOB/Height/weight picker contracts;
- one canonical owner per concept;
- no fabricated semantic defaults;
- no anonymous-auth side effects for canonical writes;
- no permanent dual-write synchronization;
- no applied migration edits;
- no legacy-column drop before repository cutover proof;
- future backend consumes the same canonical Postgres owners and backend-neutral contracts.

## Handoff

**O2 #53 is ACTIVE. Validate O2A/O2B CI #1251, then begin O2C. Do not start O3 before O2 validation.**
