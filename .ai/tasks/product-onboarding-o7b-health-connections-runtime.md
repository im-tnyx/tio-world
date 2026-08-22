# Product Onboarding O7B — Health Connections Runtime

**Status:** Active  
**Tracker:** GitHub Issue #77  
**Parent O7:** #75  
**O7A contract:** #76 ✅  
**Validated predecessor O6:** #69 ✅ / CI #1555  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting runtime checkpoint

```text
d56e8226f8631bc81d3dd309cbb22c631ca636f5
Flutter CI #1555 / run 32591048642
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O7A/docs commits after this SHA do not replace the exact runtime checkpoint.

## Approved product contract

The user approved O7A's recommended behavior:

```text
Health Connections = optional / non-blocking / retryable later
Placement           = Nutrition Targets → Health Connections → Review
```

Outcomes:

```text
Not now / skip           → continue onboarding
Platform unavailable     → continue onboarding
Permission denied/cancel → continue onboarding; retry later
Connected                → only from a real platform adapter result
```

Approved visible behavior:

```text
Title:      Connect health data
Primary:    Connect
Secondary:  Not now
```

State-specific behavior may change the primary action after an attempted/read result:

- `notRequested` → Connect + Not now;
- `denied` → Try again + Not now;
- `unavailable` → Continue;
- `connected` → Continue.

No platform branding is shown in O7B because no real platform adapter is active yet.

## Verified codebase evidence

- `OnboardingStepId.healthConnections` and `OnboardingSectionId.healthConnections` already exist.
- `BuildOnboardingFlowUseCase` currently does not schedule the step.
- `OnboardingSectionRenderer` currently throws for the future Health Connections section.
- `BuildOnboardingProgressPlanUseCase` and `OnboardingProgressPlan` currently throw for the future step.
- `OnboardingDraft` has no Health Connections payload.
- `apps/app/pubspec.yaml` has no Health Connect/HealthKit plugin.
- Android manifest has no Health Connect health-data permission wiring.
- Current phone app tree has no iOS Runner scaffold.
- `OnboardingBottomBar` already owns fixed Product Onboarding actions and uses reusable `TioButton` variants.
- Existing visual rules require `package:tio_core/core.dart`, `TioScreenHeader`, runtime semantic colors and governed spacing/components.

## Architecture decisions

### Live connection truth

Introduce a narrow onboarding-domain gateway contract:

```text
HealthConnectionGateway
  readStatus()
  requestConnection()

HealthConnectionStatus
  unavailable
  notRequested
  denied
  connected
```

The default O7B implementation is `UnavailableHealthConnectionGateway`; it never requests OS permission and never returns `connected`.

O7C will replace/override this boundary with a real Android Health Connect adapter.

### State ownership

`OnboardingState` may hold the current live `HealthConnectionStatus` and a transient connecting flag. This live platform state is **not** serialized into `OnboardingDraft` in O7B.

### Resume ownership

No new Health Connections draft payload is required in O7B. Existing orchestration fields are sufficient:

```text
currentStepId
completedStepIds
```

Pre-O7B unfinished drafts already parked at `review` without `healthConnections` completion must reconcile forward to `healthConnections` so the newly approved step is not silently bypassed. Once Health Connections is passed, `completedStepIds` prevents that compatibility redirect.

O7D may later add durable connection metadata only after proving its canonical owner.

## UI approach

Add one feature-owned Health Connections section/screen using existing Product Onboarding composition:

- `TioScreenHeader`;
- governed `context.tioColors` and `Theme.of(context).textTheme`;
- existing `TioButton` through `OnboardingBottomBar`;
- no feature token bag;
- no new core component contract;
- no platform brand icon/copy until a real adapter exists.

`OnboardingBottomBar` gets an optional secondary action seam used only when Health Connections offers `Not now`; all existing screens preserve their current single-primary rendering.

## Implementation plan

- [ ] add/export `HealthConnectionStatus`;
- [ ] add/export `HealthConnectionGateway` + fail-safe unavailable implementation;
- [ ] inject gateway through the existing Riverpod controller composition with unavailable default;
- [ ] add live Health status/connecting state to `OnboardingState` without draft serialization;
- [ ] add controller read/request behavior; no automatic permission prompt;
- [ ] add Health Connections section and screen before planner activation;
- [ ] add optional secondary action support to `OnboardingBottomBar` without changing existing screens;
- [ ] schedule Health Connections after `nutritionGoals` and before `review` in Workout/Nutrition/Hybrid;
- [ ] mark Health Connections definition `isRequired: false` to encode non-blocking product semantics;
- [ ] add one Health Connections progress item and activate progress lookup;
- [ ] reconcile pre-O7B Review resume drafts to Health Connections when the step was never completed;
- [ ] add focused domain/controller/widget/resume tests;
- [ ] run full Flutter CI four-gate validation on one exact source SHA.

## Out of scope

- Health Connect plugin/native code;
- Android health permissions/manifest mutation;
- HealthKit/iOS implementation;
- imported health/biometric record sync;
- durable connection metadata schema/owner;
- Supabase migration/RLS;
- broad Review redesign;
- O8/O9/O10/O11 work.

## Guardrails

- no passive permission request;
- no fake `connected` state;
- no sensitive health-data logging or draft duplication;
- no schema/applied migration edit;
- preserve all unrelated Product Onboarding visuals/copy/field behavior;
- PR #50 remains Draft/open/unmerged;
- O11 remains blocked until O10.

## Exit

Freeze exact O7B source SHA + four-gate CI, close #77, update #75/#40/#44/#50 + durable trackers, then activate the next O7 slice only after its prerequisites are satisfied.