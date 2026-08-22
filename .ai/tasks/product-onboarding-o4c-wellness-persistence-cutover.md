# Product Onboarding O4C — Canonical Wellness Persistence Cutover

**Status:** Ready  
**Tracker:** pending GitHub issue creation  
**Parent O4:** #58  
**Predecessor:** #60 O4B ✅ CI #1405  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Global UI / Design-System Guardrail

This is a persistence/ownership slice. No visual redesign is authorized. Existing Wellness screens, geometry, picker behavior, labels, spacing, typography, colors, and navigation appearance must remain unchanged unless a semantic wiring change strictly requires non-visual composition work.

If Flutter presentation code becomes unavoidable, read `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md` first and preserve current rendering.

## 1. Discovery

### User Outcome

When Product Onboarding saves Wellness answers, Steps, Water, Sleep, Bed Time, and Wake Time persist through the canonical Wellness owner and survive later reads without Nutrition remaining their durable owner.

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

Later commits on the branch may be docs-only handoff/tracker updates. They do not replace the exact validated O4B runtime checkpoint above.

### Success Criteria

- Product Onboarding persists active Wellness values through `WellnessTargetsRepository.upsert`.
- Production Supabase composition uses `SupabaseWellnessTargetsRepository` targeting only `public.user_wellness_targets`.
- Canonical Wellness payload covers `dailySteps`, `waterMl`, `sleepTargetMinutes`, `bedTimeMinutes`, and `wakeTimeMinutes` with explicit nullable semantics.
- Nutrition persistence stops writing Wellness mirrors (`steps_target`, `water_target_ml`, `sleep_target_minutes`, `bed_time`, `wake_up_time`) into `user_nutrition_profiles` for the O4C production path.
- Legacy `user_targets` fallback does not continue acting as a Wellness durable-write path.
- Nutrition recommendation/calculation may still consume Wellness values as inputs where required, without owning their durable storage.
- Compatibility reads are preserved where downstream code still depends on legacy rows; read removal is not implied by write cutoff.
- Owner failure is fail-closed: Wellness persistence failure prevents downstream completion/publication rather than silently falling back to Nutrition mirrors.
- No applied migration is edited and no legacy column is dropped.
- Full Flutter/Dart CI is green on one exact O4C source SHA before O4D begins.

### Scope

- add a narrow onboarding → canonical Wellness mapper if one does not already exist;
- inject `WellnessTargetsRepository` into `PersistOnboardingOwnerDataUseCase`;
- persist Wellness in the ordered owner pipeline before downstream Nutrition Targets persistence/completion;
- add app composition/provider for canonical Wellness repository;
- remove Wellness durable-write fields from Supabase Nutrition persistence;
- remove or disable legacy Wellness write fallback from the active production Nutrition path without deleting compatibility readers prematurely;
- keep Nutrition recommendation inputs available from current onboarding draft/canonical values as needed;
- add focused mapper, coordinator, repository, composition, and failure-ordering tests;
- update O4/#40/#44/#50 tracking only after evidence exists.

### Non-Goals

- no Wellness UI redesign or screen movement;
- no serialized onboarding draft relocation/schema-version bump unless proven unavoidable;
- no physical DROP/rename of legacy DB columns;
- no edit of already-applied migrations;
- no O5 Nutrition Profile/Targets split;
- no post-onboarding Wellness Settings work;
- no broad Nutrition owner redesign beyond the exact Wellness mirror write cutoff required here;
- no fabricated defaults to satisfy canonical persistence;
- no permanent dual-write synchronization.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected:
  - `apps/features/onboarding/lib/src/domain/usecases/persist_onboarding_owner_data_use_case.dart`
  - `apps/features/onboarding/lib/src/domain/usecases/targets_setup_mapper.dart`
  - `apps/features/progress/lib/src/domain/wellness_targets.dart`
  - `apps/features/progress/lib/src/data/supabase_wellness_targets_repository.dart`
  - `apps/features/nutrition/lib/src/data/repositories/supabase_targets_setup_repository.dart`
  - `apps/app/lib/app/network_providers.dart`
  - `apps/app/lib/app/router.dart`
- Existing pattern to follow:
  - O2/O3 owner cutovers inject narrow canonical repositories into `PersistOnboardingOwnerDataUseCase` and fail closed at owner boundaries.
  - `SupabaseWellnessTargetsRepository` already provides strict nullable canonical read/upsert behavior.
- Tests or validation already present:
  - `apps/features/progress/test/data/wellness_targets_repository_test.dart`
  - `apps/features/onboarding/test/domain/persist_onboarding_owner_data_use_case_test.dart`
  - `apps/features/nutrition/test/data/supabase_targets_setup_repository_test.dart`
  - O4B full CI #1405.

### Verified Current Gap

Current persistence coordinator:

```text
Profile
→ Body
→ Workout (when active)
→ Nutrition Targets
```

It currently has no `WellnessTargetsRepository` dependency or Wellness owner write.

Current `TargetsSetupMapper` still carries:

```text
dailySteps
sleepTargetMinutes
sleepTimeMinutes
wakeTimeMinutes
waterMl
```

into Nutrition `TargetsSetupData` because those values are also used by recommendation/legacy compatibility paths.

Current `SupabaseTargetsSetupRepository.saveTargetsSetup` still writes Wellness fields into `public.user_nutrition_profiles` and falls back to `public.user_targets` on selected schema errors. That is the durable write ownership to cut in O4C.

Canonical Wellness repository already writes:

```text
user_wellness_targets.steps_target
user_wellness_targets.water_target_ml
user_wellness_targets.sleep_target_minutes
user_wellness_targets.bed_time
user_wellness_targets.wake_up_time
```

and treats null fields as intentional clears.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Wellness durable owner is `user_wellness_targets` | Made | Approved canonical map #44 + O4A | #44 / #58 |
| Nutrition may consume Wellness values but cannot durably own them | Made | Prevent cross-domain duplicate ownership | #44 / #58 |
| O4C cuts writes, not physical legacy columns | Made | Destructive cleanup is O11 after O10 | #54 |
| Compatibility reads may remain temporarily | Made | Avoid breaking existing hydration/downstream paths before their own cutovers | O4C |
| Canonical null means unknown/clear, never UI default | Made | O4A repository contract | #59 |
| Wellness write failure blocks downstream completion | Made | Canonical owner must not silently fall back to mirror writes | O4C |
| Exact treatment of legacy `user_targets` write fallback | Audit in implementation | Active production path must stop Wellness durable fallback; verify whether any non-Wellness Nutrition compatibility still requires it before removal | O4C |

## 4. Architecture Design

### Chosen Approach

Introduce a dedicated mapping boundary from onboarding compatibility draft fields into canonical `WellnessTargetsData`, then persist it through `WellnessTargetsRepository` as a first-class owner in the onboarding owner coordinator.

Nutrition mapping can continue receiving Wellness values for calculation inputs during O4C, but Nutrition repository writes must exclude Wellness-owned columns.

### Ownership and Data Flow

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

same onboarding Wellness values
        ↓ calculation input only where needed
Nutrition recommendation / Nutrition target mapper
        ↓
Nutrition repository
        ↓
Nutrition-owned fields only
```

Ordered owner persistence target:

```text
Profile
→ Body
→ Wellness
→ Workout (when active)
→ Nutrition Targets
→ completion publication
```

If Wellness fails, later owner writes/completion must not proceed in that call.

### Alternative Rejected

- Keep writing both `user_wellness_targets` and `user_nutrition_profiles`: rejected because it creates permanent dual-write ownership.
- Move Wellness values physically out of `TargetsOnboardingDraft` in O4C: rejected because serialized compatibility is already proven and physical draft migration is unnecessary for durable owner cutover.
- Drop legacy Nutrition columns now: rejected because O11 owns destructive cleanup after integrated acceptance.
- Fabricate non-null Wellness values from UI defaults during persistence: rejected because canonical repository null semantics are explicit.

### Failure and Accessibility States

No visual state redesign is in scope. Persistence exceptions must preserve existing completion error/retry behavior. Signed-out canonical Wellness writes remain fail-closed. No sensitive health values should be logged.

## 5. Implementation Plan

- [ ] Re-read current branch state and preserve unrelated changes before source mutation.
- [ ] Add/test narrow `WellnessTargetsMapper` from onboarding draft compatibility fields.
- [ ] Add `WellnessTargetsRepository` dependency and `OwnerPersistenceTarget.wellness` failure boundary to `PersistOnboardingOwnerDataUseCase`.
- [ ] Define and test owner ordering so Wellness failure prevents Workout/Targets/completion progression in that call.
- [ ] Add `wellnessTargetsRepositoryProvider` in app composition using `SupabaseWellnessTargetsRepository` with in-memory fallback only where existing non-Supabase harness patterns require it.
- [ ] Inject canonical Wellness repository into onboarding completion composition.
- [ ] Refactor Nutrition persistence payload to exclude Wellness-owned mirror writes.
- [ ] Audit and constrain/remove active `user_targets` Wellness fallback writes without breaking unrelated Nutrition compatibility.
- [ ] Preserve Nutrition calculation access to Wellness inputs without durable duplicate ownership.
- [ ] Update focused tests for canonical payloads, explicit nulls, signed-out failure, failure ordering, and no Nutrition Wellness writes.
- [ ] Run focused tests first, then full Flutter/Dart analyze/tests.
- [ ] Record exact source SHA + CI run before marking O4C validated or starting O4D.

## 6. Quality Review

### Validation Run

```text
Not run yet for O4C source changes.
Starting baseline: O4B Flutter CI #1405 green on fc795e6411fe303d6381441c3ba872f99d522977.
```

### Review Findings and Resolution

No O4C production source change has been made yet. The task is ready for bounded implementation.

## 7. Final Handoff

### Changed Files

Task brief only at creation time.

### Actual Behavior

Not implemented yet.

### Known Limitations

- Compatibility draft storage remains under `TargetsOnboardingDraft` by design.
- Legacy schema columns remain until O11.
- O4D must separately prove integrated canonical read/write/resume/failure behavior after this write cutover.

### Final Status

`REVIEW`