# Product Onboarding O3 — Canonical Body Goal Section

**Status:** In progress — O3A/O3B/O3C validated; O3D integrated Body acceptance ACTIVE  
**Tracker:** GitHub Issue #55  
**O3C:** #56 ✅ closed  
**O3D:** #57 ACTIVE  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Predecessor:** #53 O2 common User Profile ✅  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Validated foundation

O2 final:
```text
7e7119aa4dfe9cb53b1078376aa93e950f987adb
Flutter CI #1279 / run 32555540391 ✅
```

O3A typed Body Goal child-flow contract:
```text
4878ebc0045be9c3d6921aafffcf9f4791df0fd9
Flutter CI #1290 / run 32556313431 ✅
```

O3B runtime `bodyGoal` section + legacy resume:
```text
3df7dbd61a57340f7d6f767361d3ceaa49cc83fb
Flutter CI #1319 / run 32558694870 ✅
```

O3C Goal Pace placement/parity:
```text
b47495e23f055c7d95eeccbca03b71c35aa38962
Flutter CI #1345 / run 32561257485
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Outcome

Give Body Goal its own Product Onboarding section and prove one canonical Body owner across runtime navigation, persistence, readback, retry, resume and completion failure ordering.

Canonical ownership:

```text
body_weight_logs  → Current Weight / history
user_body_goals   → Body Goal + Target Weight + Goal Pace
user_profiles     → common Profile only
```

No new durable owner is introduced by O3.

## Existing compatibility containers

During O3 the serialized draft remains readable through established fields:

```text
OnboardingDraft.goalSelection
ProfileOnboardingDraft.currentWeightKg
ProfileOnboardingDraft.targetWeightKg
ProfileOnboardingDraft.targetWeightDirection
TargetsOnboardingDraft.goalPaceKgPerWeek
```

These are migration-safe draft containers, not durable ownership declarations.

## Execution

```text
O3A typed Body Goal child-flow contract                         ✅ CI #1290
O3B activate bodyGoal top-level section + renderer/navigation   ✅ CI #1319
O3C Goal Pace placement + Profile/Body separation parity        ✅ #56 / CI #1345
→ O3D integrated canonical Body read/write/resume + full CI     ACTIVE #57
```

Only one O3 sub-slice is active at a time.

## Established runtime boundary

```text
userProfile
  name
  gender
  age
  measurementUnits
  height
  activity
  healthConditions

bodyGoal
  Goal
  → Current Weight
  → Target Weight?  ← GoalWeightFollowUpPolicy
  → Goal Pace?      ← same eligibility
```

When directional follow-ups are ineligible, Body Goal stops after Current Weight.

Active Targets is now:

```text
Bridge → Step Target → Sleep Target → Water Target → Nutrition Target
```

## O3D — ACTIVE #57

Focused task: `.ai/tasks/product-onboarding-o3d-integrated-body-acceptance.md`.

O3D must prove:
- Body draft → `BodySetupMapper` → canonical Body owner losslessly;
- Current Weight canonical read/write/history semantics;
- Body Goal/Target Weight/Goal Pace canonical active-goal semantics;
- same-goal retry and changed-goal lifecycle behavior;
- non-directional/training-only safety;
- Body persistence failure blocks false mode/completion publication;
- O3C resume compatibility remains green;
- full Flutter/Dart CI green on one exact O3D source checkpoint.

## O3 acceptance

- [x] Body Goal child-flow contract validated;
- [x] active top-level Product Onboarding flow uses `bodyGoal` after `userProfile`;
- [x] common `userProfile` no longer semantically owns Goal/Current Weight/Target Weight/Goal Pace;
- [x] existing Goal/current/target/pace screens are reused without redesign;
- [x] Goal Pace renders/navigates under Body Goal with shared eligibility;
- [x] active Targets flow no longer semantically owns Goal Pace;
- [x] legacy mixed Body/Goal Pace resume compatibility validated;
- [x] O3C exact full CI green;
- [ ] integrated Current Weight canonical read/write/retry acceptance green;
- [ ] integrated Body Goal/Target/Pace canonical read/write/retry acceptance green;
- [ ] integrated completion failure ordering green;
- [ ] O3 final exact full-CI checkpoint recorded;
- [ ] O4 remains blocked until O3D.

## Guardrails

- no legacy-column drops; #54/O11 remains blocked until O10;
- no applied migration edits;
- no permanent dual-write synchronization;
- no Profile owner expansion into Body concepts;
- no UI redesign;
- preserve existing picker/unit contracts;
- no Body direction inference from measurements/BMI/training-only goals;
- do not activate Wellness/Nutrition/Workout future sections during O3.

## Current work

**Execute O3D on #57 from exact green O3C checkpoint `b47495e…` / CI #1345. O4 remains blocked.**
