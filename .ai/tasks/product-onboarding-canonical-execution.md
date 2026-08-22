# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1/O2/O3 complete; O4D Wellness acceptance ACTIVE  
**Primary tracker:** #40  
**Canonical ownership:** #44  
**O1 App Mode:** #11 ✅ closed  
**O2 User Profile:** #53 ✅ closed  
**O3 Body Goal:** #55 ✅ closed / CI #1354  
**O4 Wellness:** #58 ACTIVE  
**O4A:** #59 ✅ closed / CI #1365  
**O4B:** #60 ✅ closed / CI #1405  
**O4C:** #61 ✅ validated / CI #1428  
**O4D:** #62 ACTIVE  
**Account verification:** #8 parallel lane  
**O11 cleanup:** #54 BLOCKED until O10  
**PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Current validated foundation

```text
O1 durable App Mode / active_tabs                ✅ CI #1240
O2 common User Profile end-to-end                ✅ CI #1279
O3 canonical Body Goal end-to-end                ✅ CI #1354
O4A canonical Wellness repository contract       ✅ CI #1365
O4B Wellness runtime/navigation/resume            ✅ CI #1405
O4C canonical Wellness persistence cutover       ✅ CI #1428
```

O4C exact validated source checkpoint:

```text
2cd34d70df124efd332dbbf2b7975dcef5f29631
Flutter CI #1428 / run 32569633640
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Later task/tracker-only commits do not replace this runtime/source checkpoint unless full CI is rerun on changed runtime source.

## Canonical owners

```text
users                      → stable account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + ordered active_tabs
user_devices               → device owner
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep/bed/wake targets
user_nutrition_profiles    → nutrition context
user_nutrition_targets     → nutrition targets
user_workout_profiles      → workout context
user_workout_targets       → workout targets
onboarding_drafts          → draft/resume orchestration only
```

Applied migrations are immutable. Legacy duplicate columns remain until verified O11 cleanup.

## Execution order

```text
O1 App Mode durability                         ✅ #11 / CI #1240
O2 common User Profile owner + section         ✅ #53 / CI #1279
O3 Body Goal section + Profile/Body parity     ✅ #55 / CI #1354
→ O4 Wellness placement + owner                ACTIVE #58
   O4A canonical repository contract           ✅ #59 / CI #1365
   O4B runtime Wellness section/resume          ✅ #60 / CI #1405
   O4C persistence + Nutrition mirror cutoff   ✅ #61 / CI #1428
   → O4D integrated acceptance                 ACTIVE #62
→ O5 Nutrition Profile + Targets               BLOCKED by O4D
→ O6 Workout Intro/Profile/Targets
→ O7 Health Connections
→ O8 Review + edit-back + resume
→ O9 Plan Building/finalization
→ O10 final acceptance
→ O11 canonical schema cleanup                 BLOCKED #54
```

Only one Product Onboarding sub-slice is active at a time.

## O4A — VALIDATED

`tio_feature_progress` provides `WellnessTargetsData`, `WellnessTargetsRepository`, an in-memory implementation, and a Supabase adapter targeting only `public.user_wellness_targets`. Canonical reads preserve nulls and fail strictly on malformed state; signed-out writes fail closed with no anonymous-auth side effect.

## O4B — VALIDATED

Validated runtime:

```text
wellnessGoals: Bridge → Step Target → Sleep Target → Water Target
targets:        Nutrition Target
```

Existing `TargetStepId` and `TargetsOnboardingDraft` remain compatibility storage while semantic runtime/navigation/progress ownership is Wellness. Legacy actual Targets Wellness cursors migrate to `wellnessGoals`; later checkpoints remain later with dormant Wellness values.

## O4C — VALIDATED

Focused task: `.ai/tasks/product-onboarding-o4c-wellness-persistence-cutover.md`  
Tracker: #61.

Validated behavior:

```text
Onboarding Wellness values
        ↓
WellnessTargetsMapper
        ↓
WellnessTargetsRepository
        ↓
public.user_wellness_targets
```

Owner persistence ordering is now:

```text
Profile → Body → Wellness → Workout(if active) → Nutrition Targets → completion
```

Active Nutrition writes no longer persist Steps/Water/Sleep/Bed/Wake mirrors to `user_nutrition_profiles`, and legacy `user_targets` fallback is Nutrition-only. Compatibility reads remain where older rows still require them.

## O4D — ACTIVE #62

Focused task: `.ai/tasks/product-onboarding-o4d-integrated-wellness-acceptance.md`.

O4D must prove the full canonical Wellness contract across:

- fresh write/read round-trip;
- canonical truth vs stale legacy mirrors;
- legacy Wellness cursor/value resume;
- later checkpoint preservation;
- missing/default provenance safety between concrete `TargetsOnboardingDraft` UI defaults and nullable canonical `WellnessTargetsData`;
- signed-out and owner-failure fail-closed behavior;
- downstream write/completion ordering;
- Nutrition calculation continuity without durable Wellness mirror ownership;
- production repository composition;
- one exact four-gate CI-green source checkpoint.

Production source changes are allowed only if integrated acceptance exposes a real semantic gap. Prefer narrow meaning-preserving fixes over storage/schema churn.

## Guardrails

- preserve existing screens/picker contracts;
- no fabricated semantic defaults in canonical persistence;
- no permanent dual-write synchronization;
- no applied migration edits or legacy-column drop;
- legacy reads may remain compatibility-only until later cutovers/O11;
- O5 stays blocked until #62 O4D integrated acceptance is green;
- O11/#54 stays blocked until O10;
- PR #50 remains Draft/open/unmerged through O4.

## Handoff

**Execute #62 O4D only. Do not begin O5 or schema cleanup until O4D is validated.**