# Product Onboarding O7A — Health Connections Capability Contract

**Status:** Active / contract-ready  
**Tracker:** GitHub Issue #76  
**Parent O7:** #75  
**Validated predecessor O6:** #69 ✅ / CI #1555  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting validated checkpoint

```text
d56e8226f8631bc81d3dd309cbb22c631ca636f5
Flutter CI #1555 / run 32591048642
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O6 runtime/source checkpoint. This O7A file is contract/tracker context only and does not replace that checkpoint.

## 1. Discovery

### User outcome

Prepare Product Onboarding Health Connections so a later slice can safely offer platform health integration without claiming a connection that does not exist, coercing OS permissions, or coupling onboarding completion to unavailable platform support.

### Verified source evidence

- `OnboardingStepId.healthConnections` already exists.
- The matching `OnboardingSectionId.healthConnections` identity already exists.
- `BuildOnboardingFlowUseCase` does **not** schedule Health Connections in Workout, Nutrition, or Hybrid.
- `OnboardingCompatibilitySection` treats `healthConnections` as a guarded future step and throws if it becomes active accidentally.
- `OnboardingDraft` has no Health Connections payload/state.
- `apps/app/pubspec.yaml` has no Health Connect or HealthKit integration package.
- `apps/app/android/app/src/main/AndroidManifest.xml` has no Health Connect health-data permission/configuration.
- The current `apps/app` tree on this branch has no iOS Runner scaffold, so HealthKit cannot be wired honestly in the current phone-app tree.
- Existing Product Onboarding visual guardrails require explicit approval before activating a new visible screen/content contract.

### Consequence

O7A must be non-visual and permission-side-effect free. Runtime activation before a platform/product contract exists would either crash through the future-step guard or force fabricated behavior.

## 2. Capability vocabulary proposal

This is a **contract proposal**, not a production enum in O7A.

Minimum product-safe states:

```text
unavailable
  Platform/app cannot offer the health connection capability.
  Must never be presented as connected or denied.

notRequested
  Capability is available, but the app has not requested authorization.
  No OS prompt has been triggered yet.

denied
  User/platform did not grant the required authorization.
  Must remain distinguishable from unavailable and from an intentional skip.

connected
  The platform adapter has confirmed the required authorization/capability.
  This is the only state that may be rendered/persisted as connected.
```

Potential platform-specific states such as partial/restricted must **not** be added to Product Onboarding until the real adapter proves they are needed. Do not normalize an unknown/partial platform result into `connected`.

## 3. User-choice vocabulary

Connection capability and onboarding choice are different concepts.

A later draft contract may need an orchestration-only choice such as:

```text
notDecided
skip
attemptConnection
```

O7A does not add this to `OnboardingDraft`; names/shape remain subject to O7B/O7D implementation evidence. A stored onboarding choice must never become authoritative OS authorization state.

## 4. Ownership proposal

### Product Onboarding

Owns only orchestration:

- whether the Health Connections step is active;
- whether the user chose to skip or attempt connection;
- resume/checkpoint state needed to return to the onboarding screen.

If later persisted in `onboarding_drafts`, this remains orchestration state only.

### Platform health adapter

Owns live device capability and authorization truth:

```text
platform availability
current authorization/result
request authorization action
```

The adapter must not be implemented inside a widget. App/platform composition provides it to the onboarding feature through a narrow contract.

### Durable device/account state

**Unresolved until O7D.** Do not automatically assign Health Connect/HealthKit authorization to `user_devices` merely because that table exists. If durable per-device connection metadata is needed, O7D must prove the correct owner and data shape first.

### Imported health / biometric records

Do not store imported records in `onboarding_drafts` or connection-status metadata. Imported health data belongs to a dedicated health/sync domain when that vertical slice exists, with explicit sensitive-data access controls.

## 5. Completion / skip / retry decision table

| Situation | Safe O7A interpretation | Completion behavior |
| --- | --- | --- |
| capability unavailable | no connection can be offered | **Product decision unresolved**; implementation must not fabricate connected state |
| capability available, not requested | no permission side effect yet | no automatic OS prompt |
| user explicitly skips | onboarding choice only, not denial | **Product decision unresolved**; recommended non-blocking, requires approval before O7B |
| user attempts and denies | adapter reports denied | **Product decision unresolved**; recommended retryable/non-blocking, requires approval before O7B |
| user connects | adapter confirms connected | may show connected only from confirmed adapter result |
| transient/platform error | connection result unknown/not confirmed | stay retryable; never coerce to connected |

### Recommendation requiring product confirmation

Health Connections should normally be **optional/non-blocking** for Product Onboarding because OS capability may be unavailable and authorization may be denied. This is an architecture/product recommendation only; O7B must not encode it until product behavior is explicitly approved.

## 6. Permission safety contract

- Never request Health Connect/HealthKit permission on app launch, flow construction, renderer construction, resume, or passive screen entry.
- Permission request must occur only from an explicit user action in a later approved screen.
- A rejected/cancelled platform prompt is not an app error and must remain retryable.
- Do not repeatedly prompt after denial without another explicit user action.
- Do not log permission payloads, health values, tokens, or private biometric data.

## 7. Platform boundary

### Android

Later O7C may introduce a Health Connect adapter only after selecting the actual supported Flutter/native integration and reviewing required Android permissions/manifest declarations. O7A adds none.

### iOS

The current `apps/app` tree has no iOS Runner scaffold. O7 must not claim HealthKit parity in this branch. HealthKit work requires the phone iOS target/scaffold to exist first; its adapter should conform to the same platform-neutral contract when available.

## 8. O7B prerequisites

Before activating `OnboardingStepId.healthConnections` in `BuildOnboardingFlowUseCase`:

- [ ] product confirms whether skip/denial/unavailable are completion-blocking or non-blocking;
- [ ] visible screen content/actions/options are approved;
- [ ] existing onboarding design-system/visual guardrail is satisfied for the new screen;
- [ ] exact placement relative to Nutrition Targets / Review is confirmed;
- [ ] platform-unavailable presentation is defined;
- [ ] explicit Connect action semantics are defined;
- [ ] draft/resume choice shape is decided if needed;
- [ ] renderer has a real Health Connections section before planner activation.

Do not schedule the step first and rely on the compatibility future-step failure.

## 9. O7C prerequisites

Before adding Health Connect runtime permission wiring:

- [ ] actual integration package/native approach selected from current supported tooling;
- [ ] required Android manifest permissions/configuration reviewed;
- [ ] adapter tests cover unavailable/notRequested/denied/connected;
- [ ] permission request is explicit-action only;
- [ ] imported health record scope is separately defined and not conflated with connection status.

## 10. Scope / non-goals

### In scope

- source-grounded capability/status proposal;
- ownership boundary;
- completion/skip/retry decision table;
- platform readiness evidence;
- prerequisites for O7B/O7C/O7D.

### Out of scope

- production Dart model/API changes;
- flow scheduling;
- UI/screen/copy/options;
- Flutter health plugin dependency;
- Android Health Connect permissions;
- HealthKit implementation;
- Supabase schema/migration/RLS changes;
- imported health-data sync.

## 11. Acceptance

- [x] current source/platform readiness documented accurately;
- [x] unavailable / notRequested / denied / connected are distinguished without fabricated success;
- [x] onboarding orchestration is separated from live platform authorization truth;
- [x] durable connection-state ownership remains unresolved instead of being guessed;
- [x] imported sensitive health data is explicitly outside onboarding draft ownership;
- [x] completion/skip/retry behavior is documented with unresolved product decisions marked;
- [x] O7B prerequisites require visible behavior/design approval before runtime activation;
- [x] no production source/UI/plugin/manifest/schema change occurs in O7A.

## Handoff

O7A contract is ready for tracker freeze after repository synchronization. O7B remains blocked on the explicit product decisions listed above. O11/#54 remains blocked until O10, and PR #50 remains Draft/open/unmerged.
