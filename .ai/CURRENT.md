# Current State

Last verified from current branch/runtime trackers: 2026-08-22.

This is the concise handoff for the next agent. Runtime source remains behavior truth. For Product Onboarding sequencing, read `.ai/tasks/product-onboarding-canonical-execution.md` first.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. focused task for the active slice
4. relevant GitHub issue and runtime source

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

## Product Onboarding validated foundation

```text
Section/step identity compatibility             ✅ CI #945
Target Weight draft/eligibility                 ✅ CI #1079
Goal Pace ownership/skipped-intent cleanup      ✅ CI #1090
Integrated Goal/weight local acceptance         ✅ CI #1095
Canonical Body onboarding writes                ✅ CI #1135
Canonical Body read/history contract            ✅ CI #1153
P1 Profile/App Preferences schema               ✅ LIVE
O1 durable App Mode / active_tabs               ✅ COMPLETE CI #1240
```

Final O1 checkpoint:

```text
c7925b77e9ccdc1dcd0b6ac1d9554f05972d13a7
Flutter CI #1240 / run 32552460378
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O1 evidence: `.ai/tasks/app-mode-o1f-integrated-acceptance.md`; Issue #11 is closed completed.

PR #50 remains Draft/open/unmerged for the wider Product Onboarding program.

## Current Product Onboarding sequence

```text
O1 durable App Mode / active_tabs               ✅ #11 / CI #1240
→ O2 common User Profile owner + userProfile    ACTIVE #53
→ O3 Body Goal section + Body/Profile parity
→ O4 Wellness placement + owner
→ O5 Nutrition Profile + Nutrition Targets split
→ O6 Workout Intro/Profile/Targets split
→ O7 Health Connections decision/integration
→ O8 Review + edit-back + draft/resume
→ O9 truthful Plan Building/finalization + existing Congratulations
→ O10 full mode/device/persistence acceptance
→ later legacy-column cleanup
```

Independent Account/Settings lane: A1 real email/mobile add-change-verify (#8). It does not block O2.

## Active slice — O2 common User Profile owner

Focused task: `.ai/tasks/product-onboarding-o2-user-profile-owner.md`  
Focused tracker: GitHub Issue #53.

Canonical `user_profiles` owns only:

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

Verified starting gap:
- production `SupabaseProfileSetupRepository` still reads/writes mixed `users` data and contains an anonymous-sign-in save fallback;
- legacy `ProfileSetupData` / `ProfileSetupRepository` mix common Profile with Account/avatar/plan, Goal and Body weight fields;
- Product Onboarding persists that mixed Profile contract before its separate canonical Body write;
- runtime still labels `profileBasics` with legacy `OnboardingSectionId.profile`; prepared `userProfile` is inactive in renderer.

O2 architecture direction:

```text
O2A UserProfileData + UserProfileRepository
→ O2B SupabaseUserProfileRepository → public.user_profiles only
→ O2C Product Onboarding common Profile write cutover
→ O2D activate userProfile identity using existing ProfileSection UI
→ O2E integrated acceptance + full CI
```

Do not repoint the broad legacy ProfileSetup contract at `user_profiles`. Introduce a narrow backend-neutral common Profile owner, require authenticated canonical writes, remove fabricated semantic defaults from the canonical path, and keep Body/Goal/Account concepts out.

Do not start O3 until O2 exact validation is recorded in #53/#40/#44/PR #50 and canonical tasks.

## Important product/UI rules

- Existing Name/Gender/DOB/Units/Height/Activity/Health UI is preserved.
- Existing DOB/Height/weight picker contracts are preserved.
- Current Weight remains Body-owned through `body_weight_logs`.
- Body Goal/Target Weight/Goal Pace remain `user_body_goals`.
- Existing Goal card visual language remains unchanged.
- Maintain/Recomposition do not auto-save Target Weight=current weight.
- Hybrid Workout Intro `Later` preserves stored Workout data.
- no applied migration edits;
- no permanent dual-write synchronization;
- no fabricated defaults or semantic inference;
- no legacy-column drop before cutover proof.
