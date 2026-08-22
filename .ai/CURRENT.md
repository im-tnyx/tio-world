# Current State

Last verified from current branch/runtime trackers: 2026-08-22.

This is the concise handoff for the next agent. Runtime source remains behavior truth. For Product Onboarding sequencing, read `.ai/tasks/product-onboarding-canonical-execution.md` first.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o2-user-profile-owner.md`
4. active focused task `.ai/tasks/product-onboarding-o2c-profile-write-cutover.md`
5. GitHub Issue #53 and PR #50

## Canonical persistence owners

```text
users                      → account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + active_tabs
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep
user_nutrition_profiles    → diet/allergy/food context
user_nutrition_targets     → calories/macros/fiber + target state
user_workout_profiles      → workout context/capability
user_workout_targets       → workout goals/plan constraints
onboarding_drafts          → draft/resume orchestration only
```

`users` remains the stable account root. Existing legacy mixed columns remain temporarily; no destructive cleanup yet.

## Validated foundation

```text
Section/step identity compatibility             ✅ CI #945
Target Weight draft/eligibility                 ✅ CI #1079
Goal Pace ownership/skipped-intent cleanup      ✅ CI #1090
Integrated Goal/weight local acceptance         ✅ CI #1095
Canonical Body onboarding writes                ✅ CI #1135
Canonical Body read/history contract            ✅ CI #1153
P1 Profile/App Preferences schema               ✅ LIVE
O1 durable App Mode / active_tabs               ✅ COMPLETE CI #1240
O2A narrow UserProfile contract                 ✅ CI #1252
O2B Supabase user_profiles adapter              ✅ CI #1252
```

O1 final checkpoint:

```text
c7925b77e9ccdc1dcd0b6ac1d9554f05972d13a7
Flutter CI #1240 / run 32552460378 ✅
```

O2A/O2B validated checkpoint:

```text
a263e32e2aeb64706820260c1f9eaf4c13399a3c
Flutter CI #1252 / run 32553301222
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

PR #50 remains Draft/open/unmerged.

## Current Product Onboarding sequence

```text
O1 durable App Mode / active_tabs               ✅ #11 / CI #1240
→ O2 common User Profile owner + userProfile    ACTIVE #53
   O2A narrow contract                          ✅ #1252
   O2B Supabase adapter                         ✅ #1252
   O2C onboarding Profile write cutover         ACTIVE
   O2D userProfile section/resume compatibility NEXT after O2C
   O2E integrated acceptance
→ O3 Body Goal section + Body/Profile parity
→ O4 Wellness
→ O5 Nutrition
→ O6 Workout
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
```

Independent Account/Settings lane: A1 real email/mobile add-change-verify (#8). It does not block O2.

## Active slice — O2C common Profile write cutover

Tracker: GitHub Issue #53  
Focused task: `.ai/tasks/product-onboarding-o2c-profile-write-cutover.md`

Canonical common Profile fields only:

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

O2C source direction now active:

```text
ProfileOnboardingDraft
→ strict UserProfileMapper
→ UserProfileData
→ UserProfileRepository.upsert
→ SupabaseUserProfileRepository
→ public.user_profiles

Body answers
→ existing BodySetupMapper
→ existing canonical Body owner
```

Current implementation also adds `CanonicalUserProfileBridgeRepository`: legacy Profile/avatar/settings methods still delegate to the existing broad repository, while canonical `UserProfileRepository.read/upsert` delegates to `SupabaseUserProfileRepository`. This prevents Product Onboarding canonical Profile writes from using legacy `users` while avoiding an unrelated Profile UI rewrite in O2C.

Current O2C source checkpoint before CI result:

```text
33e6a6d10a9d828e8b91b89d20bc29a8ffebba00
Flutter CI #1265 / run 32553945786 — in progress
```

O2C deliberately does not activate `OnboardingSectionId.userProfile`; O2D owns section identity + resume compatibility after O2C is green.

## Guardrails

- preserve existing Name/Gender/DOB/Units/Height/Activity/Health UI;
- preserve DOB/Height/weight picker contracts;
- Current Weight remains Body-owned;
- Body Goal/Target Weight/Goal Pace remain `user_body_goals`;
- no Account/avatar/plan/App Mode/Goal/Body values through common Profile owner;
- no fabricated semantic defaults in canonical mapper/read path;
- no anonymous-auth side effects;
- no applied migration edits;
- no legacy-column drop;
- no permanent dual-write synchronization;
- do not start O3 until O2 exact validation is recorded.
