# Product Onboarding O2E — Integrated Canonical Profile Acceptance

**Status:** Validated  
**Tracker:** GitHub Issue #53  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Final checkpoint

O2E and the complete O2 common Profile lifecycle are validated on:

```text
7e7119aa4dfe9cb53b1078376aa93e950f987adb
Flutter CI #1279 / run 32555540391
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O2D predecessor:

```text
6843a14b89f0c0bb7d62b1466eb3855ddbef0f64
Flutter CI #1275 / run 32555015103 ✅
```

## Validated O2 sequence

```text
O2A UserProfileData + UserProfileRepository               ✅ #1252
O2B SupabaseUserProfileRepository → public.user_profiles   ✅ #1252
O2C Product Onboarding canonical Profile write cutover     ✅ #1268
O2D active userProfile section + legacy resume             ✅ #1275
O2E integrated canonical Profile acceptance                ✅ #1279
```

## Canonical lifecycle proved

```text
stale legacy users Profile mirror
→ canonical UserProfileRepository.read remains authoritative
→ Product Onboarding draft / userProfile section
→ strict UserProfileData mapping
→ canonical user_profiles upsert
→ Body owner remains separate
→ onboarding completion publishes only after owner persistence
→ serialized profileBasics resume resolves to userProfile
→ fresh canonical read returns accepted Profile truth
```

Integrated harness:

`apps/features/onboarding/test/domain/o2e_integrated_profile_acceptance_test.dart`

It proves:
- canonical read is independent of a stale legacy broad Profile mirror;
- common Profile write/read round-trip preserves canonical fields;
- Product Onboarding calls canonical Profile persistence before mode/completion publication;
- Current Weight remains Body-owned;
- legacy broad `saveProfileSetup` is not called by canonical onboarding persistence;
- serialized `profileBasics` keeps nested Profile answers and resumes through active `userProfile`;
- canonical Profile failure blocks Body/downstream completion publication.

Focused O2A/O2B coverage remains authoritative for authenticated Supabase access and strict malformed-state parsing. Full CI #1279 re-runs those focused suites together with O2E.

## Acceptance

- [x] canonical `UserProfileRepository.read` returns `user_profiles` truth independently of stale legacy `users` Profile mirrors;
- [x] canonical common Profile write/read round-trip preserves name, gender, DOB, units, height, activity and health fields exactly;
- [x] Product Onboarding completion path uses canonical Profile upsert before completion publication;
- [x] canonical Profile contract excludes Account/avatar/plan/App Mode/Goal/current/target weight concepts;
- [x] Body current weight/Goal persistence remains separate and unchanged;
- [x] active Product Onboarding Profile section is `userProfile` using existing `ProfileSection`;
- [x] serialized legacy `profileBasics` snapshot resumes to active `userProfile` without losing answers/nested Profile step;
- [x] canonical Profile failure prevents downstream false completion;
- [x] unauthenticated canonical Profile access fails closed with no anonymous auth side effect;
- [x] malformed canonical Profile state fails safely rather than fabricating semantic defaults;
- [x] no legacy column drop/schema migration;
- [x] no O3/bodyGoal activation occurred before O2 validation;
- [x] full Flutter analyze + Dart analyze + Flutter tests + Dart tests green on exact final O2 checkpoint;
- [x] exact final O2 evidence is ready to freeze into #53/#40/#44/PR #50 and repo handoff before O3 implementation.

## Ownership frozen by O2

```text
public.user_profiles
├─ name
├─ gender
├─ date_of_birth
├─ unit_preferences
├─ height_cm
├─ activity_level
├─ health_conditions
└─ other_health_condition
```

Explicitly outside common Profile:

```text
current weight             → body_weight_logs
Body Goal / target / pace  → user_body_goals
App Mode / active tabs     → user_app_preferences
Account/contact/avatar     → account/legacy compatibility surfaces
Wellness/Nutrition/Workout → dedicated owners
```

## Exit

**O2E is validated. O2 common User Profile owner is complete. O3 Body Goal section + Profile/Body parity may start only from the exact O2 evidence above.**
