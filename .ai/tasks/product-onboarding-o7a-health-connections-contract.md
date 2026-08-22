# Product Onboarding O7A — Health Connections Capability Contract

**Status:** Completed / frozen  
**Tracker:** #76 ✅  
**Parent O7:** #75 ACTIVE  
**Successor O7B:** #77 PLANNED / BLOCKED  
**Validated predecessor O6:** #69 ✅ / CI #1555  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**PR:** #50 Draft/open/unmerged

## Frozen runtime checkpoint

```text
d56e8226f8631bc81d3dd309cbb22c631ca636f5
Flutter CI #1555 / run 32591048642
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O7A changed contract/tracker context only; it does not replace this exact runtime checkpoint.

## Verified readiness

- `OnboardingStepId.healthConnections` and matching section identity exist.
- `BuildOnboardingFlowUseCase` does not schedule Health Connections.
- `OnboardingCompatibilitySection` intentionally rejects it as a future step.
- `OnboardingDraft` has no Health Connections state.
- `apps/app/pubspec.yaml` has no Health Connect/HealthKit integration package.
- Android manifest has no Health Connect health-data permission/configuration.
- Current `apps/app` tree has no iOS Runner scaffold, so HealthKit parity cannot be claimed in this branch.

## Frozen capability proposal

This is the minimum product-safe vocabulary; O7A did not add a runtime enum:

```text
unavailable
notRequested
denied
connected
```

Only a real platform adapter result may establish `connected`. Unknown/partial platform results must never be normalized into connected without a proven adapter contract.

## Frozen ownership boundary

```text
Product Onboarding
  → orchestration only: step eligibility, skip/attempt choice, resume checkpoint

Platform health adapter
  → live device capability + authorization truth

Durable per-device connection metadata
  → unresolved until O7D proves the correct owner

Imported health / biometric records
  → dedicated future health/sync domain; never onboarding_drafts
```

`user_devices` is not automatically declared the Health Connect/HealthKit authorization owner merely because it exists.

## Permission safety

- no OS health permission on app launch, flow build, passive screen entry or resume;
- permission request only after explicit user action in a later approved screen;
- denial/cancel remains retryable and is not an app error;
- no repeated prompt without another explicit user action;
- no sensitive health values, tokens or permission payloads in logs.

## Completion / skip / retry

Architecture recommendation: Health Connections should be optional/non-blocking because platform support may be unavailable and permission may be denied. This recommendation is **not implemented** until product approval.

Unresolved product decisions are intentionally not guessed:

1. whether Skip, unavailable and denied/cancelled allow onboarding completion;
2. exact visible Health Connections screen/content/actions;
3. exact placement in the flow.

Recommended placement for approval: `Nutrition Targets → Health Connections → Review` in all App Modes because Health Connections is cross-mode/device integration.

## O7B blockers — #77

Before activating `healthConnections`:

- [ ] completion behavior approved;
- [ ] title/copy/actions and Connect/Skip behavior approved;
- [ ] connected/unavailable/denied/retry presentation approved;
- [ ] flow placement approved;
- [ ] design-system/visual guardrail satisfied;
- [ ] real Health Connections renderer/section exists before planner scheduling;
- [ ] any draft/resume orchestration shape is explicitly decided.

## O7C blockers

Before Android Health Connect permission wiring:

- [ ] actual supported integration approach selected;
- [ ] Android manifest permissions/config reviewed;
- [ ] adapter tests cover unavailable/notRequested/denied/connected;
- [ ] explicit-action-only permission request enforced;
- [ ] imported health-record scope remains separate from connection status.

## Acceptance

- [x] source/platform readiness documented accurately;
- [x] safe capability vocabulary defined without fabricated success;
- [x] onboarding orchestration separated from live platform authorization;
- [x] durable connection owner left unresolved instead of guessed;
- [x] sensitive imported health data excluded from onboarding draft ownership;
- [x] completion/skip/retry decisions documented with unresolved product decisions marked;
- [x] no production runtime/UI/plugin/manifest/schema change occurred.

## Handoff

O7A #76 is complete. O7B #77 remains blocked until the explicit approvals above are provided. Do not start O7C/O7D/O7E early. O11 remains blocked until O10 and PR #50 stays Draft/open/unmerged.
