# Product Onboarding O7C — Android Health Connect Adapter

**Status:** Active  
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

This O7C task/tracker commit is documentation only and does not replace the exact O7B runtime checkpoint above.

## Goal

Wire a truthful Android Health Connect platform-availability adapter behind O7B's existing `HealthConnectionGateway` boundary while preserving least privilege and the approved Product Onboarding behavior.

O7C must not invent a health-data permission scope simply to make the UI say `connected`.

## Verified starting evidence

- O7B already defines the feature-owned gateway/status contract and approved screen/orchestration behavior.
- `apps/app/pubspec.yaml` has no Health Connect/HealthKit package today.
- `apps/app/android/app/src/main/AndroidManifest.xml` has no Health Connect provider query and no health-data permissions today.
- Android app composition is Flutter + Riverpod; `apps/app` should remain thin.
- Current CI uses Flutter 3.47.1 / Dart 3.13.1.
- Repository roadmap explicitly defers health permissions/wearable-data sync until the Recovery/data-source/privacy decision is approved.
- Android Health Connect authorization is data-type-specific; manifest/runtime/Play Console declarations must agree on the exact types used by the product.

## Architecture

```text
Product Onboarding
  HealthConnectionGateway
        ↑
apps/app platform composition
  AndroidHealthConnectGateway
        ↑
Health Connect platform/plugin boundary
```

Rules:

- onboarding owns orchestration and the narrow gateway contract;
- app/platform composition owns Android/plugin wiring;
- imported health records do not belong to onboarding;
- durable connection metadata remains O7D;
- no sensitive platform state is serialized into `onboarding_drafts`.

## Status mapping before permission-scope approval

```text
Health Connect unavailable                    → unavailable
Provider missing/update required              → unavailable
SDK/provider available, scope not authorized  → notRequested
connected                                     → impossible to claim
```

A real `connected` result becomes legal only after O7C has an approved exact data-type permission set and the platform confirms that full required set is granted.

## Permission-scope gate

Before adding any `android.permission.health.*` declaration or runtime authorization request:

1. identify the concrete product capability that consumes the data;
2. identify the canonical owner for imported/read data;
3. list the exact Health Connect record types required;
4. choose read vs write separately for each type;
5. confirm the same set can be declared in Play Console/privacy disclosures;
6. add tests proving partial/denied grants never become `connected`.

Do not use a broad convenience list such as steps + sleep + weight + heart rate unless those types are independently source-backed and approved.

## Implementation plan

- [ ] re-read root/feature/app rules before source edits;
- [ ] inspect existing app-level platform/provider composition patterns;
- [ ] choose the maintained Health Connect integration boundary compatible with the repo toolchain;
- [ ] add Android SDK/provider availability detection;
- [ ] add only provider-query/config required for availability detection;
- [ ] inject the real Android adapter into `healthConnectionGatewayProvider` from app composition;
- [ ] preserve the unavailable fallback on unsupported/non-Android environments;
- [ ] prove passive Health Connections entry does not launch authorization;
- [ ] prove user `Connect` cannot fabricate success while permission scope is gated;
- [ ] document exact permission-scope evidence before adding any health-data permissions;
- [ ] add focused adapter/provider/widget tests;
- [ ] run full four-gate CI on one exact source SHA.

## Out of scope

- unapproved health-data permissions;
- health record import/sync/storage;
- background reads;
- HealthKit/iOS;
- Recovery feature implementation;
- Supabase schema/RLS for health connections;
- durable connection metadata — O7D;
- O8/O9/O10/O11 work.

## Guardrails

- no permission prompt on passive entry;
- no fake `connected`;
- no sensitive health data logging;
- no applied migration edits;
- no broad permission request for future use;
- preserve O7B UI/flow semantics;
- PR #50 remains Draft/open/unmerged;
- O11 remains blocked until O10.

## Exit

Freeze exact O7C source SHA + four-gate CI for the Android platform availability adapter and permission boundary. If no exact health-data scope is approved, permission request remains intentionally gated and `connected` remains unreachable rather than fabricated.
