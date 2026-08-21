# Product Onboarding Slice 2B — Target Weight and Goal Pace

**Status:** Blocked
**Primary owner:** `apps/features/onboarding`
**Affected platforms:** Flutter phone app
**GitHub tracker:** #40
**Current working context:** PR #50, branch `agent/onboarding-slice-2-step-1-body-goal-ui`
**Depends on:** PR #50 Goal activation being corrected, analyzer/tests green, and merged before Slice 2B production implementation begins
**Planning baseline inspected:** PR #50 head `85305129bad490b030c236ae2ad766e6b955fa2f`

## Execution Boundary

This task defines the **next Target Weight / Goal Pace implementation slice**. PR #50 already contains partial future-facing scaffolding. Do not re-implement that scaffolding after PR #50 merges. Audit the merged baseline first and complete only the remaining approved contract.

The missing `goal_weight_follow_up_policy.dart` currently breaking PR #50 is a **PR #50 stabilization blocker**, not evidence that Slice 2B should be implemented inside PR #50. The immediate order is:

```text
PR #50
→ restore/complete the minimal missing follow-up policy contract needed by existing PR #50 wiring
→ analyzer green
→ tests green
→ merge

then

Slice 2B
→ audit merged baseline
→ complete remaining Target Weight / Goal Pace contract only
```

No production code change is authorized by this task document itself.

## Global UI / Design-System Guardrail

This slice is primarily a flow/logic correction. It does **not** authorize a measurement-screen redesign.

Before any Flutter UI change, read and follow:

1. root `AGENTS.md`;
2. `apps/features/AGENTS.md`;
3. `.ai/tasks/design-system-token-consolidation.md`;
4. `apps/core/lib/src/theme/README.md`;
5. any more specific `AGENTS.md` under the changed path.

Inspect `package:tio_core/core.dart` and existing measurement components before rebuilding any picker, slider, card, input, or measurement interaction.

Mandatory visual contract:

- preserve existing Height / Current Weight / Target Weight measurement visual language;
- preserve existing Goal Pace slider/projection visual language unless separately approved;
- do not introduce a new card, text field, slider, picker design, spacing system, typography treatment, unit treatment, or motion pattern merely for this slice;
- if the intended historical wheel/picker is no longer present in current runtime source, locate/reconcile the reusable measurement interaction before any visual replacement.

---

## 1. Approved Product Contract from #40

### User Outcome

After the user chooses an explicit onboarding goal, Product Onboarding shows Target Weight and Goal Pace only when body-weight change is actually part of that chosen goal. When Target Weight is eligible, the screen opens with a deterministic goal-aware starting recommendation when enough authoritative measurements exist. The user can always change that value, and their chosen value becomes authoritative.

### Eligibility Matrix

#### Nutrition

```text
Lose weight
→ Target Weight
→ Goal Pace

Gain weight
→ Target Weight
→ Goal Pace

Maintain weight
→ skip Target Weight
→ skip Goal Pace

Recomposition
→ skip Target Weight
→ skip Goal Pace
```

#### Workout / Hybrid

```text
Lose weight selected as primary OR supporting
→ Target Weight
→ Goal Pace

Build muscle alone
Get stronger alone
Improve endurance alone
Stay fit alone
Recomposition alone
→ skip Target Weight
→ skip Goal Pace
```

Guardrail:

```text
Gain weight != Build muscle
```

### Behavioral Rules

- `GoalIntentSelection` is the semantic authority.
- BMI / Underweight / Overweight may be safety/recommendation inputs only; they must not choose or replace the user's goal.
- `targetWeight - currentWeight` must not infer the user's semantic goal.
- Next, Back, Resume, progress denominator/semantics, validation, and restored drafts must use the same active flow plan.
- Fresh eligible Target Weight may receive a deterministic recommendation.
- Existing saved user-entered Target Weight restores exactly.
- Once the user changes the recommendation, Back / Forward / Resume must preserve the user's chosen value and must not silently reapply the recommendation.
- Goal Pace represents weekly body-weight change only.
- Goal Pace direction comes from explicit goal intent.
- Calories / BMR / TDEE recommendation belongs to Nutrition Targets, not Goal Pace.
- Skipped/default Target Weight or Goal Pace values must not become canonical user intent merely because compatibility draft fields contain values.
- No Supabase schema change is required solely for this slice.

---

## 2. Current PR #50 Audit

The following is **already scaffolded or partially implemented in PR #50** and must not be recreated blindly after merge.

### Already Scaffolded

- `GoalIntent` and ordered `GoalIntentSelection` exist.
- `GoalWeightDirection` exists.
- `ProfileFlowPlan` and `TargetsFlowPlan` support dynamic child-step lists.
- `build_profile_flow_plan_use_case.dart` already expects a follow-up policy and conditionally excludes `ProfileStepId.targetWeight`.
- `build_targets_flow_plan_use_case.dart` already expects the same follow-up policy and conditionally excludes `TargetStepId.goalPace`.
- both planners already contain current-step reconciliation helpers.
- `target_weight_recommendation_resolver.dart` already contains a deterministic loss/gain recommendation scaffold with BMI-based safety guards.
- `goal_pace_resolver.dart` already exposes explicit `GoalWeightDirection` runtime semantics; numeric-delta inference is retained only as deprecated compatibility logic.
- `onboarding_controller.dart` already computes weight-goal direction, rebuilds Profile/Targets plans around Goal selection, and contains Target Weight recommendation preparation hooks.
- `onboarding_state.dart` already derives active Profile/Targets plans, weight-goal direction, and flattened progress.
- `profile_step_renderer.dart` already passes current weight, height, unit, direction, and target value into `TargetWeightScreen`.
- `target_step_renderer.dart` already passes explicit direction into `GoalPaceScreen`.
- `profile_step_validator.dart` already contains direction-aware Target Weight validation.
- relevant unit/controller/widget test files already exist as a starting point.

### PR #50 Stabilization Blocker — NOT Slice 2B Scope

PR #50 imports `goal_weight_follow_up_policy.dart`, but the file is missing at the inspected head. Flutter CI #1041 fails during onboarding analysis with 23 errors including missing URI/type/methods such as:

```text
GoalWeightFollowUpPolicy
directionFor
requiresTargetWeight
requiresGoalPace
```

Before Slice 2B production implementation starts, PR #50 must be corrected with the smallest contract-consistent fix and full analyzer/tests must pass.

### Remaining Product Gaps After the Scaffold

1. **Policy contract finalization**
   - confirm the merged `GoalWeightFollowUpPolicy` exactly implements the approved mode/goal matrix;
   - keep `WeightGoalFlowPolicy` only as bounded compatibility if still required;
   - no duplicated business rules.

2. **Target Weight recommendation semantics**
   - review existing 5% directional recommendation behavior against approved safety rules;
   - a safety guard may reduce or suppress a recommendation but must never reverse the explicit loss/gain direction;
   - insufficient authoritative input must not produce fake personalized claims.

3. **User-value preservation**
   - current PR #50 controller clears Target Weight when weight-goal direction changes;
   - audit this against reversible goal/mode-change behavior;
   - a previously user-entered value may be retained in draft for restoration when the same eligible direction returns, but only eligible values may be consumed downstream;
   - recommendations must seed only a fresh eligible state, never overwrite an existing user selection.

4. **Measurement picker/value synchronization**
   - current inspected `TargetWeightScreen` source shows value text + analysis card but does not contain the approved historical wheel/picker interaction;
   - locate the intended reusable measurement picker/interaction before UI edits;
   - ensure displayed value = selected picker position = canonical draft value;
   - saved values must restore at the exact picker position.

5. **Goal Pace ownership cleanup**
   - existing `GoalPaceScreen` still calculates/displays calorie/BMR/TDEE-derived values;
   - remove that ownership from Goal Pace while preserving the approved pace slider/projection UX;
   - Goal Pace remains weekly weight-change pace only.

6. **Skipped/default draft semantics**
   - `TargetsOnboardingDraft.goalPaceKgPerWeek` is currently non-null with default `0.5`;
   - mapper also restores missing legacy pace as `0.5`;
   - decide the smallest migration-safe representation or eligibility-aware consumption rule that prevents a skipped compatibility default from becoming fake user intent;
   - schema bump is required only if representation genuinely changes.

7. **Resume/progress/validation hardening**
   - restored drafts pointing at now-ineligible Target Weight / Goal Pace must reconcile safely;
   - progress/accessibility semantics must reflect active child-plan counts;
   - skipped screens must not create validation obligations.

---

## 3. Planned File Impact

### PR #50 stabilization first

- `apps/features/onboarding/lib/src/domain/usecases/goal_weight_follow_up_policy.dart`
  - restore/complete minimal API required by existing PR #50 wiring;
  - this stabilization belongs to PR #50 before merge.
- `apps/features/onboarding/lib/src/domain/usecases/weight_goal_flow_policy.dart`
- `apps/features/onboarding/lib/src/domain/usecases/build_profile_flow_plan_use_case.dart`
- `apps/features/onboarding/lib/src/domain/usecases/build_targets_flow_plan_use_case.dart`
- `apps/features/onboarding/lib/src/domain/usecases/usecases.dart`
  - only adjust as necessary to make PR #50 internally consistent and green; do not pull remaining Slice 2B UX/persistence cleanup into PR #50.

### Slice 2B after PR #50 merge

Audit merged source before touching each file. Expected impact:

- `apps/features/onboarding/lib/src/domain/usecases/goal_weight_follow_up_policy.dart`
  - verify/finalize approved eligibility + direction source of truth.
- `apps/features/onboarding/lib/src/domain/usecases/target_weight_recommendation_resolver.dart`
  - finalize deterministic recommendation/safety semantics.
- `apps/features/onboarding/lib/src/domain/usecases/goal_pace_resolver.dart`
  - ensure explicit direction is the only runtime semantic path.
- `apps/features/onboarding/lib/src/domain/usecases/profile_step_validator.dart`
  - verify active Target Weight validation behavior.
- `apps/features/onboarding/lib/src/domain/usecases/target_step_validator.dart`
  - verify active Goal Pace validation behavior.
- `apps/features/onboarding/lib/src/presentation/controllers/onboarding_controller.dart`
  - recommendation seeding, reversible goal changes, exact resume preservation, current-step reconciliation.
- `apps/features/onboarding/lib/src/presentation/state/onboarding_state.dart`
  - verify active plans drive navigation/progress semantics consistently.
- `apps/features/onboarding/lib/src/presentation/screens/profile/target_weight_screen.dart`
  - behavior/data synchronization only; no redesign.
- measurement picker/reusable component source discovered during the UI audit
  - restore/synchronize selected value only if needed.
- `apps/features/onboarding/lib/src/presentation/renderer/profile_step_renderer.dart`
  - verify wiring only.
- `apps/features/onboarding/lib/src/presentation/screens/targets/goal_pace_screen.dart`
  - remove calorie/BMR/TDEE responsibility; preserve pace/projection UX.
- `apps/features/onboarding/lib/src/presentation/renderer/target_step_renderer.dart`
  - ensure render path is valid only for active explicit direction.
- `apps/features/onboarding/lib/src/domain/models/targets_onboarding_draft.dart`
  - only if needed to prevent compatibility default from becoming user intent.
- `apps/features/onboarding/lib/src/data/mappers/onboarding_draft_snapshot_dto_mapper.dart`
  - only if draft representation/restore semantics require change.
- `apps/features/onboarding/lib/src/domain/models/onboarding_draft_snapshot.dart`
  - schema bump only if persisted representation truly changes.

Do **not** re-implement planner/controller scaffolding already merged from PR #50 unless the post-merge audit proves a contract gap.

---

## 4. Validation Matrix

### Eligibility

- Nutrition Lose → Target Weight + Goal Pace.
- Nutrition Gain → Target Weight + Goal Pace.
- Nutrition Maintain → both skipped.
- Nutrition Recomposition → both skipped.
- Workout Lose primary → both active.
- Workout Lose supporting → both active.
- Hybrid Lose primary → both active.
- Hybrid Lose supporting → both active.
- Build Muscle alone → both skipped.
- Get Stronger alone → both skipped.
- Improve Endurance alone → both skipped.
- Stay Fit alone → both skipped.
- Recomposition alone → both skipped.
- Build Muscle never implies Gain Weight.

### Recommendation / UX

- fresh eligible loss target is below current weight or no personalized recommendation is produced;
- fresh eligible gain target is above current weight or no personalized recommendation is produced;
- BMI guard never reverses explicit direction;
- saved user Target Weight restores exactly;
- user-edited value survives Back/Forward/Resume;
- recommendation is not reapplied over a user-edited value;
- displayed value and picker selection are identical.

### Resume / Draft

- restored now-ineligible Target Weight step reconciles safely;
- restored now-ineligible Goal Pace step reconciles safely;
- skipped default pace does not become user intent;
- reversible goal changes do not silently destroy previously entered eligible values unless an explicit product rule requires clearing;
- old draft versions restore safely.

### Goal Pace

- direction derives from explicit Goal intent;
- pace range validation remains valid;
- slider/haptics/projection visual behavior remains stable;
- calorie/BMR/TDEE recommendation is absent from Goal Pace ownership.

### Required Tests

At minimum review/update/add coverage in:

- `apps/features/onboarding/test/domain/weight_goal_flow_policy_test.dart`
- `apps/features/onboarding/test/domain/target_weight_recommendation_resolver_test.dart`
- `apps/features/onboarding/test/domain/profile_step_validator_test.dart`
- `apps/features/onboarding/test/domain/onboarding_controller_test.dart`
- `apps/features/onboarding/test/presentation/onboarding_controller_draft_persistence_test.dart`
- `apps/features/onboarding/test/data/onboarding_draft_snapshot_dto_mapper_test.dart`
- `apps/features/onboarding/test/presentation/profile_section_test.dart`
- `apps/features/onboarding/test/presentation/onboarding_flow_page_test.dart`
- focused `GoalPaceScreen` widget tests if calorie ownership/presentation changes.

Then run full Flutter/Dart analyzer and workspace tests.

---

## 5. Non-Goals

- measurement-screen redesign;
- Goal card redesign;
- canonical Body Goal / Body Measurement owner-schema migration;
- canonical Workout Goal owner migration;
- Supabase schema migration;
- Nutrition Calories / Protein / Carbs / Fat / Fiber implementation beyond removing misplaced Goal Pace ownership;
- Health Concerns / Injuries & Limitations;
- Special Event;
- Workout Profile / Equipment taxonomy;
- Plan Building / Congratulations.

---

## 6. Exit Criteria

PR #50 prerequisite:

- [ ] missing policy blocker corrected with smallest contract-consistent fix;
- [ ] PR #50 analyzer passes;
- [ ] PR #50 full workspace tests pass;
- [ ] PR #50 merged.

Slice 2B:

- [ ] merged baseline audited before implementation;
- [ ] approved eligibility matrix is the single runtime source of truth;
- [ ] recommendation never reverses explicit direction;
- [ ] user-entered Target Weight is not overwritten by recommendation;
- [ ] picker/display/draft value stay synchronized;
- [ ] Goal Pace contains no Nutrition calorie/BMR/TDEE ownership;
- [ ] skipped/default values do not become fake user intent;
- [ ] Next/Back/Resume/Progress/Validation all follow active plans;
- [ ] legacy draft restore remains migration-safe;
- [ ] no unauthorized visual redesign;
- [ ] no Supabase schema change unless separately approved for a proven representation need;
- [ ] full analyzer/tests green.

### Final Status

`BLOCKED` until PR #50 is corrected, green, and merged.
