# Product Onboarding O5C — Nutrition Goals Runtime + Legacy Targets Compatibility

**Status:** In progress  
**Tracker:** GitHub Issue #66  
**Parent O5:** #63  
**Predecessor O5B:** #65 ✅ / CI #1460  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Post-onboarding Nutrition Settings context:** #46 planning-only  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting validated checkpoint

```text
a8d63137794f6c495a276643134f75365ed48eba
Flutter CI #1460 / run 32577510268
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This exact SHA is the frozen O5B source/runtime baseline. Task/tracker-only commits after it do not replace that validation evidence.

## Outcome

Move the existing Nutrition Target runtime ownership from legacy top-level `targets` to the stable `nutritionGoals` Product Onboarding identity while preserving values, UI behavior, calculations and legacy resume compatibility.

Target identity:

```text
OnboardingStepId.nutritionGoals
OnboardingSectionId.nutritionGoals
```

Legacy draft compatibility at minimum:

```text
targets + TargetStepId.nutritionTarget
        ↓ normalize
nutritionGoals + existing Nutrition Target child/value
```

O5C is runtime identity/navigation/resume ownership only. O5D owns canonical durable persistence and mixed-writer shutdown.

## Verified starting evidence

- O5B is validated at `a8d63137794f6c495a276643134f75365ed48eba` / Flutter CI #1460.
- Stable future `nutritionGoals` and `workoutTargets` identities already exist in `OnboardingStepId`.
- Current active `TargetsFlowPlan` contains only `TargetStepId.nutritionTarget`; Body Goal Pace and Wellness targets have already moved to their canonical runtime sections.
- Existing Nutrition Target behavior is intentionally all-mode through O5B.
- The existing Nutrition Target screen calculates calories/macros/fiber from common Profile/Body/Wellness/goal inputs and is not a Nutrition Profile preference editor.
- Historical onboarding architecture keeps feature-specific branches conditional while the later Targets boundary is shared.
- #46 Nutrition Settings visibility is post-onboarding editing scope, not an explicit first-run removal decision for Workout mode.
- Canonical durable target owner already exists as `public.user_nutrition_targets`, but O5D—not O5C—owns wiring onboarding completion to that owner.
- `onboarding_drafts` remains resume/orchestration storage rather than durable domain ownership.

## Resolved decision — `nutritionGoals` remains all-mode

```text
Workout   ✅ nutritionGoals
Nutrition ✅ nutritionGoals
Hybrid    ✅ nutritionGoals
```

O5C is an ownership-identity migration and **must not also change current Product Onboarding eligibility**. There is no checked-in product approval to remove the calculated Nutrition Target from Workout mode. Repository runtime/visual safety therefore wins: preserve current behavior while moving it to the correct stable section identity.

A future decision to hide Nutrition Goals in Workout must be a separate explicitly approved product change with its own acceptance matrix.

Target placement:

```text
Workout:
userProfile → bodyGoal → wellnessGoals → workoutPreferences → nutritionGoals → review

Nutrition:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → nutritionGoals → review

Hybrid later:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → workoutIntro → nutritionGoals → review

Hybrid setup now:
userProfile → bodyGoal → wellnessGoals → nutritionProfile → workoutIntro
→ workoutPreferences → nutritionGoals → review
```

Target values remain preserved across mode changes because every current mode remains eligible in O5C.

## Scope

- [x] audit current Nutrition Target flow placement and mode behavior;
- [x] audit Nutrition Target screen/calculation semantics and Workout-mode impact;
- [ ] audit current renderer/section ownership, validation, progress and completion invalidation;
- [ ] audit legacy draft DTO/cursor normalization for `targets + nutritionTarget`;
- [x] resolve and record `nutritionGoals` mode eligibility;
- [ ] activate stable `nutritionGoals` at the current Nutrition Target position for all modes;
- [ ] remove active Nutrition Target runtime ownership from legacy top-level `targets`;
- [ ] preserve existing Nutrition Target UI and calculation behavior;
- [ ] normalize legacy `targets + nutritionTarget` resume to `nutritionGoals` losslessly;
- [ ] make next/back/progress/invalidation `nutritionGoals`-owned;
- [ ] preserve later valid checkpoints across the identity migration;
- [ ] add focused flow/controller/progress/resume/renderer tests;
- [ ] run full four-gate CI and freeze one exact O5C source SHA.

## Serialization strategy

Prefer the smallest migration surface.

`TargetsOnboardingDraft` and `TargetStepId.nutritionTarget` remain the existing draft/value compatibility storage during O5C unless source proves a format change is required. Do not introduce a second draft value merely to rename runtime ownership.

Legacy top-level `targets` remains a recognized serialized/resume identity and must normalize `nutritionTarget` to active `nutritionGoals`. Active mode plans must stop using top-level `targets` after O5C.

If current codecs require an additive identity marker or schema bump, prove that from source before changing the format. Legacy payloads must remain readable.

## UI governance

If presentation files are touched, read/follow:

```text
apps/core/lib/src/theme/README.md
apps/features/AGENTS.md
```

Reuse the existing `NutritionTargetScreen`, target scaffold, and shared onboarding components. O5C is an ownership/navigation migration, not a redesign.

## Non-goals

- no `user_nutrition_targets` completion persistence cutover;
- no `NutritionTargetsRepository` production completion wiring;
- no `TargetsSetupRepository` mixed-writer shutdown;
- no target recommendation/formula change;
- no calories/macros/fiber redesign;
- no Product Onboarding mode-eligibility change;
- no post-onboarding Settings implementation from #46;
- no Supabase migration/schema change;
- no legacy-column drop;
- no permanent dual write;
- no O5D work before O5C exact full-CI-green acceptance.

## Acceptance

- [x] mode eligibility is explicitly resolved from checked-in evidence;
- [ ] Workout, Nutrition and Hybrid active plans contain `nutritionGoals` at the existing Nutrition Target position;
- [ ] active runtime no longer uses top-level `targets` for Nutrition Target ownership;
- [ ] the existing Nutrition Target screen and calculation behavior are unchanged;
- [ ] legacy `targets + nutritionTarget` resumes under `nutritionGoals` with identical value;
- [ ] next/back/progress/completion invalidation are section-aware;
- [ ] later valid checkpoints remain later;
- [ ] serialization compatibility is explicit and tested;
- [ ] no persistence/schema/formula/mixed-writer or eligibility change;
- [ ] Flutter analyze + Dart analyze + Flutter tests + Dart tests are green on one exact source SHA.

## Exit

O5C closes only after stable Nutrition Goals runtime ownership and legacy Targets compatibility are validated on one exact full-CI-green checkpoint. O5D then performs canonical Nutrition Profile/Targets persistence cutover and legacy mixed-writer shutdown.
