# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1–O6 complete; O7 ACTIVE with O7C active  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O6 Workout:** #69 ✅ / CI #1555  
**O7 Health Connections:** #75 ACTIVE  
**O7A:** #76 ✅  
**O7B:** #77 ✅ / CI #1575  
**O7C:** #78 ACTIVE  
**Account verification:** #8 parallel lane  
**O11 cleanup:** #54 BLOCKED until O10  
**PR:** #50 Draft/open/unmerged

## Latest exact validated source checkpoint

```text
371fafb8cf8a27b6f7922733b071277accf4af98
Flutter CI #1575 / run 32607322748 / job 97114316589
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O7C task/tracker commits after this SHA do not replace exact runtime validation.

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

Health connection durability is intentionally unresolved until O7D proves the correct owner. Imported sensitive health records do not belong in `onboarding_drafts`.

## Execution order

```text
O1 App Mode durability                            ✅ #11 / CI #1240
O2 common User Profile owner + section            ✅ #53 / CI #1279
O3 Body Goal section + Body/Profile parity        ✅ #55 / CI #1354
O4 Wellness placement + canonical owner           ✅ #58 / CI #1441
O5 Nutrition Profile + Targets                    ✅ #63 / CI #1507
O6 Workout Profile + Targets                      ✅ #69 / CI #1555
→ O7 Health Connections                           ACTIVE #75
   O7A capability + product contract readiness    ✅ #76
   O7B runtime section + approved UI/content       ✅ #77 / CI #1575
   → O7C Android Health Connect adapter            ACTIVE #78
   O7D persistence/resume/review integration
   O7E integrated acceptance
→ O8 Review + edit-back + resume
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                    BLOCKED #54
```

Only one Product Onboarding implementation slice may be active at a time.

## Validated through O7B

Canonical Health Connections runtime is frozen:

```text
flow:       Nutrition Targets → Health Connections → Review
behavior:   optional / non-blocking / retryable later
status:     unavailable | notRequested | denied | connected
state:      live platform status outside OnboardingDraft
```

Only a real platform adapter may establish `connected`. O7B's unavailable fallback never requests OS permission and pre-O7B unfinished Review drafts reconcile through the new step.

## O7C active contract — #78

O7C wires Android Health Connect availability/composition behind O7B's `HealthConnectionGateway`.

The repository currently has no Health Connect dependency, provider query or health-data permission declarations. Repository roadmap also defers health permissions/wearable-data sync until the Recovery/data-source/privacy boundary is approved.

Because Android Health Connect permissions are tied to specific record types/use cases, O7C must not invent a broad future-use permission set. Before adding any health-data permission or runtime authorization request, prove:

- concrete product capability;
- canonical imported-data owner;
- exact record types;
- read/write scope per type;
- matching Play Console/privacy declaration;
- partial/denied grants cannot become `connected`.

Until exact scope is approved/source-backed:

```text
SDK/provider unavailable                  → unavailable
SDK/provider available, scope unapproved  → notRequested
connected                                 → unreachable
```

Platform availability detection and app-level gateway composition may proceed without broad data access.

## Guardrails

- no fake health connection success;
- no passive OS health permission request;
- no broad health permission declarations for future use;
- no plugin/manifest mutation outside O7C's proven minimum;
- no sensitive health-data duplication/logging;
- no applied migration edits or legacy-column drops;
- O11/#54 stays blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Handoff

**O7B #77 is complete on exact source `371faf...` / CI #1575. O7C #78 is the only active Product Onboarding implementation slice. Do not start O7D/O7E early.**
