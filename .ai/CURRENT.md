# Current State

Last verified from current branch/runtime trackers and exact CI evidence: 2026-08-23.

Runtime source remains behavior truth. Product Onboarding sequencing is owned by `.ai/tasks/product-onboarding-canonical-execution.md`.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o7c-health-connect-adapter.md`
4. GitHub Issues #79/#78/#75/#40/#44 and Draft PR #50
5. O7B predecessor acceptance: #77 / CI #1575

## Latest exact validated Product Onboarding / platform checkpoint

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

This freezes O7C1 Health Connect surface-presence infrastructure. Tracker/docs commits after this SHA do not replace exact runtime/platform validation.

## Current sequence

```text
O1 App Mode                                      ✅ #11 / CI #1240
O2 User Profile                                  ✅ #53 / CI #1279
O3 Body Goal                                     ✅ #55 / CI #1354
O4 Wellness                                      ✅ #58 / CI #1441
O5 Nutrition Profile + Targets                   ✅ #63 / CI #1507
O6 Workout Profile + Targets                     ✅ #69 / CI #1555
→ O7 Health Connections                          ACTIVE/BLOCKED #75
   O7A capability + product contract readiness   ✅ #76
   O7B runtime section + approved UI/content      ✅ #77 / CI #1575
   O7C Android Health Connect adapter             PARTIAL #78
      O7C1 surface-presence infrastructure        ✅ source f95ddf7c / CI #1593 + Native #5
      O7C2 SDK readiness + authorization          BLOCKED #79
   O7D persistence/resume/review integration      BLOCKED by O7C2
   O7E integrated acceptance                     BLOCKED
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                   BLOCKED #54
```

## O7B frozen runtime

Health Connections is active in every App Mode as:

```text
... → Nutrition Targets → Health Connections → Review
```

It is optional, non-blocking and retryable later. Only a real platform adapter may establish `connected`; passive entry never requests OS permission and live Health authorization state is not serialized into `OnboardingDraft`.

## O7C1 validated boundary

O7C1 detects only Android Health Connect **surface presence**:

```text
Android 14+            → framework Health Connect service surface
Android 9–13           → Health Connect provider/settings surface
Android < 9            → absent
managed profile        → absent
non-Android/failure    → absent
```

Surface presence is not SDK readiness and is never authorization. O7C1 adds no health-data permission, no record access, no Health Connect client dependency, no app minSdk change, and does not replace the production O7B unavailable gateway.

## O7C2 blocker — #79

No exact first imported Health Connect signal is approved yet. Existing step/sleep values are wellness **targets**, not evidence that Steps/Sleep records should be imported.

Before O7C2 source work, #79 must define:

- first user-visible product outcome;
- exact Health Connect record types;
- read/write scope;
- canonical imported-data owner;
- retention/freshness/consent withdrawal;
- Android client/minSdk policy;
- matching Play Console/privacy declaration.

Until then:

```text
surface present ≠ SDK ready
SDK ready        ≠ authorized
connected        → unreachable
```

## Guardrails

- no fake health connection success;
- no health permission without exact approved data types and explicit user action;
- no broad future-use permissions;
- no sensitive health-data duplication/logging;
- imported health records never belong in `onboarding_drafts`;
- do not start O7D/O7E while O7C2 is blocked;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.
