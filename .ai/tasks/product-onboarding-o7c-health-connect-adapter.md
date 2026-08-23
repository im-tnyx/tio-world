# Product Onboarding O7C — Android Health Connect Adapter

**Status:** O7C1 VALIDATED; O7C2 SDK readiness/authorization BLOCKED by #79  
**Tracker:** GitHub Issue #78  
**Health-data scope blocker:** #79  
**Parent O7:** #75  
**O7B runtime:** #77 ✅ / CI #1575  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Exact validated O7C1 checkpoint

```text
f95ddf7cef05e658566e5d9493efd6099edded76
Flutter CI #1593 / run 32611022666 / job 97124041663
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅

Android Native CI #5 / run 32611022667 / job 97124042275
Android debug APK/native compile ✅
```

Tracker/docs commits after this SHA do not replace exact O7C1 validation.

## O7C1 validated contract — surface presence only

O7C1 establishes the smallest truthful Android platform probe without health-data access:

```text
Android 14+            → framework Health Connect service surface present / absent
Android 9–13           → Health Connect provider settings surface present / absent
Android < 9            → absent
managed/work profile   → absent
non-Android/test       → fail-safe absent
```

This is deliberately **surface presence**, not Health Connect SDK readiness or authorization.

The first implementation used the word `available`; semantic review corrected that before freeze because provider/settings presence on Android 9–13 cannot prove the official client SDK is current/usable. Official Android guidance uses `HealthConnectClient.getSdkStatus()` to distinguish unavailable, provider-update-required and available states. That readiness check belongs in O7C2 after dependency/minSdk and permission scope are approved.

## Validated O7C1 implementation

- app-owned dependency-free Android platform channel/bridge;
- Android 14+ framework service presence probe;
- Android 9–13 provider/settings surface presence probe;
- Android < 9 and managed profile fail closed;
- non-Android/channel failures fail closed;
- manifest adds only Health Connect provider package visibility query;
- no `android.permission.health.*` declarations;
- no Health Connect record reads/writes;
- no app minSdk change;
- no health plugin/client dependency;
- production O7B `UnavailableHealthConnectionGateway` remains wired, so no dead/fake Connect path is exposed;
- focused Dart mocked-channel tests;
- dedicated Android Native CI now compiles the Java bridge/manifest through `flutter build apk --debug`.

## O7C2 — SDK readiness + authorization BLOCKED by #79

Before Product Onboarding `Connect` can invoke the real OS authorization flow, #79 must approve:

1. concrete product capability consuming Health Connect data;
2. exact Health Connect record types;
3. read vs write scope per type;
4. canonical owner for imported records/summaries;
5. retention/freshness/consent-withdrawal rules;
6. Android client dependency/minSdk policy;
7. exact `getSdkStatus()` mapping including provider-update-required;
8. matching Play Console/privacy declaration;
9. full/partial/denied permission tests.

Existing wellness values such as step/sleep **targets** are not imported health records and do not justify permissions.

Until #79 resolves the contract:

```text
surface present ≠ SDK ready
SDK ready        ≠ authorized
connected        → unreachable
```

## Guardrails

- no passive permission prompt;
- no fake `connected`;
- no broad health permissions for future use;
- no sensitive health-data logging;
- no health records in `onboarding_drafts`;
- no silent whole-app minSdk increase;
- no O7D/O7E implementation while O7C2 is blocked;
- PR #50 remains Draft/open/unmerged;
- O11 remains blocked until O10.

## Handoff

**O7C1 is frozen on `f95ddf7c...` with Flutter CI #1593 and Android Native CI #5 green. #78 remains open because O7C2 is blocked by product/data decision #79. Do not start O7D/O7E until #79 resolves the first least-privilege Health Connect data contract and O7C2 is implemented/validated.**
