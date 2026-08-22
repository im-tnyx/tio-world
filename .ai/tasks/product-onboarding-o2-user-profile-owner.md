# Product Onboarding O2 — Canonical User Profile Owner

**Status:** Validated / complete  
**Tracker:** GitHub Issue #53  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Canonical execution:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Outcome

`public.user_profiles` is the durable authenticated owner for common personal Profile data used by Product Onboarding. Existing Profile UI is preserved, active onboarding identity is `userProfile`, and legacy `profileBasics` draft/resume compatibility remains intact.

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
avatar/plan/account state          → account/legacy surfaces
goals/primary_goal                 → Body/goal intent owners
currentWeightKg                    → body_weight_logs
targetWeightKg / Goal Pace         → user_body_goals
App Mode / tabs                    → user_app_preferences
Wellness/Nutrition/Workout         → dedicated owners
```

## Validated execution

```text
O2A narrow UserProfileData + UserProfileRepository        ✅ CI #1252
O2B SupabaseUserProfileRepository → public.user_profiles  ✅ CI #1252
O2C Product Onboarding common Profile write cutover       ✅ CI #1268
O2D userProfile section + draft/resume compatibility      ✅ CI #1275
O2E integrated read/write/section acceptance + full CI    ✅ CI #1279
```

Final O2 checkpoint:

```text
7e7119aa4dfe9cb53b1078376aa93e950f987adb
Flutter CI #1279 / run 32555540391
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Focused O2 checkpoints:

```text
O2A/O2B
a263e32e2aeb64706820260c1f9eaf4c13399a3c
Flutter CI #1252 / run 32553301222 ✅

O2C
75bcdc487a67b79128d41fb42547c0a50c8520ce
Flutter CI #1268 / run 32554015902 ✅

O2D
6843a14b89f0c0bb7d62b1466eb3855ddbef0f64
Flutter CI #1275 / run 32555015103 ✅
```

## Frozen behavior

- `UserProfileData` contains only canonical common Profile fields;
- `SupabaseUserProfileRepository` targets only `public.user_profiles`;
- unauthenticated canonical access fails closed without anonymous-auth side effects;
- malformed canonical state fails strictly rather than fabricating semantic defaults;
- Product Onboarding Profile writes use `UserProfileRepository.upsert`;
- canonical onboarding writes do not call broad legacy `saveProfileSetup`;
- Current Weight and Body Goal remain separate Body-owned persistence;
- active `profileBasics` flow resolves to `OnboardingSectionId.userProfile` and reuses existing `ProfileSection` UI;
- persisted `profileBasics` + nested Profile step/data resume without schema/version bump;
- stale legacy common-Profile mirrors never override canonical `UserProfileRepository.read` truth;
- no legacy columns were dropped and no permanent dual-write synchronization was introduced.

## Integrated acceptance

Focused task: `.ai/tasks/product-onboarding-o2e-integrated-profile-acceptance.md`.

Integrated harness:

`apps/features/onboarding/test/domain/o2e_integrated_profile_acceptance_test.dart`

It proves stale-legacy-vs-canonical read precedence, canonical write/read round-trip, owner ordering, Body separation, serialized resume to `userProfile`, and failure-safe completion semantics.

## Exit

**O2 is complete. Next Product Onboarding work is O3 Body Goal section + Profile/Body parity. O11 destructive cleanup remains blocked until O10 final acceptance.**
