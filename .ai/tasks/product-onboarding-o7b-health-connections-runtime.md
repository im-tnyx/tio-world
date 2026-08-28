# Product Onboarding O7B — Health Connections Runtime

**Status:** Completed  
**Tracker:** GitHub Issue #77 ✅  
**Parent O7:** #75  
**O7A contract:** #76 ✅  
**Validated source:** `371fafb8cf8a27b6f7922733b071277accf4af98`  
**Validation:** Flutter CI #1575 / run 32607322748 / job 97114316589 ✅  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Exact validated checkpoint

```text
371fafb8cf8a27b6f7922733b071277accf4af98
Flutter CI #1575 / run 32607322748 / job 97114316589
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Completed product contract

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

Visible behavior:

```text
Title:      Connect health data
notRequested → Connect + Not now
denied       → Try again + Not now
unavailable  → Continue
connected    → Continue
```

## Completed architecture

`HealthConnectionGateway` + `HealthConnectionStatus` form the narrow onboarding/platform boundary.

The O7B default `UnavailableHealthConnectionGateway`:

- never requests OS permission;
- truthfully reports unavailable;
- never returns fake `connected`.

Live capability/authorization state remains outside `OnboardingDraft`. Existing orchestration fields (`currentStepId`, `completedStepIds`) provide the O7B resume checkpoint. Pre-O7B unfinished Review drafts without Health Connections completion reconcile through the new step.

## Completed implementation

- [x] add/export `HealthConnectionStatus`;
- [x] add/export `HealthConnectionGateway` + fail-safe unavailable implementation;
- [x] inject gateway through Riverpod composition with unavailable default;
- [x] add live status/connecting controller state without draft serialization;
- [x] add explicit request behavior with no automatic permission prompt;
- [x] add Health Connections section/screen + renderer;
- [x] add optional secondary action seam to `OnboardingBottomBar`;
- [x] schedule Health Connections after `nutritionGoals` and before `review` in all modes;
- [x] mark Health Connections non-blocking (`isRequired: false`);
- [x] add Health Connections progress item;
- [x] reconcile pre-O7B Review resume drafts;
- [x] correct Nutrition Target CTA from stale `Review` to `Continue`;
- [x] preserve Product Onboarding busy Back parity (visible but disabled; system Back blocked);
- [x] add focused domain/controller/widget/resume coverage;
- [x] pass full four-gate CI on exact source SHA.

## Deliberately not done

- Health Connect plugin/native adapter;
- Android health-data permissions;
- HealthKit/iOS;
- imported health/biometric record sync;
- durable connection metadata schema/owner;
- Supabase migration/RLS;
- O8+ work.

## Handoff

O7C #78 is active. It may wire truthful Android Health Connect availability/composition, but health-data permission requests remain gated until exact data types/use cases are source-backed. PR #50 remains Draft/open/unmerged and O11 remains blocked until O10.
