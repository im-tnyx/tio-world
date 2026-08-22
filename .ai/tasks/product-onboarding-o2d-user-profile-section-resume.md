# Product Onboarding O2D — `userProfile` Section + Resume Compatibility

**Status:** In progress  
**Tracker:** GitHub Issue #53  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting checkpoint

O2C canonical common Profile write cutover is validated:

```text
75bcdc487a67b79128d41fb42547c0a50c8520ce
Flutter CI #1268 / run 32554015902
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Validated O2C behavior:
- Product Onboarding maps common Profile answers through strict `UserProfileMapper`;
- persistence calls `UserProfileRepository.upsert`;
- Supabase canonical path writes `public.user_profiles`;
- Body remains a separate canonical owner;
- broad legacy Profile/avatar/settings APIs remain compatibility-only through `CanonicalUserProfileBridgeRepository`;
- canonical onboarding upsert does not call legacy broad `saveProfileSetup`.

## Outcome

Activate prepared `OnboardingSectionId.userProfile` for the existing Profile onboarding section without changing visual design, while preserving old persisted `profileBasics`/legacy `profile` resume checkpoints.

O2D is a section identity/resume migration slice, not a new Profile UI or ownership slice.

## Scope

```text
existing ProfileSection UI
+ existing profileBasics step id
+ new active section identity: OnboardingSectionId.userProfile
+ compatibility for legacy persisted section/checkpoint identity
```

Required behavior:
- active flow emits `OnboardingSectionId.userProfile` for Profile basics;
- renderer maps `userProfile` to the existing `ProfileSection` widget;
- legacy `OnboardingSectionId.profile` remains readable/reconcilable for old drafts/checkpoints but is not emitted by the new active flow;
- existing `OnboardingStepId.profileBasics` remains stable unless evidence requires otherwise;
- Back/Next/progress semantics remain unchanged;
- no Profile UI redesign;
- no O3 `bodyGoal` activation;
- no persistence/schema changes.

## Acceptance

- [ ] active flow plan uses `OnboardingSectionId.userProfile` for `profileBasics`;
- [ ] renderer reuses existing `ProfileSection` for `userProfile`;
- [ ] legacy `profile` checkpoint resumes into the active Profile section safely;
- [ ] `profileBasics` persisted step compatibility is preserved;
- [ ] controller resume clamps/reconciles stale legacy section identity without losing Profile answers;
- [ ] progress denominator/order unchanged except identity label migration;
- [ ] no new screen or visual redesign;
- [ ] no O3/bodyGoal activation;
- [ ] focused flow/renderer/resume tests;
- [ ] Flutter analyze + Dart analyze + Flutter tests + Dart tests green on exact O2D checkpoint.

## Guardrails

- preserve Name/Gender/DOB/Units/Height/Activity/Health UI exactly;
- preserve DOB/Height picker contracts;
- Current Weight remains Body-owned;
- no applied migration edits or legacy-column drops;
- no owner semantics change in O2D;
- O2E integrated read/write/resume acceptance follows only after O2D validation;
- O3 must not start before O2E.

## Current work

**Audit the active flow definition, section renderer, persisted draft decoding and resume reconciliation; then activate `userProfile` with explicit legacy compatibility tests.**
