# Product Onboarding O7C — Android Health Connect Adapter

**Status:** Active — O7C1 availability probe in implementation; O7C2 authorization gated  
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

O7C task/tracker commits after this SHA do not replace the exact O7B runtime checkpoint.

## Goal

Establish a truthful Android Health Connect platform boundary behind O7B's existing `HealthConnectionGateway` contract without inventing health-data permissions or silently dropping supported Android devices.

## Verified starting evidence

- O7B already defines the feature-owned gateway/status contract and approved screen/orchestration behavior.
- `apps/app/pubspec.yaml` has no Health Connect/HealthKit package today.
- Android manifest has no Health Connect provider query and no health-data permissions at the O7B checkpoint.
- Current Flutter toolchain baseline resolves Android `minSdk` to API 24.
- Official Health Connect client SDK supports Android 8/API 26+, while usable Health Connect requires Android 9/API 28+ with Google Play services.
- Adding the official SDK/plugin directly would therefore force a whole-app minimum-SDK decision; O7C must not silently raise API 24 → 26 for an optional integration.
- Repository roadmap explicitly defers health permissions/wearable-data sync until the Recovery/data-source/privacy decision is approved.
- Health Connect authorization is data-type-specific; manifest/runtime/Play Console declarations must agree on exact product-used data types.
- Existing `Flutter CI` analyzes/tests Dart and Flutter packages but does not run an Android Gradle/APK build, so native Java/manifest changes require a separate Android build gate before O7C1 can be called platform-validated.

## O7C split

### O7C1 — platform availability probe (active)

Implement a dependency-free Android platform probe owned by `apps/app`:

```text
Android 14+ (API 34+) → framework Health Connect system-service presence
Android 9–13          → Health Connect provider/settings activity presence
Android < 9           → unavailable
managed/work profile  → unavailable
non-Android/test      → fail-safe unavailable
```

The probe may add only the package visibility query needed to inspect the Health Connect provider. It adds **no** `android.permission.health.*` declarations.

O7C1 is infrastructure only. It must not replace the O7B unavailable gateway in app composition if doing so would expose a user-facing `Connect` action that cannot yet perform a real authorization attempt.

### O7C2 — authorization adapter (gated)

Before wiring the real adapter into `healthConnectionGatewayProvider` and making `Connect` invoke the OS flow, resolve:

1. concrete product capability consuming Health Connect data;
2. canonical owner for imported/read records;
3. exact Health Connect record types;
4. read vs write scope per type;
5. Android minimum-SDK/dependency policy if the official client/plugin is required;
6. matching Play Console/privacy declaration;
7. full-grant/partial-grant/denied mapping tests.

Until O7C2 is approved/source-backed, `connected` remains unreachable.

## Architecture

```text
Product Onboarding
  HealthConnectionGateway
        ↑ (O7C2 only after scope gate)
apps/app platform composition
  AndroidHealthConnectGateway
        ↑
apps/app Android availability / authorization bridge
```

Rules:

- onboarding owns orchestration and the narrow gateway contract;
- `apps/app` owns Android/platform composition;
- imported health records do not belong to onboarding;
- durable connection metadata remains O7D;
- no sensitive platform state is serialized into `onboarding_drafts`.

## Status semantics

For an eventual fully wired adapter:

```text
Health Connect unavailable                     → unavailable
Provider missing/update required               → unavailable
SDK/provider available, permission not granted → notRequested/denied as proven
full approved permission set granted           → connected
```

Availability alone is never `connected`.

## Implementation plan

- [x] re-read root/feature workflow rules before source edits;
- [x] inspect existing app-level provider composition pattern;
- [x] reject silent whole-app minSdk 24 → 26 as an O7C1 side effect;
- [x] add dependency-free Android platform/provider availability probe;
- [x] add only Health Connect provider package visibility query;
- [x] add Dart app-layer availability probe with fail-safe parsing/error behavior;
- [x] add focused app-layer tests with mocked platform channel;
- [x] keep O7B production gateway fallback wired until authorization scope is real;
- [ ] add focused Android Native CI that compiles a debug APK for `apps/app/android/**` changes;
- [ ] pass full Flutter four-gate CI on one exact O7C1 source SHA;
- [ ] pass Android debug APK build on that same exact O7C1 source SHA;
- [ ] freeze O7C1 evidence without closing #78 if O7C2 remains gated;
- [ ] document exact health-data scope before any authorization/health permission source change.

## Validation contract

O7C1 is not platform-validated unless the same exact source SHA has both:

```text
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
Android debug APK/native compile ✅
```

A four-gate Flutter CI run alone is insufficient because it does not compile `MainActivity.java`, `HealthConnectAvailabilityBridge.java`, or the Android manifest.

## Out of scope

- unapproved health-data permissions;
- dead/no-op user-facing Connect wiring;
- silent app minSdk increase;
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

O7C1 exits with one exact source SHA that passes both the existing Flutter four-gate CI and an Android debug APK/native compile gate. #78 remains ACTIVE if authorization scope/minSdk policy is still unresolved; O7D does not start early. O7C fully exits only after a real, least-privilege authorization adapter is wired and validated, or the product explicitly narrows O7C to availability-only behavior.
