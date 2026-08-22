# Product Onboarding O2 — Canonical User Profile Owner

**Status:** In progress  
**Tracker:** GitHub Issue #53  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Canonical execution:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**Implementation PR:** #50  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting checkpoint

O1 durable App Mode is complete and validated:

```text
c7925b77e9ccdc1dcd0b6ac1d9554f05972d13a7
Flutter CI #1240 / run 32552460378
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O1 final evidence: `.ai/tasks/app-mode-o1f-integrated-acceptance.md`; Issue #11 is closed completed.

## Outcome

Make `public.user_profiles` the durable authenticated owner for common personal Profile data used by Product Onboarding, while preserving existing onboarding UI and keeping Account, App Mode, Body, Wellness, Nutrition and Workout data in their separate owners.

Activate the prepared `OnboardingSectionId.userProfile` boundary migration-safely without inventing a new screen or breaking existing persisted `profileBasics` draft/resume checkpoints.

## Canonical common Profile contract

```text
user_profiles
├─ user_id
├─ name
├─ gender
├─ date_of_birth
├─ unit_preferences
├─ height_cm
├─ activity_level
├─ health_conditions
├─ other_health_condition
├─ created_at
└─ updated_at
```

Allowed domain fields:

```text
name
gender
dateOfBirth
unitPreferences
heightCm
activityLevel
healthConditions
otherHealthCondition
```

Explicitly excluded:

```text
username/email/mobile/verification → users
avatar/plan/account state          → existing account/profile settings surfaces, not O2 common owner
goals/primary_goal                 → Body/goal intent owners
currentWeightKg                    → body_weight_logs
targetWeightKg / Goal Pace         → user_body_goals
App Mode / tabs                    → user_app_preferences
Wellness/Nutrition/Workout         → their canonical owners
```

## Verified starting gaps

### Legacy mixed Supabase Profile adapter

`apps/features/profile/lib/src/data/repositories/supabase_profile_setup_repository.dart` currently:
- writes/reads/realtime-watches `public.users`;
- attempts anonymous sign-in when save is called without an authenticated user;
- mixes Account/avatar/plan, Goal and Body weight fields into one payload;
- updates unit preferences in `users`;
- maps legacy rows with fabricated DOB/height/current-weight/activity defaults.

This adapter must not simply be pointed at `user_profiles`; its contract is too broad.

### Legacy mixed domain model

`ProfileSetupData` contains common Profile plus username/mobile/avatar/plan, Goals, current weight and target weight. `ProfileSetupRepository` also owns avatar operations. It remains a compatibility/legacy setup surface during O2 rather than becoming the canonical common Profile API.

### Onboarding persistence

`PersistOnboardingOwnerDataUseCase` currently maps onboarding Profile answers into `ProfileSetupData` and calls `ProfileSetupRepository.saveProfileSetup`, then separately persists canonical Body data. O2 must replace only the common Profile owner dependency; Body remains separate and intact.

### Section identity

`OnboardingSectionId.userProfile` is already prepared. Runtime `_profileBasics` still points at legacy `OnboardingSectionId.profile`, and the renderer intentionally treats `userProfile` as inactive. Reuse the existing `ProfileSection` UI when activating the new identity.

## Architecture

Introduce a narrow backend-neutral owner contract:

```text
UserProfileData
UserProfileRepository
  read()
  upsert(UserProfileData)

SupabaseUserProfileRepository
  → public.user_profiles only
  → current authenticated user only
  → strict parse/serialization
  → no anonymous sign-in
```

Keep the legacy broad `ProfileSetupRepository` available for unrelated legacy/settings/avatar consumers until later parity proves they can move. O2 should avoid a risky all-at-once rewrite.

Onboarding path after cutover:

```text
ProfileOnboardingDraft
→ Common User Profile mapper
→ UserProfileRepository.upsert

OnboardingDraft Body answers
→ existing BodySetupMapper
→ existing canonical BodySetupRepository
```

## Execution order

```text
O2A narrow UserProfile domain/repository contract
→ O2B Supabase user_profiles adapter
→ O2C Product Onboarding common Profile write cutover
→ O2D userProfile section activation + draft/resume compatibility
→ O2E integrated read/write/section acceptance + full CI
```

Only one sub-slice should advance at a time; record exact CI checkpoints when useful. O3 must not begin before O2 integrated validation.

## Acceptance

- [ ] `UserProfileData` contains only canonical common Profile fields;
- [ ] backend-neutral `UserProfileRepository` is independent of Supabase;
- [ ] `SupabaseUserProfileRepository` targets only `public.user_profiles`;
- [ ] unauthenticated canonical read/write does not create anonymous users or mutate state;
- [ ] mapper/adapter reject malformed semantic state rather than fabricating defaults;
- [ ] units preserve exact supported storage semantics;
- [ ] Product Onboarding common Profile write uses `UserProfileRepository`;
- [ ] active onboarding Profile path does not write Goals/current/target weight/account/contact/avatar/plan through Profile owner;
- [ ] existing Body owner persistence still runs separately;
- [ ] `profileBasics` step/resume identity remains compatible;
- [ ] active section is `OnboardingSectionId.userProfile`;
- [ ] renderer reuses existing `ProfileSection` UI;
- [ ] old draft/resume checkpoints reconcile safely;
- [ ] no legacy database column drop;
- [ ] no O3 `bodyGoal` section activation;
- [ ] focused contract, Supabase adapter, onboarding persistence and section compatibility tests;
- [ ] Flutter analyze + Dart analyze + Flutter tests + Dart tests green on exact O2 checkpoint.

## Guardrails

- existing Name/Gender/DOB/Units/Height/Activity/Health UI unchanged;
- existing DOB/Height picker contracts unchanged;
- Current Weight remains in the measurement journey but is Body-owned;
- Goal/Target Weight/Goal Pace stay outside common Profile owner;
- no anonymous auth side effect to make writes succeed;
- no permanent dual writes between `users` and `user_profiles`;
- no edits to applied migrations;
- canonical `user_profiles` values win when the new canonical read path is used;
- future backend must consume the same backend-neutral contract.

## Current work

**O2A → O2B: implement the narrow common Profile contract and Supabase `user_profiles` adapter with focused tests before changing onboarding orchestration.**
