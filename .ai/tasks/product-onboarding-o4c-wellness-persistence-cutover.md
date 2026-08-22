# Product Onboarding O4C — Canonical Wellness Persistence Cutover

**Status:** In progress  
**Tracker:** #61  
**Parent O4:** #58  
**Predecessor:** #60 O4B ✅ CI #1405  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Global UI / Design-System Guardrail

This is a persistence/ownership slice. No visual redesign is authorized. Existing Wellness screens, geometry, picker behavior, labels, spacing, typography, colors, and navigation appearance must remain unchanged. If presentation code becomes unavoidable, read `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md` first.

## 1. Discovery

### User Outcome

Product Onboarding Wellness answers persist through the canonical Wellness owner, while Nutrition may consume those values for calculations but no longer durably owns them.

### Starting checkpoint

Validated O4B runtime/source baseline:

```text
fc795e6411fe303d6381441c3ba872f99d522977
Flutter CI #1405 / run 32567404925
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Later branch commits before O4C source work are docs/tracker handoff commits and do not replace this exact validated runtime baseline.

### Success Criteria

- onboarding persists Steps/Water/Sleep/Bed/Wake through `WellnessTargetsRepository.upsert`;
- production composition uses `SupabaseWellnessTargetsRepository` targeting only `public.user_wellness_targets`;
- canonical null/clear semantics remain explicit and no UI default is fabricated;
- Nutrition `user_nutrition_profiles` writes stop including Wellness-owned mirrors;
- legacy `user_targets` is not an active fallback durable Wellness write path;
- Nutrition recommendation/calculation can still consume Wellness inputs where required;
- compatibility reads remain only where downstream code still needs them;
- Wellness owner failure prevents downstream owner/completion progression in the same call;
- no applied migration edit or legacy-column drop;
- exact O4C source SHA passes full Flutter/Dart CI before O4D starts.

### Scope

- add a narrow onboarding → `WellnessTargetsData` mapper;
- inject `WellnessTargetsRepository` into `PersistOnboardingOwnerDataUseCase`;
- add `OwnerPersistenceTarget.wellness` and fail-closed ordering;
- add app provider/composition for canonical Wellness repository;
- remove Wellness-owned fields from active Supabase Nutrition writes;
- audit/constrain the legacy `user_targets` fallback;
- preserve calculation inputs and required compatibility reads;
- add focused mapper/coordinator/repository/composition tests.

### Non-Goals

- no UI redesign or runtime section movement;
- no physical `TargetsOnboardingDraft` relocation unless proven unavoidable;
- no draft schema-version bump unless proven unavoidable;
- no legacy DB column DROP/rename;
- no applied migration edit;
- no O5 Nutrition split;
- no post-onboarding Wellness Settings work;
- no broad Nutrition redesign;
- no permanent dual-write synchronization.

## 2. Codebase Exploration

### Verified Evidence

Inspected current branch:

- `apps/features/onboarding/lib/src/domain/usecases/persist_onboarding_owner_data_use_case.dart`
- `apps/features/onboarding/lib/src/domain/usecases/targets_setup_mapper.dart`
- `apps/features/progress/lib/src/domain/wellness_targets.dart`
- `apps/features/progress/lib/src/data/supabase_wellness_targets_repository.dart`
- `apps/features/nutrition/lib/src/data/repositories/supabase_targets_setup_repository.dart`
- `apps/app/lib/app/network_providers.dart`
- `apps/app/lib/app/router.dart`

Existing tests include:

- `apps/features/progress/test/data/wellness_targets_repository_test.dart`
- `apps/features/onboarding/test/domain/persist_onboarding_owner_data_use_case_test.dart`
- `apps/features/nutrition/test/data/supabase_targets_setup_repository_test.dart`

### Verified Current Gap

Current owner coordinator:

```text
Profile
→ Body
→ Workout (when active)
→ Nutrition Targets
```

It has no Wellness repository dependency/write.

`TargetsSetupMapper` still carries `dailySteps`, `sleepTargetMinutes`, `sleepTimeMinutes`, `wakeTimeMinutes`, and `waterMl` into Nutrition `TargetsSetupData` because they remain calculation/compatibility inputs.

`SupabaseTargetsSetupRepository.saveTargetsSetup()` still writes Wellness mirrors into `public.user_nutrition_profiles` and can fall back to `public.user_targets`.

`SupabaseWellnessTargetsRepository` already writes only:

```text
user_wellness_targets.steps_target
user_wellness_targets.water_target_ml
user_wellness_targets.sleep_target_minutes
user_wellness_targets.bed_time
user_wellness_targets.wake_up_time
```

with explicit nullable clears and signed-out fail-closed behavior.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Wellness durable owner is `user_wellness_targets` | Made | approved canonical map | #44 / #58 |
| Nutrition may consume but not own Wellness values | Made | one durable owner per concept | #44 / #58 |
| O4C cuts writes, not physical columns | Made | destructive cleanup belongs to O11 | #54 |
| Compatibility reads may remain temporarily | Made | avoid premature downstream breakage | O4C |
| Null means unknown/intentional clear | Made | O4A canonical repository contract | #59 |
| Wellness failure blocks downstream completion | Made | no silent mirror fallback | #61 |
| Exact legacy `user_targets` fallback treatment | Audit during implementation | remove Wellness durable fallback without breaking unrelated Nutrition compatibility | #61 |

## 4. Architecture Design

### Chosen Approach

```text
OnboardingDraft.targets compatibility values
        ↓
WellnessTargetsMapper
        ↓
WellnessTargetsRepository.upsert
        ↓
SupabaseWellnessTargetsRepository
        ↓
public.user_wellness_targets

same Wellness values
        ↓ calculation input only where needed
Nutrition recommendation / target mapper
        ↓
Nutrition repository
        ↓
Nutrition-owned persistence only
```

Target owner ordering:

```text
Profile
→ Body
→ Wellness
→ Workout (when active)
→ Nutrition Targets
→ completion publication
```

If Wellness persistence fails, later owner writes/completion do not proceed in that call.

### Alternative Rejected

- permanent dual-write to Wellness + Nutrition tables;
- physical draft migration during O4C;
- legacy column cleanup before O11;
- fabricated non-null defaults for canonical persistence.

### Failure and Accessibility States

No visual state redesign. Existing retry/error behavior is preserved. Signed-out Wellness writes remain fail-closed. Do not log sensitive health values.

## 5. Implementation Plan

- [ ] verify latest branch state before production source mutation;
- [ ] add/test `WellnessTargetsMapper`;
- [ ] inject canonical Wellness repository into owner coordinator;
- [ ] add `OwnerPersistenceTarget.wellness` and ordering/failure tests;
- [ ] add `wellnessTargetsRepositoryProvider` and app composition;
- [ ] inject Wellness owner into onboarding completion path;
- [ ] stop Nutrition Supabase writes for Steps/Water/Sleep/Bed/Wake;
- [ ] audit/remove Wellness behavior from active `user_targets` fallback;
- [ ] preserve Nutrition calculation inputs without durable duplicate ownership;
- [ ] run focused tests;
- [ ] run full Flutter/Dart analyze/tests;
- [ ] record exact O4C source SHA + CI evidence before O4D.

## 6. Quality Review

### Validation Run

```text
O4C source validation not run yet.
Starting baseline: O4B CI #1405 green on fc795e6411fe303d6381441c3ba872f99d522977.
```

### Review Findings and Resolution

Task/issue/context are prepared. Production O4C source implementation is the active next work.

## 7. Final Handoff

### Changed Files

Task/tracker context only so far.

### Actual Behavior

O4C production behavior not implemented yet.

### Known Limitations

Compatibility draft storage remains under `TargetsOnboardingDraft`; legacy schema columns remain until O11; O4D will separately prove integrated read/write/resume/failure behavior.

### Final Status

`REVIEW`