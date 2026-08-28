# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1–O6 complete; O7 ACTIVE/BLOCKED at O7C2  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O6 Workout:** #69 ✅ / CI #1555  
**O7 Health Connections:** #75 ACTIVE/BLOCKED  
**O7A:** #76 ✅  
**O7B:** #77 ✅ / CI #1575  
**O7C:** #78 PARTIAL — O7C1 ✅, O7C2 blocked by #79  
**Account verification:** #8 parallel lane  
**O11 cleanup:** #54 BLOCKED until O10  
**PR:** #50 Draft/open/unmerged

## Latest exact validated source/platform checkpoint

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

Tracker/docs commits after this SHA do not replace exact validation.

## Canonical owners

```text
users                      → stable account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + ordered active_tabs
user_devices               → device owner
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep/bed/wake targets
user_nutrition_profiles    → nutrition context only
user_nutrition_targets     → calories/macros/fiber + customization state
user_workout_profiles      → workout context/capability
user_workout_targets       → workout goals/schedule/plan constraints
onboarding_drafts          → draft/resume orchestration only
```

Health connection durability remains unresolved until O7D. Imported health records require a dedicated owner proven by #79; they never belong in `onboarding_drafts`.

## Execution order

```text
O1 App Mode durability                            ✅ #11 / CI #1240
O2 common User Profile owner + section            ✅ #53 / CI #1279
O3 Body Goal section + Body/Profile parity        ✅ #55 / CI #1354
O4 Wellness placement + canonical owner           ✅ #58 / CI #1441
O5 Nutrition Profile + Targets                    ✅ #63 / CI #1507
O6 Workout Profile + Targets                      ✅ #69 / CI #1555
→ O7 Health Connections                           ACTIVE/BLOCKED #75
   O7A capability + product contract readiness    ✅ #76
   O7B runtime section + approved UI/content       ✅ #77 / CI #1575
   O7C Android Health Connect adapter              PARTIAL #78
      O7C1 platform surface presence               ✅ f95ddf7c / CI #1593 + Native #5
      O7C2 SDK readiness + authorization           BLOCKED #79
   O7D persistence/resume/review integration      BLOCKED
   O7E integrated acceptance                     BLOCKED
→ O8 Review + edit-back + resume
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                    BLOCKED #54
```

Only one Product Onboarding implementation slice may be active at a time. O7C2 is currently blocked; do not start O7D/O7E early.

## Validated Health Connections runtime — O7B

```text
flow:       Nutrition Targets → Health Connections → Review
behavior:   optional / non-blocking / retryable later
status:     unavailable | notRequested | denied | connected
state:      live platform status outside OnboardingDraft
```

Only a real authorized adapter may establish `connected`.

## Validated Android platform infrastructure — O7C1

O7C1 provides app-owned, dependency-free Health Connect surface-presence detection only:

```text
Android 14+            → framework service surface present/absent
Android 9–13           → provider/settings surface present/absent
Android < 9            → absent
managed/non-Android    → absent
```

It adds only provider package visibility, no health-data permissions, no record access, no Health Connect client dependency, and no app minSdk change. The production O7B unavailable gateway remains wired.

Surface presence must not be promoted to SDK readiness or authorization. Official client readiness later belongs to O7C2 and must distinguish unavailable/provider-update-required/available.

## O7C2 blocker — #79

Before any `android.permission.health.*` declaration or runtime authorization request, approve:

- concrete product capability;
- exact Health Connect record types;
- read/write scope per type;
- canonical imported-data owner;
- retention/freshness/consent withdrawal;
- Android client dependency/minSdk policy;
- matching Play Console/privacy declaration;
- full/partial/denied grant mapping.

Wellness targets such as steps/sleep do not themselves approve imported Steps/Sleep records.

## Guardrails

- no fake health connection success;
- no passive OS health permission request;
- no broad health permission declarations for future use;
- no sensitive health-data duplication/logging;
- no applied migration edits or legacy-column drops;
- O11/#54 stays blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Handoff

**O7C1 is validated on `f95ddf7c...` with Flutter CI #1593 and Android Native CI #5. O7C2 remains blocked by #79. Keep #78/#75 open and do not start O7D/O7E until the first least-privilege Health Connect data contract is approved and implemented.**
