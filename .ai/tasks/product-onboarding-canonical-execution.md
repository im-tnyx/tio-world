# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1 validated; O2C common User Profile write cutover ACTIVE  
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
O2A narrow UserProfile contract                  ✅ CI #1252
O2B Supabase user_profiles adapter               ✅ CI #1252
```

O1 final:

```text
c7925b77e9ccdc1dcd0b6ac1d9554f05972d13a7
Flutter CI #1240 / run 32552460378 ✅
```

O2A/O2B final:

```text
a263e32e2aeb64706820260c1f9eaf4c13399a3c
Flutter CI #1252 / run 32553301222
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
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

Onboarding orchestrates; it does not own durable domain data. Applied migrations are immutable and legacy columns remain until verified cleanup.

## Execution order

```text
O1 App Mode durability                         ✅ #11 / CI #1240
→ O2 common User Profile owner + section       ACTIVE #53
   O2A narrow contract                        ✅ #1252
   O2B Supabase adapter                       ✅ #1252
   O2C onboarding Profile write cutover       ACTIVE
   O2D userProfile section + resume           NEXT after O2C
   O2E integrated acceptance
→ O3 Body Goal section + Profile/Body parity
→ O4 Wellness placement + owner
→ O5 Nutrition Profile + Targets
→ O6 Workout Intro/Profile/Targets
→ O7 Health Connections
→ O8 Review + edit-back + resume
→ O9 Plan Building/finalization
→ O10 final acceptance
```

Only one Product Onboarding slice is active at a time.

## O2 — Common User Profile owner

Parent task: `.ai/tasks/product-onboarding-o2-user-profile-owner.md`  
Tracker: #53.

Canonical fields:

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

Not common Profile-owned: Account/contact, App Mode, current weight, Body Goal/Target/Pace, Wellness, Nutrition or Workout data.

### O2C — ACTIVE

Focused task: `.ai/tasks/product-onboarding-o2c-profile-write-cutover.md`.

Target path:

```text
ProfileOnboardingDraft
→ strict UserProfileMapper
→ UserProfileData
→ UserProfileRepository.upsert
→ SupabaseUserProfileRepository
→ public.user_profiles

Body answers
→ existing BodySetupMapper
→ existing canonical Body repository
```

Current source includes:
- strict mapper with no fabricated name/gender/DOB/height/activity defaults;
- Product Onboarding owner coordinator calling canonical `UserProfileRepository.upsert`;
- separate Body/Workout/Targets writes preserved;
- `CanonicalUserProfileBridgeRepository` so legacy Profile/avatar/settings APIs remain available while canonical common Profile methods route to `SupabaseUserProfileRepository`;
- focused mapper/use-case/bridge tests;
- no `userProfile` section activation yet.

Latest source at this handoff:

```text
df611158b28f5ded0ef924e45d7d5798803bbfd9
```

Take one exact full-CI checkpoint after context-sync commits settle. If green, record O2C and move to O2D.

## Later slices

O2D activates `userProfile` using the existing `ProfileSection` UI and proves old `profileBasics` draft/resume compatibility. O2E integrates canonical read/write/section acceptance. O3 then activates Body Goal parity. O4–O10 remain in the established sequence.

## Guardrails

- preserve existing onboarding UI by default;
- preserve DOB/Height/weight picker contracts;
- one canonical owner per concept;
- no fabricated semantic defaults;
- no anonymous-auth side effects for canonical writes;
- no permanent dual-write synchronization;
- no applied migration edits;
- no legacy-column drop before proof;
- do not start O3 before O2 exact validation.

## Handoff

**O2C is ACTIVE on #53. Validate the latest branch head, record exact CI, then start O2D.**
