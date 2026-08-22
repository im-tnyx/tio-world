# Product Onboarding O2 — Canonical User Profile Owner

**Status:** In progress — O2A/O2B validated; O2C write cutover ACTIVE  
**Tracker:** GitHub Issue #53  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Canonical execution:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**Implementation PR:** #50  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Validated predecessor

O1 durable App Mode is complete:

```text
c7925b77e9ccdc1dcd0b6ac1d9554f05972d13a7
Flutter CI #1240 / run 32552460378 ✅
```

O2A/O2B common Profile owner foundation is validated:

```text
a263e32e2aeb64706820260c1f9eaf4c13399a3c
Flutter CI #1252 / run 32553301222
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Outcome

Make `public.user_profiles` the durable authenticated owner for common personal Profile data used by Product Onboarding, preserve existing UI, and activate `OnboardingSectionId.userProfile` migration-safely only after the persistence cutover is validated.

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

Excluded from common Profile ownership:

```text
username/email/mobile/verification → users
avatar/plan/account state          → legacy/account surfaces pending later parity
goals/primary_goal                 → Body/goal intent owners
currentWeightKg                    → body_weight_logs
targetWeightKg / Goal Pace         → user_body_goals
App Mode / tabs                    → user_app_preferences
Wellness/Nutrition/Workout         → dedicated owners
```

## Execution

```text
O2A narrow UserProfileData + UserProfileRepository        ✅ CI #1252
O2B SupabaseUserProfileRepository → public.user_profiles  ✅ CI #1252
O2C Product Onboarding common Profile write cutover       ACTIVE
→ O2D userProfile section activation + draft/resume compatibility
→ O2E integrated read/write/section acceptance + full CI
```

### O2A/O2B — VALIDATED

Implemented and validated:
- narrow backend-neutral `UserProfileData` / `UserProfileRepository`;
- `SupabaseUserProfileRepository` reads/writes only `public.user_profiles`;
- authenticated user required, no anonymous sign-in side effect;
- strict gender/DOB/height/activity/health/unit parsing;
- DB snake_case semantics preserved (`very_active`, `low_blood_pressure`);
- payload excludes Account/avatar/plan, App Mode, Goals and Body weights.

### O2C — ACTIVE

Focused task: `.ai/tasks/product-onboarding-o2c-profile-write-cutover.md`.

Active target path:

```text
ProfileOnboardingDraft
→ UserProfileMapper
→ UserProfileData
→ UserProfileRepository.upsert
→ SupabaseUserProfileRepository
→ public.user_profiles

Body answers
→ BodySetupMapper
→ existing canonical Body repository
```

Implemented so far:
- strict `UserProfileMapper`; required name/gender/DOB/height/activity fail closed rather than receiving legacy fabricated defaults;
- Health Conditions and exact typed measurement units map only into common Profile;
- `PersistOnboardingOwnerDataUseCase` uses `UserProfileRepository.upsert` at the Profile owner boundary;
- Profile failure remains `OwnerPersistenceTarget.profile` and stops downstream writes;
- Body/Workout/Targets writes remain separate and mode-aware;
- `CanonicalUserProfileBridgeRepository` preserves broad legacy Profile/avatar/settings APIs while routing canonical `UserProfileRepository` methods to `SupabaseUserProfileRepository`;
- Supabase app composition injects that bridge through the existing Profile provider, so Product Onboarding canonical upsert does not call legacy `saveProfileSetup`;
- focused mapper/use-case/bridge tests added.

O2C current source checkpoint before authoritative final CI:

```text
151361176e9582c6cd86061e898835a0a4cb43e7
```

O2C does not activate `userProfile` section identity. That is O2D.

## Remaining acceptance

- [x] `UserProfileData` contains only canonical common Profile fields;
- [x] backend-neutral `UserProfileRepository` exists;
- [x] Supabase adapter targets only `user_profiles`;
- [x] unauthenticated canonical adapter access has no anonymous side effects;
- [x] strict canonical parser/serializer validated;
- [x] O2A/O2B full CI green #1252;
- [x] onboarding canonical mapper targets `UserProfileData` only;
- [x] Product Onboarding Profile write calls `UserProfileRepository.upsert`;
- [x] existing Body owner persistence remains separate;
- [x] composition prevents canonical onboarding upsert from calling broad legacy save;
- [ ] O2C full CI green and exact checkpoint recorded;
- [ ] activate `OnboardingSectionId.userProfile` using existing `ProfileSection` UI;
- [ ] preserve `profileBasics` persisted step/resume compatibility;
- [ ] canonical Profile read precedence over stale `users` mirrors integrated;
- [ ] O2E integrated acceptance/full CI;
- [ ] no legacy columns dropped;
- [ ] no O3 `bodyGoal` activation before O2 completion.

## Guardrails

- existing Name/Gender/DOB/Units/Height/Activity/Health UI unchanged;
- DOB/Height picker contracts unchanged;
- Current Weight remains Body-owned;
- Goal/Target Weight/Goal Pace stay outside common Profile owner;
- no anonymous auth side effect;
- no permanent `users` ↔ `user_profiles` dual-write sync;
- no edits to applied migrations;
- no fabricated semantic defaults in canonical paths;
- future backend consumes the same backend-neutral common Profile contract.

## Current work

**Validate O2C on the latest exact branch head. When green, record the checkpoint and start O2D `userProfile` section activation + resume compatibility.**
