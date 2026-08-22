# Current State

Last verified from current branch/runtime trackers and exact CI evidence: 2026-08-23.

Runtime source remains behavior truth. Product Onboarding sequencing is owned by `.ai/tasks/product-onboarding-canonical-execution.md`.

## Read order

1. `.ai/CURRENT.md`
2. `.ai/tasks/product-onboarding-canonical-execution.md`
3. `.ai/tasks/product-onboarding-o7a-health-connections-contract.md`
4. GitHub Issues #77/#75/#40/#44 and Draft PR #50
5. O6 predecessor acceptance: #74/#69

## Latest exact validated Product Onboarding checkpoint

```text
d56e8226f8631bc81d3dd309cbb22c631ca636f5
Flutter CI #1555 / run 32591048642
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O6 runtime/source checkpoint. O7A contract/tracker commits do not replace exact runtime validation.

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
   O7B runtime section + approved UI/content      BLOCKED #77
   O7C Android Health Connect adapter
   O7D persistence/resume/review integration
   O7E integrated acceptance
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 Canonical Schema Cleanup                   BLOCKED #54
```

## O7A frozen contract

Reserved `healthConnections` identities exist but remain unscheduled. Current app source has no Health Connect/HealthKit plugin, Android health permission configuration, Health Connections draft state or active platform adapter; this branch also has no iOS Runner scaffold.

Minimum product-safe capability proposal:

```text
unavailable
notRequested
denied
connected
```

Only a real platform adapter may establish `connected`.

Ownership split:

```text
Product Onboarding
  → orchestration only: eligibility / skip-or-attempt / resume checkpoint

Platform health adapter
  → live capability + authorization truth

Durable per-device connection metadata
  → unresolved until O7D

Imported health / biometric records
  → future dedicated health/sync domain; never onboarding_drafts
```

## O7B blocker — #77

Source activation is blocked until explicit approval of:

1. completion behavior for Skip / unavailable / denied-cancelled;
2. visible screen content/actions and connected/unavailable/denied states;
3. exact flow placement.

Architecture recommendation: Health Connections should be optional/non-blocking and retryable later. Recommended placement: `Nutrition Targets → Health Connections → Review` for all App Modes. Neither recommendation is implemented until approved.

## Guardrails

- no fake health connection success;
- no OS health permission request without explicit user action;
- no new visible Health Connections screen/content without approval;
- no health plugin/manifest/schema mutation before its focused slice;
- no sensitive health-data duplication/logging;
- O11 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.
