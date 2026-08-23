# Product Onboarding O7C — Android Health Connect Adapter

**Status:** Active — O7C1 surface-presence probe in validation; O7C2 authorization gated  
**Tracker:** GitHub Issue #78  
**Parent O7:** #75  
**O7B runtime:** #77 ✅ / CI #1575  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting exact runtime checkpoint

```text
371fafb8cf8a27b6f7922733b071277accf4af98
Flutter CI #1575 / run 32607322748 / job 97114316589
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Goal

Establish the smallest truthful Android Health Connect platform boundary behind O7B without inventing health-data permissions, authorization state, or a whole-app minimum-SDK change.

## Verified evidence

- O7B already defines the feature-owned `HealthConnectionGateway` / `HealthConnectionStatus` contract.
- The app baseline resolves Android `minSdk` to API 24.
- The official Health Connect client SDK supports API 26+, while usable Health Connect is Android 9/API 28+.
- Official Android guidance uses `HealthConnectClient.getSdkStatus()` to distinguish unavailable, provider-update-required and available states.
- A dependency-free package/settings/service probe cannot prove the same SDK-readiness contract; on Android 9–13, provider surface presence does not prove that the provider is current enough for the client SDK.
- Health Connect permissions are tied to exact product-used data types and matching Play Console declarations.
- Repository Recovery/product docs do not yet approve the first imported health signal or its owner.

## O7C split

### O7C1 — platform surface presence

Dependency-free app-owned probe:

```text
Android 14+            → framework Health Connect service surface present / absent
Android 9–13           → Health Connect provider settings surface present / absent
Android < 9            → absent
managed/work profile   → absent
non-Android/test       → fail-safe absent
```

This is deliberately **presence**, not SDK readiness or authorization.

O7C1:

- may add only provider package visibility needed for the probe;
- adds no `android.permission.health.*` declarations;
- reads/writes no health records;
- does not map surface presence to `connected`;
- does not replace the O7B unavailable gateway in production composition.

### O7C2 — SDK readiness + authorization (gated)

Before wiring Product Onboarding `Connect` to a real Android adapter, resolve:

1. concrete product capability consuming Health Connect data;
2. canonical owner for imported/read records;
3. exact Health Connect record types;
4. read vs write scope per type;
5. Android dependency/minSdk policy for the official client SDK;
6. exact `getSdkStatus()` mapping including provider-update-required;
7. matching Play Console/privacy declaration;
8. full-grant/partial-grant/denied tests.

Until O7C2 is approved/source-backed, `connected` remains unreachable.

## Validation contract for O7C1

One exact source SHA must pass:

```text
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
Android debug APK/native compile ✅
```

The Android build gate is required because the normal Flutter four-gate workflow does not compile the Java bridge or manifest.

## Current implementation checklist

- [x] re-read root/feature workflow rules;
- [x] inspect app-level composition;
- [x] reject silent minSdk 24 → 26 change;
- [x] add dependency-free Android surface-presence bridge;
- [x] add only Health Connect provider package visibility query;
- [x] add fail-closed Dart bridge + mocked channel tests;
- [x] keep O7B production gateway fallback wired;
- [x] add focused Android Native CI debug APK build;
- [x] identify and correct readiness-overclaim before final freeze;
- [ ] pass Flutter four-gate CI on the corrected exact SHA;
- [ ] pass Android Native CI on the same corrected exact SHA;
- [ ] freeze O7C1 evidence;
- [ ] resolve first health-data scope before O7C2 source work.

## Out of scope

- SDK-readiness claims from package/settings presence;
- unapproved health-data permissions;
- dead/no-op user-facing Connect wiring;
- silent app minSdk increase;
- health record import/sync/storage;
- background health reads;
- HealthKit/iOS;
- Recovery feature implementation;
- Supabase schema/RLS for health connections;
- durable connection metadata — O7D;
- O8/O9/O10/O11 work.

## Guardrails

- no passive permission prompt;
- no fake `connected`;
- no broad future-use health permissions;
- no sensitive health-data logging;
- no applied migration edits;
- preserve O7B UI/flow semantics;
- PR #50 remains Draft/open/unmerged;
- O11 remains blocked until O10.

## Exit

O7C1 exits when the corrected surface-presence implementation passes both Flutter four-gate CI and Android debug APK/native compile on one exact SHA. #78 remains open while O7C2 is gated. O7D does not start early.