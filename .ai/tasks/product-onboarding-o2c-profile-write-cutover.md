# Product Onboarding O2C — Canonical Profile Write Cutover

**Status:** Active  
**Tracker:** GitHub Issue #53  
**Parent task:** `.ai/tasks/product-onboarding-o2-user-profile-owner.md`  
**Canonical execution:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**Implementation PR:** #50  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Validated predecessor

O2A/O2B narrow common Profile contract + Supabase adapter are validated on the exact source/context checkpoint:

```text
a263e32e2aeb64706820260c1f9eaf4c13399a3c
Flutter CI #1252 / run 32553301222
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Validated owner boundary:

```text
UserProfileData
→ UserProfileRepository
→ SupabaseUserProfileRepository
→ public.user_profiles only
```

Authenticated canonical access has no anonymous-auth fallback. Canonical parsing is strict and the common Profile payload excludes Account/contact/avatar/plan, App Mode, Goals and Body weights.

## Outcome

Cut Product Onboarding completion-time common Profile persistence from the legacy mixed `ProfileSetupRepository` boundary to the narrow canonical `UserProfileRepository`, while preserving the existing separate Body/Workout/Targets writes and current UI/flow identities.

O2C does **not** activate `OnboardingSectionId.userProfile`; that remains O2D after write-cutover validation.

## Current legacy path

```text
ProfileOnboardingDraft
→ ProfileSetupMapper
→ ProfileSetupData
→ ProfileSetupRepository.saveProfileSetup
→ legacy/mixed users adapter
```

The legacy model/repository carries Account/avatar/plan, Goals and Body weights and is therefore not the correct canonical common Profile boundary.

## Target O2C path

```text
ProfileOnboardingDraft
→ UserProfileMapper
→ UserProfileData
→ UserProfileRepository.upsert
→ public.user_profiles

OnboardingDraft Body answers
→ existing BodySetupMapper
→ existing BodySetupRepository
```

## Required behavior

- add a pure onboarding `UserProfileMapper` that maps only approved common Profile fields;
- require real completed Profile answers instead of fabricating fallback name/gender/DOB/height/activity semantics;
- preserve exact typed `MeasurementUnitPreferences`;
- keep Health Conditions mapping owner-local and deterministic;
- `PersistOnboardingOwnerDataUseCase` depends on `UserProfileRepository`, not `ProfileSetupRepository`;
- Profile persistence failures remain `OwnerPersistenceTarget.profile` failures;
- Body persistence remains the next independent owner write and still owns Current Weight + Body Goal data;
- Workout/Targets mode-aware behavior remains unchanged;
- app composition injects `SupabaseUserProfileRepository` when Supabase is available;
- legacy broad Profile provider remains available for avatar/account/profile-settings compatibility surfaces during O2;
- no dual write from Product Onboarding into both `users` and `user_profiles`;
- no section identity/UI change in O2C.

## Acceptance

- [ ] onboarding mapper produces `UserProfileData` only;
- [ ] mapper rejects missing/invalid required common Profile answers instead of inventing defaults;
- [ ] Goals/current weight/target weight/mobile/avatar/plan cannot cross the new common Profile boundary;
- [ ] `PersistOnboardingOwnerDataUseCase` writes common Profile through `UserProfileRepository.upsert`;
- [ ] existing canonical Body write runs separately after Profile and remains intact;
- [ ] workout/nutrition/hybrid owner-write matrix is unchanged;
- [ ] Profile repository failure remains fail-closed before downstream owner writes;
- [ ] app router/composition injects the canonical user-profile repository for Product Onboarding completion;
- [ ] legacy broad Profile repository remains available for non-O2C consumers;
- [ ] focused mapper/use-case/composition tests pass;
- [ ] Flutter analyze + Dart analyze + Flutter tests + Dart tests green on an exact O2C checkpoint.

## Guardrails

- no `userProfile` section activation yet;
- no O3 Body Goal section work;
- no UI redesign;
- no applied migration edits;
- no legacy-column drop;
- no anonymous auth side effect;
- no fabricated semantic defaults;
- no permanent dual-write synchronization.

## Exit

When O2C is validated:

```text
O2A narrow contract                 ✅ #1252
O2B Supabase adapter                ✅ #1252
O2C onboarding Profile write cutover ✅ <exact CI>
→ O2D userProfile section activation + resume compatibility NEXT
```
