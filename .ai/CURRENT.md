# Current State

Last verified from current branch/runtime trackers and exact CI evidence: 2026-08-23.

Runtime source remains behavior truth. Product Onboarding sequencing is owned by `.ai/tasks/product-onboarding-canonical-execution.md`.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o7c-health-connect-adapter.md`
4. GitHub Issues #78/#75/#40/#44 and Draft PR #50
5. O7B predecessor acceptance: #77 / CI #1575

## Latest exact validated Product Onboarding checkpoint

```text
371fafb8cf8a27b6f7922733b071277accf4af98
Flutter CI #1575 / run 32607322748 / job 97114316589
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O7B runtime/source checkpoint. O7C task/tracker commits after this SHA do not replace exact runtime validation.

## Current sequence

```text
O1 App Mode                                      ✅ #11 / CI #1240
O2 User Profile                                  ✅ #53 / CI #1279
O3 Body Goal                                     ✅ #55 / CI #1354
O4 Wellness                                      ✅ #58 / CI #1441
O5 Nutrition Profile + Targets                   ✅ #63 / CI #1507
O6 Workout Profile + Targets                     ✅ #69 / CI #1555
→ O7 Health Connections                          ACTIVE #75
   O7A capability + product contract readiness   ✅ #76
   O7B runtime section + approved UI/content      ✅ #77 / CI #1575
   → O7C Android Health Connect adapter           ACTIVE #78
   O7D persistence/resume/review integration
   O7E integrated acceptance
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

It is optional, non-blocking and retryable later. Live status values are:

```text
unavailable
notRequested
denied
connected
```

Only a real platform adapter may establish `connected`. O7B's fallback is truthfully unavailable, passive entry never requests OS permission, and live Health authorization state is not serialized into `OnboardingDraft`.

## O7C active boundary — #78

O7C owns Android Health Connect platform availability/composition behind `HealthConnectionGateway`.

Repository evidence does not yet approve concrete health-data record types. `docs/ROADMAP.md` explicitly defers health permissions/wearable-data sync until the Recovery/data-source/privacy decision is approved. Therefore O7C must not invent broad health permissions.

Before any `android.permission.health.*` declaration/runtime authorization request, prove the exact product use case, exact record types and read/write scope. Until that gate is satisfied:

```text
SDK/provider unavailable                   → unavailable
SDK/provider available, scope unapproved   → notRequested
connected                                  → unreachable
```

## Guardrails

- no fake health connection success;
- no OS health permission request without exact approved data types and explicit user action;
- no broad future-use permissions;
- no sensitive health-data duplication/logging;
- imported health records never belong in `onboarding_drafts`;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.
