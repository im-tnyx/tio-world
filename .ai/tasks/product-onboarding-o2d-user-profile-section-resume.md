# Product Onboarding O2D — `userProfile` Section + Resume Compatibility

**Status:** Validated  
**Tracker:** GitHub Issue #53  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Validated checkpoint

```text
6843a14b89f0c0bb7d62b1466eb3855ddbef0f64
Flutter CI #1275 / run 32555015103
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Outcome

The existing Profile onboarding UI now uses the prepared `OnboardingSectionId.userProfile` identity without changing its persisted top-level step id or visual contract. Old persisted `profileBasics` snapshots resume through the new active section while retaining Profile answers and nested Profile step state.

## Validated behavior

```text
persisted top-level identity: OnboardingStepId.profileBasics   unchanged
active section identity:      OnboardingSectionId.userProfile
active renderer:              existing ProfileSection
legacy renderer identity:     OnboardingSectionId.profile remains supported
```

Persisted onboarding snapshots do not serialize section identity. They serialize the stable top-level `current_step_id`, completed step ids and nested Profile draft/step data. Therefore O2D required no draft schema/version bump.

### Active flow
- `BuildOnboardingFlowUseCase` emits `userProfile` for `profileBasics`;
- new active plans no longer emit legacy `profile`;
- Back/Next/progress ordering and stable step IDs are unchanged.

### Renderer compatibility
- `OnboardingSectionRenderer` maps both active `userProfile` and legacy `profile` to the existing `ProfileSection`;
- `ProfileSection` keeps its strict `profileBasics` guard and accepts only those two Profile section identities;
- no router or visual redesign was required.

### Resume compatibility
A serialized legacy schema-v4 snapshot with `current_step_id: profileBasics` restores into active `userProfile` and preserves:
- common Profile answers;
- nested `ProfileStepId`;
- canonical metric values;
- stable top-level resume location.

## CI learning / corrections

O2D intentionally remained unvalidated through two intermediate failures:

1. CI #1273: analyze gates passed, but app router regressions exposed that `ProfileSection` still enforced the legacy-only `profile` section guard. Fixed by allowing exactly `profile` or `userProfile` while retaining the `profileBasics` guard.
2. CI #1274: analyze gates passed and the router regressions/new O2D migration tests passed; one legacy controller test still expected the old active `profile` identity. The assertion was updated to the canonical `userProfile` identity.
3. CI #1275: exact final O2D source passed the complete Flutter/Dart analyze and test suite.

## Acceptance

- [x] active flow plan uses `OnboardingSectionId.userProfile` for `profileBasics`;
- [x] renderer reuses existing `ProfileSection` for `userProfile`;
- [x] legacy `profile` states remain renderable for compatibility;
- [x] `profileBasics` persisted step compatibility is preserved;
- [x] serialized legacy checkpoint resumes without losing Profile answers/nested step;
- [x] progress denominator/order remains unchanged apart from section identity;
- [x] no new screen or visual redesign;
- [x] no persistence/schema changes;
- [x] no O3/bodyGoal activation;
- [x] focused flow/renderer/resume tests;
- [x] Flutter analyze + Dart analyze + Flutter tests + Dart tests green on exact O2D checkpoint.

## Scope proof

O2D did not change:
- canonical Profile persistence semantics validated in O2C;
- Body/Goal owner semantics;
- database schema/RLS/migrations;
- app router behavior;
- Profile visual design;
- O3 `bodyGoal` activation.

## Handoff

**O2D is validated. Start O2E integrated canonical Profile read/write/resume acceptance only. O3 remains blocked until O2E validates the complete O2 slice.**
