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
- Stable future `nutritionGoals` top-level identity already exists in `OnboardingStepId`.
- Current active `TargetsFlowPlan` contains only `TargetStepId.nutritionTarget`; Body Goal Pace and Wellness targets have already moved to their canonical runtime sections.
- Existing Nutrition Target behavior is still intentionally left under legacy top-level `targets` through O5B.
- Canonical durable target owner already exists as `public.user_nutrition_targets`, but O5D—not O5C—owns wiring onboarding completion to that owner.
- `onboarding_drafts` remains resume/orchestration storage rather than durable domain ownership.

## Decision gate — `nutritionGoals` mode eligibility

Do not change source placement until checked-in product/runtime evidence resolves this explicitly.

Current facts to reconcile:

```text
Current legacy Nutrition Target: Workout + Nutrition + Hybrid
O5B Nutrition Profile:          Nutrition + Hybrid only
Future identities:              nutritionGoals separate from workoutTargets
#46 Nutrition Settings:         Nutrition + Hybrid only
```

Rules:

- do not hide the current target merely because the new section is named `nutritionGoals`;
- do not preserve all-mode visibility merely because legacy runtime did so;
- resolve the intended first-run requirement from repository product contracts and actual target semantics;
- if a mode becomes ineligible, preserve dormant target values and never delete them;
- document the final decision in Issue #66 and this task before implementation.

## Scope

- [ ] audit current Nutrition Target flow placement and mode behavior;
- [ ] audit Nutrition Target screen/calculation semantics and whether Workout mode depends on them;
- [ ] audit current renderer/section ownership, validation, progress and completion invalidation;
- [ ] audit legacy draft DTO/cursor normalization for `targets + nutritionTarget`;
- [ ] resolve and record `nutritionGoals` mode eligibility;
- [ ] activate stable `nutritionGoals` at the current Nutrition Target position for eligible plans;
- [ ] remove active Nutrition Target runtime ownership from legacy top-level `targets`;
- [ ] preserve existing Nutrition Target UI and calculation behavior;
- [ ] normalize legacy `targets + nutritionTarget` resume to `nutritionGoals` losslessly;
- [ ] make next/back/progress/invalidation `nutritionGoals`-owned;
- [ ] preserve dormant values and later valid checkpoints across mode changes;
- [ ] add focused flow/controller/progress/resume/renderer tests;
- [ ] run full four-gate CI and freeze one exact O5C source SHA.

## Serialization strategy

Prefer the smallest migration surface.

`TargetsOnboardingDraft` and `TargetStepId.nutritionTarget` may remain serialized compatibility storage during O5C if they are already stable and lossless. Do not introduce a second draft field merely to rename runtime ownership.

If current codecs require an additive identity marker or schema bump, prove that from source before changing the format. Legacy payloads must remain readable.

## UI governance

If presentation files are touched, read/follow:

```text
apps/core/lib/src/theme/README.md
apps/features/AGENTS.md
```

Reuse the existing Nutrition Target screen and shared onboarding components. O5C is an ownership/navigation migration, not a redesign.

## Non-goals

- no `user_nutrition_targets` completion persistence cutover;
- no `NutritionTargetsRepository` production completion wiring;
- no `TargetsSetupRepository` mixed-writer shutdown;
- no target recommendation/formula change;
- no calories/macros/fiber redesign;
- no post-onboarding Settings implementation from #46;
- no Supabase migration/schema change;
- no legacy-column drop;
- no permanent dual write;
- no O5D work before O5C exact full-CI-green acceptance.

## Acceptance

- [ ] mode eligibility is explicitly resolved from checked-in evidence;
- [ ] eligible active plans contain `nutritionGoals` at the existing Nutrition Target position;
- [ ] active runtime no longer uses top-level `targets` for Nutrition Target ownership;
- [ ] the existing Nutrition Target screen and calculation behavior are unchanged;
- [ ] legacy `targets + nutritionTarget` resumes under `nutritionGoals` with identical value;
- [ ] next/back/progress/completion invalidation are section-aware;
- [ ] mode changes preserve dormant target data;
- [ ] later valid checkpoints remain later;
- [ ] serialization compatibility is explicit and tested;
- [ ] no persistence/schema/formula/mixed-writer change;
- [ ] Flutter analyze + Dart analyze + Flutter tests + Dart tests are green on one exact source SHA.

## Exit

O5C closes only after stable Nutrition Goals runtime ownership and legacy Targets compatibility are validated on one exact full-CI-green checkpoint. O5D then performs canonical Nutrition Profile/Targets persistence cutover and legacy mixed-writer shutdown.
