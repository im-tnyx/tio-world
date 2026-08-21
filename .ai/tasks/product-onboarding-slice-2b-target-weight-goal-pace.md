# Product Onboarding Slice 2B — Target Weight and Goal Pace

**Status:** In progress  
**Primary owner:** `apps/features/onboarding`  
**Affected platforms:** Flutter phone app  
**GitHub tracker:** #40  
**Canonical implementation PR:** #50 `feat(onboarding): activate unified mode-aware Goal screen`  
**Canonical branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`  
**Current audited PR #50 head:** `ec125ed560fbbbf95ccfc031cccd8df3fe7c39c2`  
**Current execution decision:** keep one active implementation PR (#50) until the approved Goal + Target Weight + Goal Pace contract in this task is internally complete and fully validated. Do not merge #50 to `main` yet.

---

## 0. Continuation-Safe Handoff — Read This First

This section is the canonical continuation context. A future agent/turn should be able to continue this work from the repository without relying on chat history.

### PR topology at the latest audit

#### PR #50 — canonical implementation PR

- state: open
- draft: yes
- mergeable: yes
- base: `main`
- head: `agent/onboarding-slice-2-step-1-body-goal-ui`
- audited head: `ec125ed560fbbbf95ccfc031cccd8df3fe7c39c2`
- changed files at audit: 54
- successful full Flutter CI evidence: run **#1057**, run id `32484593862`
- that successful job passed:
  - workspace bootstrap
  - Flutter analyze
  - Dart analyze
  - Flutter tests
  - Dart tests
- another run (#1058) on the same head was cancelled; the successful #1057 run is the green validation evidence.

PR #50 currently contains more than the Goal screen itself. It already contains future-facing Target Weight / Goal Pace flow scaffolding and some runtime behavior. Do not assume every existing behavior in #50 is finally approved merely because CI is green.

#### PR #51 — temporary stacked Slice 2B-A verification PR

- title: `feat(onboarding): enforce goal-aware weight follow-up eligibility`
- state: open
- draft: yes
- mergeable: yes
- base: PR #50 branch `agent/onboarding-slice-2-step-1-body-goal-ui`
- head: `agent/onboarding-slice-2b-a-weight-eligibility`
- audited head: `dd6168f71da90063bbe9de24a3eecf646ed72413`
- successful Flutter CI: run **#1060**, run id `32485233156`
- actual diff is only two test files:
  1. `apps/features/onboarding/test/domain/goal_weight_follow_up_flow_plan_test.dart`
  2. `apps/features/onboarding/test/domain/weight_goal_flow_policy_test.dart`

Those tests cover the approved eligibility matrix and current-step reconciliation. They are useful and must not be lost.

**Consolidation rule:** do not merge PR #51. Bring its two useful test changes into the canonical PR #50 branch, verify the resulting #50 diff/tests, then close #51 as superseded by #50.

#### PR #52 — validation-only PR

- title: `chore(onboarding): validate stacked Goal + weight eligibility integration`
- state: closed
- merged: no
- purpose was only to trigger `pull_request -> main` CI for the stacked #50 + #51 state.
- no further action is required. Do not reopen or merge it.

### Single-PR decision

The owner decision is now:

```text
PR #50 stays open/draft
→ consolidate useful #51 tests into #50
→ complete remaining Slice 2B behavior in #50
→ full acceptance matrix + full CI
→ only then decide Ready/Merge
```

Do not create another PR for 2B-B or 2B-C unless a later explicit owner decision changes this strategy.

---

## 1. Issue #40 Contract Relevant to This Task

Issue #40 is the canonical Product Onboarding structure tracker. It establishes these ownership rules:

- Onboarding owns flow order, step identity, draft/resume, Review, and finalization orchestration.
- Profile owns shared identity/baseline.
- Body/Wellness owns Body Goal and body metrics/goal plan.
- Nutrition owns Nutrition Profile + numeric Nutrition Targets.
- Workout owns Workout Profile + Workout Goals/Targets.
- A unified user-facing Goal screen is a presentation/orchestration decision and must not recreate mixed canonical ownership.

### Approved dynamic Goal screen contract

Already activated in PR #50 and should not be reimplemented from scratch:

#### Nutrition

Single select:

```text
Lose weight
Gain weight
Maintain weight
Recomposition
```

#### Workout / Hybrid

Same six training-aware options in both modes:

```text
Lose weight
Build muscle
Get stronger
Improve endurance
Stay fit
Recomposition
```

Rules:

- first selection = primary
- optional second compatible selection = supporting
- max 2
- incompatible selection starts a new primary according to the approved policy
- `Build muscle` must never be treated as `Gain weight`
- no `BODY GOAL` / `WORKOUT GOAL` visual subgroup headings
- preserve existing Goal card visual/interaction language

### Approved Target Weight / Goal Pace eligibility

`GoalIntentSelection` is the semantic authority.

#### Nutrition

```text
Lose weight      → Target Weight + Goal Pace
Gain weight      → Target Weight + Goal Pace
Maintain weight  → skip both
Recomposition    → skip both
```

#### Workout / Hybrid

```text
Lose weight primary OR supporting
→ Target Weight + Goal Pace

Build muscle alone
Get stronger alone
Improve endurance alone
Stay fit alone
Recomposition alone
→ skip both
```

Never infer body-weight direction from BMI, `target-current` delta, legacy profile labels, or a training-only goal.

Eligibility belongs at flow-plan/navigation level so these all agree:

- Next
- Back
- resume
- restored draft reconciliation
- progress count/semantics
- validation
- rendering

### Approved measurement initialization behavior

Do not redesign Height / Current Weight / Target Weight measurement UX.

Required truth when a measurement screen opens:

```text
visible value == picker selected position == canonical draft value
```

Priority:

1. saved/resumed answer restores exactly;
2. Height / Current Weight with no answer use deterministic existing defaults, with display and picker synchronized;
3. eligible Target Weight with no user-selected target may start from a deterministic goal-aware recommendation when authoritative inputs are sufficient;
4. recommendation is only a starting selection and remains user-adjustable;
5. after the user changes it, Back / Forward / resume must preserve the user's chosen value and must not silently recalculate over it.

### Recommendation decision boundary

The product contract approves deterministic goal-aware recommendation behavior and safety guardrails. It does **not** by itself approve a specific medical/numeric formula.

Current PR #50 contains a recommendation scaffold using:

- ±5% directional change
- BMI floor `18.5`
- gain guard `30.0`
- clamp `30..200 kg`

Treat those values as **current implementation scaffold requiring explicit review**, not as a newly invented canonical product/medical rule. Do not expand reliance on those numbers without a focused audit/approval. A safety guard may suppress a recommendation but must never reverse the explicit loss/gain direction.

### Approved Goal Pace ownership

- Goal Pace = weekly body-weight change only.
- direction = explicit goal intent only.
- preserve existing slider/haptics/projection visual language.
- Calories / BMR / TDEE belong to Nutrition Targets, not Goal Pace.
- if Goal Pace is skipped, a compatibility default must not be interpreted as a user-selected pace.

---

## 2. What Is Already Done in PR #50

### Goal activation — done and validated by CI

- `GoalIntent` exists.
- ordered `GoalIntentSelection(primaryGoal, supportingGoal)` exists.
- `GoalIntentSelectionPolicy` is mode-aware.
- Nutrition is single-select.
- Workout/Hybrid expose the approved six goals and compatible max-two behavior.
- `GoalIntentScreen` is active at the Profile Goal step.
- legacy Goal screen is inactive/removed from runtime path.
- draft snapshot schema v3 stores Goal selection.
- v1/v2 restore paths are migration-aware.
- unsupported legacy mappings return to Goal rather than inventing semantic intent.
- `Build muscle != Gain weight` guard exists.

### Weight-follow-up scaffolding already present

- `GoalWeightDirection` exists.
- `GoalWeightFollowUpPolicy` exists and currently matches the approved mode/goal eligibility matrix.
- `ProfileFlowPlan` / `BuildProfileFlowPlanUseCase` conditionally include Target Weight.
- `TargetsFlowPlan` / `BuildTargetsFlowPlanUseCase` conditionally include Goal Pace.
- both planners have current-step reconciliation helpers.
- `OnboardingState` derives dynamic Profile/Targets plans and flattened progress.
- controller navigation uses active child plans.
- Target Weight validation is direction-aware.
- Goal Pace runtime direction path uses explicit `GoalWeightDirection`.
- renderers pass explicit direction into Target Weight / Goal Pace presentation.

### Additional tests currently living only in PR #51

Must be consolidated into #50 before #51 closes:

- complete Nutrition / Workout / Hybrid follow-up matrix;
- training-only goals never invent body-weight direction;
- `Build muscle` never becomes gain direction;
- missing mode never activates follow-ups;
- Target Weight and Goal Pace use the same eligibility source;
- ineligible Target Weight reconciles to Current Weight;
- ineligible Goal Pace reconciles to Water Target.

---

## 3. Current Audit Findings / Known Risks

These are not theoretical. Inspect current #50 source before changing behavior.

### A. User Target Weight is currently cleared on direction changes

`OnboardingController` currently clears `targetWeightKg` when the resolved weight direction changes, including goal/mode transitions.

This is not automatically accepted final behavior. The approved contract requires reversible goal changes to avoid silently destroying previously entered eligible values unless an explicit product rule requires clearing them.

Target behavior to implement/audit:

- hidden/ineligible value may remain in draft for reversible changes;
- downstream code consumes it only when eligible;
- when returning to the same eligible direction, prior user-entered value should be restorable where semantically valid;
- do not silently overwrite a user-entered value with a recommendation.

### B. Recommendation currently seeds at runtime

`OnboardingController._prepareProfileForStep(...)` currently calls `TargetWeightRecommendationResolver` when entering an eligible Target Weight step with `targetWeightKg == null`.

This is conceptually aligned with the approved starting-recommendation behavior, but the exact numeric algorithm is not yet approved as a final product rule. Audit before retaining/expanding it.

### C. Current recommendation numeric policy is not yet locked

`TargetWeightRecommendationResolver` currently uses the ±5% / BMI 18.5 / BMI 30 / 30..200kg scaffold described above.

Before finalizing Slice 2B:

- verify whether these numbers already come from an approved repository/product policy;
- if not, propose the exact deterministic rule for explicit approval;
- do not present arbitrary thresholds as medical personalization;
- insufficient authoritative input should produce a neutral deterministic state or no personalized recommendation rather than invented certainty.

### D. Measurement picker source is unresolved

The inspected Height / Current Weight / Target Weight screen sources expose displayed values and surrounding content, but the intended historical/approved wheel interaction was not clearly present in the audited screen files.

Before any measurement UI edit:

1. locate the existing/reusable picker implementation or historical intended component;
2. verify kg/lb and height-unit handling;
3. verify initial selected index/value semantics;
4. preserve layout, typography, spacing, motion, and interaction design;
5. do not replace the picker with a card/text field/slider/new design.

### E. Goal Pace still owns Nutrition calorie logic

Current `GoalPaceScreen` still calculates/displays BMR/TDEE-style calorie values and kcal presentation.

This violates the approved ownership boundary.

Required correction:

- remove calorie/BMR/TDEE recommendation responsibility from Goal Pace;
- keep weekly pace, warning, projection, slider/haptics;
- Nutrition Targets remain the owner of Calories / BMR / TDEE context.

### F. Skipped Goal Pace still has a compatibility default

`TargetsOnboardingDraft.goalPaceKgPerWeek` is currently non-null with default `0.5` and legacy decode behavior also uses a default.

Risk:

```text
Goal Pace skipped
but draft contains 0.5
→ must NOT mean “user selected 0.5 kg/week”
```

Choose the smallest migration-safe representation/consumption rule that preserves old drafts while preventing fake intent. A local snapshot schema bump is only justified if the representation truly changes. No Supabase schema change is required solely for this slice.

### G. PR #50 description is no longer a perfect scope description

PR #50 body still says Target Weight recommendation/user-preservation/Goal Pace cleanup are out of scope. The owner decision now keeps remaining Slice 2B work inside the same PR before merge.

Update the PR body near final stabilization so the review description matches the actual final scope and validation evidence. Do not mark Ready while the body and implementation contract disagree.

---

## 4. Execution Plan Inside the Single Canonical PR #50

### Slice 2B-A0 — consolidate PR #51 into #50

First action before new product behavior:

- bring the two #51 test-file changes into #50;
- verify exact diff;
- run relevant focused tests / CI as available;
- only after the changes are visibly present on #50, close #51 as superseded by #50;
- leave #52 closed.

No production logic change is needed merely to consolidate #51 because the production eligibility policy already lives in #50.

### Slice 2B-A1 — eligibility/navigation truth hardening

Verify and close remaining gaps in:

- `GoalWeightFollowUpPolicy`
- `BuildProfileFlowPlanUseCase`
- `BuildTargetsFlowPlanUseCase`
- controller reconciliation
- `OnboardingState` progress flattening
- validators
- restored now-ineligible Target Weight/Goal Pace steps

Acceptance:

- every approved mode/goal combination has the correct active steps;
- Next/Back/Resume/Progress/Validation agree;
- skipped steps do not create validation obligations;
- no training-only intent invents body-weight direction.

### Slice 2B-B — Target Weight initialization + preservation

Order:

1. audit/locate approved measurement picker implementation;
2. establish display/picker/draft synchronization;
3. audit recommendation algorithm and get explicit approval for any exact numeric formula not already canonical;
4. recommendation seeds only a truly fresh eligible state;
5. preserve user-adjusted Target Weight across Back/Forward/resume;
6. stop direction/mode changes from destructively clearing recoverable user intent unless explicitly required;
7. ensure kg/lb display and canonical kg storage remain consistent.

No redesign.

### Slice 2B-C — Goal Pace + draft semantics

- remove Calories/BMR/TDEE/kcal ownership from Goal Pace;
- keep slider/haptics/projection UX;
- ensure direction comes only from `GoalIntentSelection` / `GoalWeightDirection`;
- prevent skipped default `0.5` from becoming fake user intent;
- reconcile old drafts safely;
- bump local snapshot schema only if required by the chosen representation.

### Slice 2B-D — full acceptance gate

Run complete matrix across:

```text
Nutrition:
Lose / Gain / Maintain / Recomposition

Workout:
Lose primary
Lose supporting
Build muscle only
Get stronger only
Improve endurance only
Stay fit only
Recomposition only

Hybrid:
same weight-goal matrix
plus existing Workout Intro branch compatibility
```

For applicable cases verify:

- Next
- Back
- resume
- restored draft
- progress count and accessibility semantics
- validation
- Target Weight recommendation start
- user override persistence
- unit behavior
- Goal Pace direction
- skipped/default semantics

Then full repository-required analyzer/tests.

---

## 5. Planned / Expected File Impact

Audit before editing. Expected files include:

### Eligibility / flow

- `apps/features/onboarding/lib/src/domain/usecases/goal_weight_follow_up_policy.dart`
- `apps/features/onboarding/lib/src/domain/usecases/weight_goal_flow_policy.dart`
- `apps/features/onboarding/lib/src/domain/usecases/build_profile_flow_plan_use_case.dart`
- `apps/features/onboarding/lib/src/domain/usecases/build_targets_flow_plan_use_case.dart`
- `apps/features/onboarding/lib/src/domain/usecases/build_onboarding_progress_plan_use_case.dart`
- `apps/features/onboarding/lib/src/presentation/state/onboarding_state.dart`
- `apps/features/onboarding/lib/src/presentation/controllers/onboarding_controller.dart`

### Target Weight

- `apps/features/onboarding/lib/src/domain/usecases/target_weight_recommendation_resolver.dart`
- `apps/features/onboarding/lib/src/domain/usecases/profile_step_validator.dart`
- `apps/features/onboarding/lib/src/presentation/renderer/profile_step_renderer.dart`
- `apps/features/onboarding/lib/src/presentation/screens/profile/target_weight_screen.dart`
- reusable measurement picker/component source discovered during audit

### Goal Pace / draft

- `apps/features/onboarding/lib/src/domain/usecases/goal_pace_resolver.dart`
- `apps/features/onboarding/lib/src/domain/usecases/target_step_validator.dart`
- `apps/features/onboarding/lib/src/presentation/renderer/target_step_renderer.dart`
- `apps/features/onboarding/lib/src/presentation/screens/targets/goal_pace_screen.dart`
- `apps/features/onboarding/lib/src/domain/models/targets_onboarding_draft.dart` only if needed
- `apps/features/onboarding/lib/src/data/mappers/onboarding_draft_snapshot_dto_mapper.dart` only if needed
- `apps/features/onboarding/lib/src/domain/models/onboarding_draft_snapshot.dart` only if representation changes

### Tests

At minimum audit/update:

- `apps/features/onboarding/test/domain/goal_weight_follow_up_flow_plan_test.dart` (from #51)
- `apps/features/onboarding/test/domain/weight_goal_flow_policy_test.dart`
- `apps/features/onboarding/test/domain/target_weight_recommendation_resolver_test.dart`
- `apps/features/onboarding/test/domain/profile_step_validator_test.dart`
- `apps/features/onboarding/test/domain/target_step_validator_test.dart`
- `apps/features/onboarding/test/domain/onboarding_controller_test.dart`
- `apps/features/onboarding/test/presentation/onboarding_controller_draft_persistence_test.dart`
- `apps/features/onboarding/test/data/onboarding_draft_snapshot_dto_mapper_test.dart`
- `apps/features/onboarding/test/presentation/profile_section_test.dart`
- `apps/features/onboarding/test/presentation/targets_section_test.dart`
- `apps/features/onboarding/test/presentation/onboarding_flow_page_test.dart`

---

## 6. UI / Design-System Guardrails

Before any Flutter UI edit, read and follow:

1. root `AGENTS.md`;
2. `apps/features/AGENTS.md`;
3. `.ai/tasks/design-system-token-consolidation.md`;
4. `apps/core/lib/src/theme/README.md`;
5. any more specific `AGENTS.md` under the changed path.

Use the existing reusable `package:tio_core/core.dart` surface before rebuilding a component.

Mandatory:

- no Goal card redesign;
- no measurement screen redesign;
- no new picker design unless separately approved;
- preserve Goal Pace slider/projection visual language while removing misplaced calorie ownership;
- preserve spacing, typography, unit treatment, motion, selected-state behavior, and accessibility semantics unless a separate design change is approved.

---

## 7. Non-Goals

This task does not authorize:

- canonical Body Goal / Body Measurement owner schema migration;
- canonical Workout Goal owner migration;
- Supabase schema migration solely for this slice;
- Health Concerns / Injuries & Limitations implementation;
- Special Event changes;
- Workout Profile / Equipment taxonomy;
- Nutrition macro-target implementation beyond removing misplaced Goal Pace calorie ownership;
- Health Connections;
- Plan Building / Congratulations changes;
- unrelated onboarding redesign.

---

## 8. Current Validation Evidence

### PR #50

Successful Flutter CI run **#1057** (`32484593862`) on head:

`ec125ed560fbbbf95ccfc031cccd8df3fe7c39c2`

At that head:

- Flutter analyze passed
- Dart analyze passed
- Flutter tests passed
- Dart tests passed

This proves the current branch is technically green at that snapshot. It does **not** prove the remaining Slice 2B product contract is complete.

### PR #51

Successful Flutter CI run **#1060** (`32485233156`) on head:

`dd6168f71da90063bbe9de24a3eecf646ed72413`

This validates the two additional eligibility/reconciliation test changes in the stacked state. Those changes still need consolidation into #50.

---

## 9. Exit Criteria Before PR #50 Can Be Considered Ready

### PR topology

- [ ] #51 two useful test changes are present in #50.
- [ ] #51 is closed as superseded only after consolidation verification.
- [x] #52 is closed and unmerged.
- [ ] #50 remains the only active implementation PR for this work.

### Goal / eligibility

- [x] dynamic mode-aware Goal screen active.
- [x] `GoalIntentSelection` stored/restored migration-safely.
- [x] `Build muscle != Gain weight`.
- [ ] consolidated matrix tests prove approved eligibility on #50.
- [ ] Next/Back/Resume/Progress/Validation all agree on active plans.

### Target Weight

- [ ] intended picker/reusable measurement interaction audited.
- [ ] displayed value = selected picker value = canonical draft value.
- [ ] exact recommendation numeric rule is approved or replaced with an already-approved deterministic policy.
- [ ] recommendation never reverses explicit direction.
- [ ] recommendation seeds only fresh eligible state.
- [ ] user-adjusted Target Weight survives Back/Forward/resume.
- [ ] reversible goal/mode changes do not silently destroy recoverable user-entered target intent.

### Goal Pace / draft

- [ ] Goal Pace contains no Calories/BMR/TDEE/kcal ownership.
- [ ] direction derives only from explicit Goal intent.
- [ ] slider/haptics/projection remain stable.
- [ ] skipped/default `0.5` does not become fake user intent.
- [ ] legacy drafts restore safely.

### Final validation

- [ ] focused tests for all changed contracts pass.
- [ ] full Flutter analyzer passes.
- [ ] full Dart analyzer passes.
- [ ] full Flutter tests pass.
- [ ] full Dart tests pass.
- [ ] PR #50 body is updated to match final actual scope/evidence.
- [ ] PR #50 remains Draft until the above product + technical gates are satisfied.

### Final Status

`IN PROGRESS` on PR #50. Do not merge to `main` until the exit criteria above are satisfied.
