# Product Onboarding O3D — Integrated Canonical Body Acceptance

**Status:** In progress  
**Tracker:** GitHub Issue #57  
**Parent O3 tracker:** #55  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Predecessor:** #56 O3C ✅  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting checkpoint

O3C Goal Pace runtime ownership parity is validated:

```text
b47495e23f055c7d95eeccbca03b71c35aa38962
Flutter CI #1345 / run 32561257485
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Outcome

Prove the entire O3 canonical Body path end-to-end before O4 Wellness starts:

```text
Product Onboarding Body Goal draft
→ BodySetupMapper
→ BodySetupRepository / BodyRepository
→ canonical Body state
→ body_weight_logs + user_body_goals semantics
→ resume compatibility
→ completion/failure ordering
```

This is acceptance-first. Change production code only if the integrated harness exposes a real O3 gap.

## Canonical Body contract

```text
body_weight_logs → Current Weight/history
user_body_goals  → Body Goal + Target Weight + Goal Pace
user_profiles    → common Profile only
onboarding_drafts → orchestration/resume only
```

`TargetsOnboardingDraft.goalPaceKgPerWeek` remains a serialized compatibility value container during O3; it is not a durable Targets ownership declaration.

## Existing owner semantics to preserve

`BodySetupMapper`:
- maps only explicit Body intents;
- never converts training-only goals into Body goals;
- never infers direction from target/current numbers or BMI;
- consumes Target Weight only when stored direction matches the active explicit Body intent;
- consumes Goal Pace only for directional Body intents.

`BodyRepository`:
- `saveBodySetup` owns onboarding setup writes;
- `getBodyState` owns canonical readback;
- `recordCurrentWeight` owns post-onboarding history writes;
- `onboarding_setup` provenance is reserved for setup retry/reconciliation semantics.

`InMemoryBodySetupRepository` mirrors canonical lifecycle semantics for deterministic acceptance tests:
- one onboarding snapshot semantic;
- same goal type preserves starting weight / started-at;
- changed goal type starts a new active goal state;
- non-directional goals reject Target Weight/Pace.

`SupabaseBodySetupRepository` targets only:
- `body_weight_logs` for Current Weight/history;
- `user_body_goals` for active Body Goal state;
- no legacy Profile/Nutrition mirror writes.

## Required integrated acceptance

### A. Directional write/read round-trip

Use an explicit directional draft with:
- Current Weight;
- matching Target Weight direction/value;
- Goal Pace;
- primary/supporting rank as applicable.

Prove:
- mapper output is lossless;
- owner save succeeds;
- canonical read returns latest weight + active Body Goal + Target Weight + Goal Pace + rank;
- no numeric inference is involved.

### B. Non-directional and training-only safety

Prove:
- Maintain/Recomposition may persist a Body Goal but never dormant Target Weight/Pace;
- training-only Workout goal persists no Body Goal;
- Current Weight remains independently writable when present.

### C. Retry/lifecycle semantics

Prove:
- repeated onboarding save keeps one onboarding snapshot semantic;
- same Body goal retry preserves starting weight / started-at semantics;
- updating target/pace on same goal updates canonical active state without creating a competing goal;
- changing goal type replaces/supersedes previous active goal semantics rather than leaving two active owners.

### D. Product Onboarding completion failure ordering

Prove through the actual owner persistence/completion path:
- Body owner receives Body setup data once through the canonical boundary;
- Body persistence failure surfaces as Body owner failure;
- failure blocks confirmed App Mode publication and completed onboarding status;
- no Profile/Nutrition broad Body mirror path is invoked.

### E. O3C resume parity stays intact

Prove at minimum:
- active Body Goal Goal Pace cursor resumes under `bodyGoal`;
- legacy `targets + goalPace` cursor migrates without losing pace;
- later top-level checkpoint remains later when pace is dormant;
- active Targets flow stays pace-free.

## Acceptance

- [ ] directional Current Weight/Body Goal/Target/Pace maps losslessly;
- [ ] canonical Body read returns latest weight and active goal state;
- [ ] explicit intent, not numeric state, controls Body direction;
- [ ] Maintain/Recomposition never consume dormant Target Weight/Pace;
- [ ] training-only goals never fabricate a Body Goal;
- [ ] repeated onboarding save preserves one setup-weight snapshot semantic;
- [ ] same-goal retry preserves lifecycle semantics;
- [ ] changed goal does not leave competing active goal state;
- [ ] Body owner failure blocks App Mode/completion publication;
- [ ] no legacy Profile/Nutrition Body persistence is introduced;
- [ ] O3C Goal Pace runtime/resume behavior remains green;
- [ ] no applied migration, legacy-column drop, permanent dual-write, or UI redesign;
- [ ] Flutter analyze + Dart analyze + Flutter tests + Dart tests all green on one exact O3D source checkpoint.

## Guardrails

- no Body direction inference from measurements, BMI, or target delta;
- no fabricated semantic defaults;
- no `user_profiles` expansion into Body concepts;
- no Goal Pace return to active Targets;
- no permanent dual-write synchronization;
- no applied migration edits;
- no legacy-column drops; O11/#54 stays blocked until O10;
- no O4 source work until O3D exact full CI is green.

## Validation

Focused tests should exercise the real O3 boundaries rather than duplicating isolated mapper tests:

```text
BodySetupMapper
+ InMemoryBodySetupRepository / BodyRepository readback
+ PersistOnboardingOwnerDataUseCase or CompleteOnboardingUseCase failure ordering
+ O3C resume migration contract
```

Then require full workspace CI.

## Exit criteria

O3D is complete only when one exact source SHA has:

```text
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

and #57/#55/#40/#44/PR #50 plus `.ai` handoff files record that checkpoint. Only then may O4 Wellness become active.

## Current work

**Build the integrated O3 acceptance harness first; change production behavior only for a real exposed Body ownership/lifecycle/resume gap.**
