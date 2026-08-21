# Product Onboarding Slice 2B — Target Weight and Goal Pace

**Status:** Blocked
**Primary owner:** `apps/features/onboarding`
**Affected platforms:** Flutter phone app
**GitHub tracker:** #40
**Depends on:** PR #50 (`feat(onboarding): activate unified mode-aware Goal screen`) being corrected, green, and merged
**Planning base:** `main` at `751b9d66ba3a70a26d5339fdec546ff01261a69b`

## Global UI / Design-System Guardrail

This slice is primarily a flow/logic correction. It does **not** authorize a measurement-screen redesign.

Before any Flutter UI change, read and follow:

1. root `AGENTS.md`;
2. `apps/features/AGENTS.md`;
3. `.ai/tasks/design-system-token-consolidation.md`;
4. `apps/core/lib/src/theme/README.md`;
5. any more specific `AGENTS.md` under the changed path.

Inspect the existing reusable `package:tio_core/core.dart` UI surface before rebuilding any picker, slider, card, input, or measurement component.

Mandatory visual contract:

- preserve the existing Height / Current Weight / Target Weight measurement visual language;
- preserve the existing Goal Pace slider/projection visual language unless a separately approved UI decision says otherwise;
- do not introduce a new card, text field, slider, picker design, spacing system, typography treatment, unit treatment, or motion pattern merely to implement this slice;
- if the current runtime source no longer contains the approved historical wheel/picker implementation, audit and identify the intended reusable measurement interaction before making a visual replacement.

---

## 1. Discovery

### User Outcome

After the user chooses an explicit onboarding goal, Product Onboarding should show Target Weight and Goal Pace only when body-weight change is actually part of that chosen goal. When Target Weight is eligible, the screen should open with a deterministic goal-aware starting recommendation when enough authoritative measurements exist, while always allowing the user to choose a different valid value.

```text
GoalIntentSelection
        ↓
Goal-aware eligibility policy
        ├─ Target Weight active?
        └─ Goal Pace active?
                ↓
Flow-plan navigation / Back / Resume / Progress / Validation
                ↓
Target Weight deterministic starting recommendation
                ↓
User selection remains authoritative
                ↓
Goal Pace direction comes from explicit Goal intent
```

### Approved Eligibility Matrix

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

### Success Criteria

- Target Weight and Goal Pace visibility derives from explicit `GoalIntentSelection`, never from numeric weight differences.
- Nutrition `Lose weight` and `Gain weight` collect both Target Weight and Goal Pace.
- Nutrition `Maintain weight` and `Recomposition` skip both screens.
- Workout / Hybrid collect both only when `Lose weight` is selected in either allowed position.
- `Build muscle`, `Get stronger`, `Improve endurance`, `Stay fit`, and `Recomposition` do not independently imply a target body weight.
- Next, Back, resume, progress denominator/semantics, validation, and restored drafts use the same active flow plan.
- Displayed measurement value and picker/selection position represent the same canonical value.
- Existing saved user-entered values restore exactly.
- Fresh eligible Target Weight may receive a deterministic goal-aware starting recommendation when enough authoritative input exists.
- The recommendation is only an initial selection; user changes remain authoritative and survive Back/Forward and resume.
- BMI or underweight/overweight classification may act only as recommendation/safety input; it must not silently decide or replace the user's explicit goal.
- Goal Pace represents weekly body-weight change only for eligible weight-change goals.
- Goal Pace direction comes from explicit goal intent, not `targetWeight - currentWeight` inference.
- Skipped/default Target Weight or Goal Pace values do not become canonical user intent merely because legacy draft fields contain defaults.
- No Supabase schema change is required solely for this slice.
- Full analyzer and workspace tests pass before the slice is merge-ready.

### Scope

- goal-aware Target Weight / Goal Pace eligibility;
- nested Profile and Targets flow-plan inclusion/skip behavior;
- current-step reconciliation when goal/mode changes or a draft resumes;
- progress and accessibility semantics derived from active child plans;
- Target Weight initialization and recommendation behavior;
- exact restoration of saved user-entered measurement values;
- Goal Pace direction/validation cleanup;
- removal of calorie/BMR/TDEE ownership from Goal Pace where current presentation still performs Nutrition-target calculations;
- draft/resume semantics for skipped/default weight-follow-up values;
- focused unit/controller/widget tests and full CI validation.

### Non-Goals

- redesigning Height / Current Weight / Target Weight measurement UI;
- redesigning Goal Pace slider/projection UI;
- changing the approved Goal card UI from PR #50;
- canonical Body Goal / Body Measurement owner-schema migration;
- Supabase schema migration;
- Nutrition Calories / Protein / Carbs / Fat / Fiber recommendation implementation beyond removing misplaced ownership from Goal Pace;
- Health Concerns / Injuries & Limitations work;
- Special Event work;
- Workout Profile / Equipment taxonomy work;
- Plan Building / Congratulations work.

---

## 2. Codebase Exploration

### Verified Evidence

The following evidence was inspected on PR #50 branch `agent/onboarding-slice-2-step-1-body-goal-ui` at head `85305129bad490b030c236ae2ad766e6b955fa2f` unless otherwise noted.

#### Flow policy/plans

- `apps/features/onboarding/lib/src/domain/usecases/build_profile_flow_plan_use_case.dart`
  - already expects `GoalWeightFollowUpPolicy`;
  - conditionally removes `ProfileStepId.targetWeight`;
  - contains current-step reconciliation.
- `apps/features/onboarding/lib/src/domain/usecases/build_targets_flow_plan_use_case.dart`
  - already expects `GoalWeightFollowUpPolicy`;
  - conditionally removes `TargetStepId.goalPace`;
  - contains current-step reconciliation.
- `apps/features/onboarding/lib/src/domain/usecases/weight_goal_flow_policy.dart`
  - retained as a compatibility name around `GoalWeightFollowUpPolicy`.
- PR #50 currently imports `goal_weight_follow_up_policy.dart`, but that file is missing at the inspected head and CI fails analyzer because of that incomplete wiring. This task must not begin implementation until PR #50 is corrected and green.

#### Target recommendation / pace semantics

- `apps/features/onboarding/lib/src/domain/usecases/target_weight_recommendation_resolver.dart`
  - already contains a deterministic directional recommendation scaffold;
  - currently applies explicit loss/gain direction and BMI-based guardrails;
  - needs contract-aligned tests and final behavior review.
- `apps/features/onboarding/lib/src/domain/usecases/goal_pace_resolver.dart`
  - already exposes `resolveModeForDirection(GoalWeightDirection?)`;
  - retains numeric-difference inference only as a deprecated compatibility helper.

#### Controller / state wiring

- `apps/features/onboarding/lib/src/presentation/controllers/onboarding_controller.dart`
  - already computes goal direction;
  - already rebuilds Profile/Targets plans around goal selection;
  - already contains Target Weight recommendation preparation hooks;
  - currently clears Target Weight when weight-goal direction changes; preservation semantics must be reviewed against the approved reversible goal/mode-change contract.
- `apps/features/onboarding/lib/src/presentation/state/onboarding_state.dart`
  - derives `profileFlowPlan`, `targetsFlowPlan`, `weightGoalDirection`, and flattened progress from the active draft.

#### Screens / renderers

- `apps/features/onboarding/lib/src/presentation/renderer/profile_step_renderer.dart`
  - passes current weight, height, unit, explicit weight direction, and target value into `TargetWeightScreen`.
- `apps/features/onboarding/lib/src/presentation/screens/profile/target_weight_screen.dart`
  - currently renders a value plus direction-aware analysis card;
  - current `main` and inspected PR #50 file do not show the approved historical wheel/picker interaction inside this source file, so the implementation slice must first locate/reconcile the intended measurement picker implementation rather than inventing a new design.
- `apps/features/onboarding/lib/src/presentation/renderer/target_step_renderer.dart`
  - passes explicit `weightGoalDirection` into `GoalPaceScreen` and currently force-unwraps it; active-plan eligibility must guarantee that this render path is valid.
- `apps/features/onboarding/lib/src/presentation/screens/targets/goal_pace_screen.dart`
  - preserves the existing slider/projection presentation;
  - currently also calculates/displays BMR/TDEE-derived calorie values, which conflicts with the approved ownership rule that calorie/BMR/TDEE recommendation belongs to Nutrition Targets rather than Goal Pace.

#### Draft / persistence

- `apps/features/onboarding/lib/src/domain/models/profile_onboarding_draft.dart`
  - `targetWeightKg` is nullable and supports clearing.
- `apps/features/onboarding/lib/src/domain/models/targets_onboarding_draft.dart`
  - `goalPaceKgPerWeek` is currently non-null with default `0.5`;
  - the slice must prevent that compatibility default from becoming user-selected intent when Goal Pace is skipped.
- `apps/features/onboarding/lib/src/data/mappers/onboarding_draft_snapshot_dto_mapper.dart`
  - currently serializes `goal_pace_kg_per_week` directly;
  - missing legacy pace decodes to `0.5`;
  - restoration/eligibility reconciliation must be audited before deciding whether schema representation itself must change.

#### Existing tests

- `apps/features/onboarding/test/domain/weight_goal_flow_policy_test.dart`
- `apps/features/onboarding/test/domain/target_weight_recommendation_resolver_test.dart`
- `apps/features/onboarding/test/domain/profile_step_validator_test.dart`
- `apps/features/onboarding/test/domain/onboarding_controller_test.dart`
- `apps/features/onboarding/test/presentation/onboarding_controller_draft_persistence_test.dart`
- `apps/features/onboarding/test/data/onboarding_draft_snapshot_dto_mapper_test.dart`
- `apps/features/onboarding/test/presentation/profile_section_test.dart`
- `apps/features/onboarding/test/presentation/onboarding_flow_page_test.dart`

Current recommendation tests also require contract review: some inspected expected values would reverse the requested direction after a BMI guard, while the resolver's final guard rejects direction reversal. Tests and implementation must agree that safety guardrails may reduce or suppress a recommendation but may not silently reverse the explicit user goal.

### Existing Pattern to Follow

- Use pure Dart policies/use cases for eligibility, recommendation, and semantic direction.
- Build conditional child lists in `ProfileFlowPlan` / `TargetsFlowPlan`.
- Let controller/state derive navigation, progress, resume, and validation from those same plans.
- Preserve visual components; change behavior/data wiring rather than creating parallel screens.

---

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Nutrition Lose/Gain show Target Weight + Goal Pace | Approved | explicit body-weight change intent | Product / #40 |
| Nutrition Maintain skips both | Approved | no weekly body-weight change target required | Product / #40 |
| Nutrition Recomposition skips both for this onboarding contract | Approved | no automatic target-body-weight assumption | Product / #40 |
| Workout/Hybrid Lose Weight in primary or supporting position shows both | Approved | explicit loss intent is authoritative | Product / #40 |
| Build Muscle must not map to Gain Weight | Approved | training outcome != body-weight direction | Product / #40 |
| BMI/weight classification must not choose user goal | Approved | explicit `GoalIntent` is authoritative | Product / #40 |
| Existing measurement and pace visual language is preserved | Approved | this is flow/logic correction, not redesign | Product / #40 |
| User-edited Target Weight survives Back/Forward/resume | Approved | user selection outranks recommendation | Product / #40 |
| Goal Pace calorie/BMR/TDEE ownership moves out of Goal Pace | Approved | Nutrition Targets owns calorie recommendation | Product / #40 |
| Whether `goalPaceKgPerWeek` becomes nullable/answered-state or remains compatibility-default plus eligibility metadata | Needs implementation audit | choose smallest migration-safe representation that prevents fake intent | Onboarding architecture |
| Exact reusable wheel/picker source to preserve for measurement screens | Needs source audit before UI edits | current inspected Target Weight source does not contain it | Onboarding + core UI |

---

## 4. Architecture Design

### Chosen Approach

Create one explicit goal-weight follow-up policy as the source of truth for both Target Weight and Goal Pace eligibility and direction. Use it only from flow planning, controller/state orchestration, validation, recommendation, and presentation metadata. Do not let the screens infer semantic goal direction from measurements.

```text
GoalIntentSelection + AppMode
        ↓
GoalWeightFollowUpPolicy
        ├─ GoalWeightDirection? loss/gain/null
        ├─ shouldCollectTargetWeight
        └─ shouldCollectGoalPace
                ↓
BuildProfileFlowPlanUseCase / BuildTargetsFlowPlanUseCase
                ↓
OnboardingController / OnboardingState
                ↓
Next / Back / Resume / Progress / Validation / Renderer
```

Target recommendation:

```text
Explicit eligible direction
+ currentWeightKg
+ heightCm when available
        ↓
TargetWeightRecommendationResolver
        ↓
Deterministic starting target OR no personalized recommendation
        ↓
User adjusts value
        ↓
Stored user value becomes authoritative
```

### Ownership and Data Flow

```text
Goal UI intent
→ Onboarding goal-selection draft
→ goal-weight follow-up policy
→ conditional flow plans
→ Target Weight / Goal Pace temporary onboarding draft values
→ later canonical Body owner migration in a separate approved slice
```

This slice must not recreate mixed owner persistence. `GoalIntentSelection` remains an onboarding orchestration contract, not a durable canonical owner field.

### Alternative Rejected

- Infer gain/loss from `targetWeight - currentWeight`: rejected because measurement deltas must not decide semantic user intent.
- Infer goal from BMI/underweight/overweight status: rejected because health classification is not user intent.
- Map `Build muscle` to `Gain weight`: rejected because training hypertrophy intent and body-weight gain are not equivalent.
- Always show Target Weight/Goal Pace and ignore irrelevant values later: rejected because navigation, progress, resume, validation, and persistence semantics would disagree.
- Rebuild measurement UI to solve initialization: rejected; behavior must be corrected while preserving approved visual interaction.

### Failure and Accessibility States

- If insufficient authoritative inputs exist for a safe personalized Target Weight recommendation, use a neutral deterministic starting state/value and do not claim personalization.
- If a restored draft points to a now-ineligible Target Weight or Goal Pace step, reconcile to a valid active step without losing unrelated draft answers.
- Hidden/skipped compatibility defaults must not be announced or persisted as user-selected intent.
- Progress semantics must reflect the actual active screen count after conditional skips.
- Existing measurement and slider semantics/haptics should be preserved unless a bug prevents accessible operation.

---

## 5. Planned File Impact

### Domain policy and flow planning

- [ ] `apps/features/onboarding/lib/src/domain/usecases/goal_weight_follow_up_policy.dart`
  - provide one explicit policy API for direction + Target Weight/Goal Pace eligibility;
  - cover the approved mode/goal matrix;
  - never map Build Muscle to Gain Weight.
- [ ] `apps/features/onboarding/lib/src/domain/usecases/weight_goal_flow_policy.dart`
  - keep only a bounded compatibility adapter if still required after PR #50;
  - avoid duplicate business rules.
- [ ] `apps/features/onboarding/lib/src/domain/usecases/build_profile_flow_plan_use_case.dart`
  - include/skip `ProfileStepId.targetWeight` from the policy;
  - reconcile current child step safely.
- [ ] `apps/features/onboarding/lib/src/domain/usecases/build_targets_flow_plan_use_case.dart`
  - include/skip `TargetStepId.goalPace` from the same policy;
  - reconcile current child step safely.
- [ ] `apps/features/onboarding/lib/src/domain/usecases/build_onboarding_progress_plan_use_case.dart`
  - verify no special-case logic is required; active child plans should automatically produce the correct progress denominator and semantics.

### Recommendation and validation

- [ ] `apps/features/onboarding/lib/src/domain/usecases/target_weight_recommendation_resolver.dart`
  - finalize deterministic loss/gain starting recommendation behavior;
  - enforce safety guardrails without reversing explicit direction;
  - return no personalized recommendation when inputs are insufficient.
- [ ] `apps/features/onboarding/lib/src/domain/usecases/goal_pace_resolver.dart`
  - make explicit `GoalWeightDirection` the runtime semantic path;
  - retain numeric-difference helper only for bounded legacy compatibility if still needed.
- [ ] `apps/features/onboarding/lib/src/domain/usecases/profile_step_validator.dart`
  - validate only active Target Weight steps;
  - loss target must be below current weight;
  - gain target must be above current weight.
- [ ] `apps/features/onboarding/lib/src/domain/usecases/target_step_validator.dart`
  - validate Goal Pace only for an active weight-change direction;
  - do not allow a skipped compatibility default to create a validation/persistence obligation.

### Draft / restore / persistence semantics

- [ ] `apps/features/onboarding/lib/src/domain/models/profile_onboarding_draft.dart`
  - verify Target Weight clearing/preservation semantics support reversible goal/mode changes without overwriting user-entered values.
- [ ] `apps/features/onboarding/lib/src/domain/models/targets_onboarding_draft.dart`
  - decide the smallest migration-safe representation that distinguishes a compatibility default from user-selected Goal Pace intent;
  - prefer explicit nullable/answered semantics only if required; do not bump schema mechanically.
- [ ] `apps/features/onboarding/lib/src/data/mappers/onboarding_draft_snapshot_dto_mapper.dart`
  - safely decode legacy drafts;
  - preserve user-entered eligible values;
  - prevent skipped/default fields from becoming active intent merely through deserialization.
- [ ] `apps/features/onboarding/lib/src/domain/models/onboarding_draft_snapshot.dart`
  - bump local draft schema only if the persisted representation actually changes and migration tests justify it.

### Controller / state / navigation

- [ ] `apps/features/onboarding/lib/src/presentation/controllers/onboarding_controller.dart`
  - rebuild Profile/Targets plans when mode/goal changes;
  - reconcile invalid current child steps;
  - initialize Target Weight only when entering an eligible screen with no saved user target;
  - never overwrite a saved/user-edited target on Back/Forward or resume;
  - review whether changing away from a weight goal should retain the user value in reversible draft state instead of clearing it;
  - ensure skipped Goal Pace compatibility values are not consumed as user intent.
- [ ] `apps/features/onboarding/lib/src/presentation/state/onboarding_state.dart`
  - keep flow plans, direction, Back availability, progress count/value, and semantics aligned with the same policy.

### Presentation

- [ ] `apps/features/onboarding/lib/src/presentation/renderer/profile_step_renderer.dart`
  - verify canonical value, unit, measurements, and explicit direction wiring.
- [ ] `apps/features/onboarding/lib/src/presentation/screens/profile/height_screen.dart`
  - audit value/picker initialization only if the shared picker mismatch affects this screen; no redesign.
- [ ] `apps/features/onboarding/lib/src/presentation/screens/profile/current_weight_screen.dart`
  - audit value/picker initialization only if the shared picker mismatch affects this screen; BMI may inform safety copy but not goal semantics.
- [ ] `apps/features/onboarding/lib/src/presentation/screens/profile/target_weight_screen.dart`
  - ensure displayed value and actual selector position are the same canonical value;
  - present the seeded recommendation as an editable starting value;
  - preserve approved visual language;
  - audit/restore the intended reusable wheel/picker instead of inventing a new UI if current source is incomplete.
- [ ] `apps/features/onboarding/lib/src/presentation/renderer/target_step_renderer.dart`
  - guarantee Goal Pace only renders when direction is valid; remove unsafe assumptions if needed.
- [ ] `apps/features/onboarding/lib/src/presentation/screens/targets/goal_pace_screen.dart`
  - preserve slider/projection interaction;
  - use explicit loss/gain direction;
  - remove BMR/TDEE/calorie recommendation ownership from this screen and leave it to Nutrition Targets.

### Public exports

- [ ] `apps/features/onboarding/lib/src/domain/usecases/usecases.dart`
  - export the final policy/resolver surface once implementation naming is settled.

---

## 6. Test Plan

### Policy matrix

- [ ] `apps/features/onboarding/test/domain/weight_goal_flow_policy_test.dart`
  - Nutrition Lose -> loss + both follow-ups;
  - Nutrition Gain -> gain + both follow-ups;
  - Nutrition Maintain -> no direction + skip both;
  - Nutrition Recomposition -> no direction + skip both;
  - Workout/Hybrid Lose as primary -> loss + both;
  - Workout/Hybrid Lose as supporting -> loss + both;
  - Build Muscle/Get Stronger/Improve Endurance/Stay Fit/Recomposition alone -> skip both;
  - Build Muscle never becomes Gain Weight.

### Target recommendation

- [ ] `apps/features/onboarding/test/domain/target_weight_recommendation_resolver_test.dart`
  - deterministic same-input same-output behavior;
  - loss recommendation remains below current weight;
  - gain recommendation remains above current weight;
  - safety guard may reduce/suppress recommendation but never reverse direction;
  - no direction -> no personalized recommendation;
  - insufficient measurements -> neutral/no personalized recommendation according to the final chosen API.

### Validation

- [ ] `apps/features/onboarding/test/domain/profile_step_validator_test.dart`
  - loss target must be lower;
  - gain target must be higher;
  - range checks remain intact.
- [ ] add/update Goal Pace validator tests
  - active loss/gain pace range;
  - skipped/non-direction path does not fabricate a requirement.

### Controller / flow / resume

- [ ] `apps/features/onboarding/test/domain/onboarding_controller_test.dart`
  - mode/goal changes rebuild active child plans;
  - current Target Weight/Goal Pace step reconciles safely when it becomes hidden;
  - recommendation seeds only when no user target exists;
  - user-edited target is not recalculated/overwritten;
  - reversible goal changes preserve allowed draft values according to the finalized preservation policy.
- [ ] `apps/features/onboarding/test/presentation/onboarding_controller_draft_persistence_test.dart`
  - Back/Forward preserves target;
  - resume preserves target;
  - hidden compatibility defaults are not treated as active intent.
- [ ] `apps/features/onboarding/test/data/onboarding_draft_snapshot_dto_mapper_test.dart`
  - legacy v1/v2/v3 restoration remains safe;
  - add a new schema case only if representation changes.

### Widget / progress

- [ ] `apps/features/onboarding/test/presentation/profile_section_test.dart`
  - Target Weight visible/hidden matrix;
  - canonical display/selector initialization where testable.
- [ ] `apps/features/onboarding/test/presentation/onboarding_flow_page_test.dart`
  - active screen count/progress semantics change correctly with eligibility.
- [ ] add/update Goal Pace widget tests
  - loss/gain copy/slider/projection direction;
  - no calorie/BMR/TDEE recommendation ownership remains in Goal Pace after cleanup.

### Full validation

```text
flutter analyze
flutter test for all Flutter packages
Dart package analyze/tests where workspace CI requires them
full GitHub Flutter CI
```

No merge readiness claim until all required analyzer/tests are green.

---

## 7. Implementation Order

1. **Precondition:** fix PR #50 missing/incomplete `GoalWeightFollowUpPolicy` wiring and merge PR #50 green.
2. Re-audit exact post-merge source because PR #50 may change while being fixed.
3. Lock one policy API and focused eligibility tests.
4. Activate conditional Profile/Targets flow plans and current-step reconciliation.
5. Align controller/state navigation, progress, Back, resume, and validation.
6. Fix measurement initialization using the existing approved picker interaction.
7. Finalize deterministic Target Weight recommendation and preservation semantics.
8. Clean Goal Pace semantic direction and remove Nutrition calorie/BMR/TDEE ownership from the Goal Pace presentation.
9. Reconcile draft serialization/default semantics; bump draft schema only if truly required.
10. Run focused tests, full analyzer/tests, and device acceptance for Nutrition/Workout/Hybrid paths.

---

## 8. Acceptance Matrix

| Mode | Goal selection | Target Weight | Goal Pace | Direction |
|---|---|---:|---:|---|
| Nutrition | Lose weight | Show | Show | Loss |
| Nutrition | Gain weight | Show | Show | Gain |
| Nutrition | Maintain weight | Skip | Skip | None |
| Nutrition | Recomposition | Skip | Skip | None |
| Workout | Lose weight | Show | Show | Loss |
| Workout | Get stronger + Lose weight | Show | Show | Loss |
| Workout | Build muscle + Get stronger | Skip | Skip | None |
| Hybrid | Lose weight + Improve endurance | Show | Show | Loss |
| Hybrid | Recomposition + Get stronger | Skip | Skip | None |
| Hybrid | Build muscle + Get stronger | Skip | Skip | None |

For every Show case:

- saved draft value restores exactly;
- fresh Target Weight receives deterministic goal-aware starting recommendation when safe inputs exist;
- user may change recommendation;
- user change survives navigation/resume;
- direction is not inferred from numeric delta.

For every Skip case:

- step is absent from active child plan;
- Back/Next/progress/resume agree that it is absent;
- compatibility/default value is not consumed as canonical user intent.

---

## 9. Quality Review

### Validation Run

```text
Not run yet. This task is documentation/planning only and remains blocked on PR #50.
```

### Review Findings and Resolution

- PR #50 current head contains incomplete policy wiring and cannot be used as a clean implementation base until corrected.
- The approved #40 contract is detailed enough to freeze this slice without further product clarification.
- Draft Goal Pace default semantics and the exact measurement wheel/picker source require implementation-time source audit, but neither blocks task creation.

---

## 10. Final Handoff

### Changed Files

Planning task only:

```text
.ai/tasks/product-onboarding-slice-2b-target-weight-goal-pace.md
.ai/tasks/README.md
```

### Actual Behavior

No runtime behavior changed by this task document.

### Known Limitations

- Implementation is blocked until PR #50 is corrected, green, and merged.
- Exact post-merge file list may shrink or shift after PR #50 fixes.
- Canonical Body owner migration remains a separate later concern.

### Exit Criteria

Task may move from `Blocked` to `Ready` when:

- PR #50 is merged green;
- post-merge source is re-audited;
- no new conflict exists with Issue #40 approved Target Weight / Goal Pace contract.

Task becomes `Validated` only after implementation is merged with analyzer/tests/CI and required device acceptance passing.

### Final Status

`BLOCKED`
