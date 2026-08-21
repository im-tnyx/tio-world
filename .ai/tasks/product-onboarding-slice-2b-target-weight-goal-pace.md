# Product Onboarding Slice 2B — Target Weight and Goal Pace

**Status:** In progress  
**Primary owner:** `apps/features/onboarding`  
**Affected platforms:** Flutter phone app  
**GitHub tracker:** #40  
**Canonical implementation PR:** #50 `feat(onboarding): activate unified mode-aware Goal screen`  
**Canonical branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`  
**Owner execution decision:** keep one active implementation PR (#50) until the approved Goal + Target Weight + Goal Pace contract is complete and fully validated. Do not merge #50 to `main` yet.

---

## 0. Canonical Continuation Context — Read First

This file is the durable handoff. Continue from repository state here instead of relying on chat history.

### PR topology

#### PR #50 — only active implementation PR

- open, Draft, mergeable
- base: `main`
- head: `agent/onboarding-slice-2-step-1-body-goal-ui`
- post-consolidation code/test head was `1d0f25e241599b948b0d2d250b93e10e50656785`; subsequent task-only commits move the branch head but do not alter the consolidated production/test behavior.
- prior full green evidence: Flutter CI **#1057**, run id `32484593862`, on `ec125ed560fbbbf95ccfc031cccd8df3fe7c39c2`
  - Flutter analyze passed
  - Dart analyze passed
  - Flutter tests passed
  - Dart tests passed
- fresh post-consolidation CI **#1065**, run id `32487577655`, reached both Flutter and Dart analyzer success and was running Flutter tests at the latest audit.

Green CI proves technical consistency at that snapshot. It does not prove the remaining Product contract is complete.

#### PR #51 — closed, superseded, do not merge

Former stacked PR `feat(onboarding): enforce goal-aware weight follow-up eligibility`.

Its only two useful changes were copied into #50 and verified by matching blob content:

1. `apps/features/onboarding/test/domain/goal_weight_follow_up_flow_plan_test.dart`
   - blob `8a61872d37d68535821295d2d047f955e1ec92c3`
2. `apps/features/onboarding/test/domain/weight_goal_flow_policy_test.dart`
   - blob `a4ae3e658875ff131ebcc5b944e271b819846c8a`

PR #51 is closed and unmerged. All continuation happens on #50.

#### PR #52 — closed validation-only PR

- closed
- unmerged
- existed only to trigger `pull_request -> main` CI for the earlier stacked state
- no further action; do not reopen or merge.

### Single-PR execution

```text
PR #50 Draft
→ #51 eligibility tests consolidated ✅
→ finish Target Weight behavior
→ finish Goal Pace/draft semantics
→ full acceptance matrix
→ full CI green
→ update PR body to actual final scope
→ only then Ready/Merge decision
```

Do not create another 2B PR unless the owner explicitly changes this strategy.

---

## 1. Issue #40 Product / Ownership Contract

Issue #40 is canonical for Product Onboarding structure.

```text
Onboarding
= flow/order/step identity/draft-resume/review/finalization orchestration

Profile
= shared identity and baseline

Body / Wellness
= Body Goal and body metrics/goal plan

Nutrition
= Nutrition Profile + numeric Nutrition Targets

Workout
= Workout Profile + Workout Goals/Targets
```

A unified user-facing Goal screen is a presentation/orchestration decision and must not recreate a mixed canonical persistence owner.

### Dynamic Goal screen — already implemented in #50

#### Nutrition — single select

```text
Lose weight
Gain weight
Maintain weight
Recomposition
```

#### Workout / Hybrid — max 2 compatible

```text
Lose weight
Build muscle
Get stronger
Improve endurance
Stay fit
Recomposition
```

Rules:

- first = primary
- optional compatible second = supporting
- max 2
- `Build muscle` never means `Gain weight`
- no BODY GOAL / WORKOUT GOAL subgroup headings
- preserve existing Goal card visual/interaction language.

### Target Weight / Goal Pace eligibility

`GoalIntentSelection` is semantic authority.

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

Never infer body-weight direction from BMI, current/target delta, or a training-only intent.

Eligibility must be flow-plan level so Next, Back, Resume, restored drafts, progress, validation, and rendering all use the same active steps.

---

## 2. Measurement / Recommendation Contract

Do not redesign Height / Current Weight / Target Weight measurement UX.

Required invariant:

```text
visible value == selected picker position == canonical draft value
```

Initialization priority:

1. restore saved/resumed answer exactly;
2. Height / Current Weight with no answer use deterministic existing defaults with display and input synchronized;
3. fresh eligible Target Weight may receive a deterministic goal-aware recommendation when authoritative inputs are sufficient;
4. recommendation is only a starting selection and is user-adjustable;
5. after user adjustment, Back / Forward / Resume preserves the user's value and does not silently recalculate over it.

### Exact numeric recommendation rule is NOT locked

Current #50 scaffold uses:

- ±5% directional change
- BMI floor `18.5`
- gain guard `30.0`
- weight clamp `30..200 kg`

These values are implementation scaffold, not automatically an approved product/medical formula.

Before finalizing:

- audit whether an existing canonical repository/product policy owns these numbers;
- otherwise propose the exact deterministic rule for explicit approval;
- a safety guard may reduce/suppress a recommendation but must never reverse explicit loss/gain direction;
- insufficient authoritative input should produce a neutral deterministic state or no personalized recommendation, not invented certainty.

BMI/weight status may be a safety input only; it cannot choose the semantic goal.

---

## 3. Measurement Input / Picker Audit — Current Source Finding

### Audit result: current measurement input control is absent

Fresh audit of PR #50 branch confirmed:

- `HeightScreen` renders formatted height text + information card.
- `CurrentWeightScreen` renders formatted weight text + BMI information card.
- `TargetWeightScreen` renders formatted target text + target-analysis card.
- all three screens accept an `onChanged` callback but do **not** invoke/use that callback in their current screen bodies.
- `ProfileStepRenderer` only passes controller callbacks into these screens; it does not inject an input control.
- `ProfileScreenScaffold` only renders header + supplied child + error semantics; it does not inject a picker.

Repository code search at audit found no current indexed implementation for:

```text
ListWheelScrollView
CupertinoPicker
FixedExtentScrollController
MeasurementPicker
Wheel
picker
```

Commit search for `measurement` surfaced measurement-unit preference/editor work but no identifiable measurement wheel/picker implementation. The connector could not provide path-history lookup for these screen files, so historical picker source remains unproven.

### Consequence

Issue #40 says preserve the existing wheel/picker interaction, but the audited current source has no such input control. Therefore:

- do **not** invent a new picker visual/interaction from scratch;
- do **not** treat the current text-only screen as proof that picker removal was intended;
- before visual implementation, locate an approved source/reference (historical repo state, retained design/reference, or separately approved reusable picker contract);
- non-visual flow/state/persistence work can proceed independently where the contract is already explicit.

This audit is complete for **current source**. Historical/design-reference recovery remains a decision/input dependency for the visual measurement control.

---

## 4. Goal Pace Contract

- Goal Pace = weekly body-weight change only.
- direction comes only from explicit Goal intent / `GoalWeightDirection`.
- preserve slider, haptics, warnings, and projection visual language.
- Calories / BMR / TDEE belong to Nutrition Targets, not Goal Pace.
- skipped Goal Pace must not turn a compatibility default into fake user intent.

---

## 5. Already Done in PR #50

### Goal activation

- `GoalIntent`
- ordered `GoalIntentSelection(primaryGoal, supportingGoal)`
- mode-aware `GoalIntentSelectionPolicy`
- Nutrition single-select
- Workout/Hybrid compatible max-two behavior
- active `GoalIntentScreen`
- draft schema v3 Goal selection
- migration-aware v1/v2 restoration
- unsupported legacy mappings do not invent intent
- `Build muscle != Gain weight`.

### Follow-up scaffolding

- `GoalWeightDirection`
- `GoalWeightFollowUpPolicy`
- conditional Profile Target Weight plan
- conditional Targets Goal Pace plan
- current-step reconciliation helpers
- active child plans drive navigation
- state derives progress from active plans
- direction-aware Target Weight validation
- explicit Goal Pace direction path
- renderers receive explicit direction.

### Consolidated eligibility verification

Now directly on #50:

- Nutrition Lose/Gain active; Maintain/Recomposition skipped
- Workout/Hybrid Lose primary/supporting active
- training-only goals do not create body-weight direction
- Build muscle never becomes Gain weight
- missing mode activates no follow-up
- Target Weight and Goal Pace share eligibility source
- ineligible Target Weight reconciles to Current Weight
- ineligible Goal Pace reconciles to Water Target.

---

## 6. Current Audit Findings / Risks

### A. Target Weight is destructively cleared today

`OnboardingController` currently clears `targetWeightKg` when resolved weight direction changes during goal/mode changes.

This is not accepted final behavior.

Required target:

- reversible goal/mode changes should not silently destroy recoverable user-entered target intent;
- hidden/ineligible value may remain dormant but must not be consumed downstream;
- recommendation must never overwrite an existing user-entered value;
- direct loss↔gain semantics need explicit handling because one scalar target cannot safely represent both directions simultaneously.

Do not invent a new persistence representation without auditing the smallest migration-safe option.

### B. Recommendation seeds at runtime today

`OnboardingController._prepareProfileForStep(...)` seeds `TargetWeightRecommendationResolver` on eligible Target Weight when no target exists.

Concept approved; exact formula still gated by Section 2.

### C. Goal Pace still owns calorie logic

Current `GoalPaceScreen` still calculates/displays BMR/TDEE-like kcal values.

Must be removed from Goal Pace ownership while preserving pace/projection UX.

### D. Goal Pace default can look like user intent

`TargetsOnboardingDraft.goalPaceKgPerWeek` is non-null with default `0.5`; legacy restore also has default behavior.

```text
Goal Pace skipped + draft has 0.5
≠ user selected 0.5 kg/week
```

Choose the smallest migration-safe fix. Local snapshot schema changes only if representation truly changes. No Supabase schema change solely for this task.

### E. PR #50 description is stale

PR body still describes remaining 2B pieces as out of scope, but the owner decision is now to complete them inside #50 before merge. Update body after implementation stabilizes.

---

## 7. Execution Order on PR #50

### 2B-A0 — PR consolidation

- [x] copy #51 flow-plan matrix/reconciliation test into #50
- [x] copy #51 strengthened weight policy test into #50
- [x] verify matching blob content
- [x] close #51 unmerged as superseded
- [x] leave #52 closed/unmerged
- [ ] fresh #50 post-consolidation CI fully green (latest audited #1065 had analyzer green and Flutter tests running)

### 2B-A1 — eligibility/navigation truth

Audit/close gaps in:

- `GoalWeightFollowUpPolicy`
- `BuildProfileFlowPlanUseCase`
- `BuildTargetsFlowPlanUseCase`
- controller reconciliation
- `OnboardingState` progress flattening
- validators
- restored now-ineligible Target Weight/Goal Pace steps.

Acceptance:

- approved mode/goal matrix exact;
- Next/Back/Resume/Progress/Validation/rendering agree;
- hidden screens create no validation obligation;
- no training-only goal invents body-weight direction.

### 2B-B1 — non-visual Target Weight state/persistence

Can proceed without inventing picker UI:

1. audit current clearing behavior and reversible transitions;
2. define smallest migration-safe way to distinguish fresh recommendation vs preserved user intent if needed;
3. recommendation seeds only truly fresh eligible state;
4. user-entered value is never overwritten by recommendation;
5. hidden values are not consumed when ineligible;
6. exact numeric recommendation policy remains an approval gate.

### 2B-B2 — measurement input restoration/synchronization

Blocked on approved picker/reference evidence:

1. obtain historical/design/reusable picker reference;
2. restore/reuse without redesign;
3. enforce display = input selection = draft value;
4. verify kg/lb and height units;
5. verify Back/Forward/resume initialization.

### 2B-C — Goal Pace + draft semantics

- remove Calories/BMR/TDEE/kcal responsibility from Goal Pace;
- preserve slider/haptics/warnings/projection;
- direction only from explicit Goal intent;
- prevent skipped default `0.5` from becoming fake intent;
- restore old drafts safely;
- local snapshot bump only if needed.

### 2B-D — full acceptance

Matrix:

```text
Nutrition: Lose / Gain / Maintain / Recomposition
Workout: Lose primary / Lose supporting / each non-weight goal alone
Hybrid: same goal matrix + existing Workout Intro branch compatibility
```

Verify Next, Back, Resume, restored draft, progress/accessibility, validation, Target Weight state, user override, units, Goal Pace direction, and skipped/default semantics.

Then full Flutter/Dart analyze + tests required by repository CI.

---

## 8. Expected File Impact

Audit before editing.

### Flow / eligibility

- `apps/features/onboarding/lib/src/domain/usecases/goal_weight_follow_up_policy.dart`
- `apps/features/onboarding/lib/src/domain/usecases/weight_goal_flow_policy.dart`
- `apps/features/onboarding/lib/src/domain/usecases/build_profile_flow_plan_use_case.dart`
- `apps/features/onboarding/lib/src/domain/usecases/build_targets_flow_plan_use_case.dart`
- `apps/features/onboarding/lib/src/domain/usecases/build_onboarding_progress_plan_use_case.dart`
- `apps/features/onboarding/lib/src/presentation/controllers/onboarding_controller.dart`
- `apps/features/onboarding/lib/src/presentation/state/onboarding_state.dart`.

### Target Weight / measurements

- `apps/features/onboarding/lib/src/domain/usecases/target_weight_recommendation_resolver.dart`
- `apps/features/onboarding/lib/src/domain/usecases/profile_step_validator.dart`
- `apps/features/onboarding/lib/src/presentation/renderer/profile_step_renderer.dart`
- `apps/features/onboarding/lib/src/presentation/screens/profile/height_screen.dart`
- `apps/features/onboarding/lib/src/presentation/screens/profile/current_weight_screen.dart`
- `apps/features/onboarding/lib/src/presentation/screens/profile/target_weight_screen.dart`
- approved reusable/historical measurement input component once identified.

### Goal Pace / draft

- `apps/features/onboarding/lib/src/domain/usecases/goal_pace_resolver.dart`
- `apps/features/onboarding/lib/src/domain/usecases/target_step_validator.dart`
- `apps/features/onboarding/lib/src/presentation/renderer/target_step_renderer.dart`
- `apps/features/onboarding/lib/src/presentation/screens/targets/goal_pace_screen.dart`
- `apps/features/onboarding/lib/src/domain/models/targets_onboarding_draft.dart` only if needed
- `apps/features/onboarding/lib/src/data/mappers/onboarding_draft_snapshot_dto_mapper.dart` only if needed
- `apps/features/onboarding/lib/src/domain/models/onboarding_draft_snapshot.dart` only if representation changes.

### Tests

- `apps/features/onboarding/test/domain/goal_weight_follow_up_flow_plan_test.dart`
- `apps/features/onboarding/test/domain/weight_goal_flow_policy_test.dart`
- `apps/features/onboarding/test/domain/target_weight_recommendation_resolver_test.dart`
- `apps/features/onboarding/test/domain/profile_step_validator_test.dart`
- `apps/features/onboarding/test/domain/target_step_validator_test.dart`
- `apps/features/onboarding/test/domain/onboarding_controller_test.dart`
- `apps/features/onboarding/test/presentation/onboarding_controller_draft_persistence_test.dart`
- `apps/features/onboarding/test/data/onboarding_draft_snapshot_dto_mapper_test.dart`
- `apps/features/onboarding/test/presentation/profile_section_test.dart`
- `apps/features/onboarding/test/presentation/targets_section_test.dart`
- `apps/features/onboarding/test/presentation/onboarding_flow_page_test.dart`.

---

## 9. UI / Design-System Guardrails

Before Flutter UI changes read:

1. root `AGENTS.md`
2. `apps/features/AGENTS.md`
3. `.ai/tasks/design-system-token-consolidation.md`
4. `apps/core/lib/src/theme/README.md`
5. any more specific nested `AGENTS.md`.

Use existing `package:tio_core/core.dart` reusable surface first.

Mandatory:

- no Goal card redesign;
- no Height/Current Weight/Target Weight redesign;
- no invented picker design;
- preserve Goal Pace slider/projection visual language;
- preserve spacing, typography, unit treatment, motion, selected states, and accessibility semantics unless separately approved.

---

## 10. Non-Goals

Not authorized here:

- canonical Body Goal / Body Measurement owner schema migration;
- canonical Workout Goal owner migration;
- Supabase schema migration solely for this slice;
- Health Concerns / Injuries & Limitations implementation;
- Special Event changes;
- Workout Profile / Equipment taxonomy;
- Nutrition macro-target implementation beyond removing Goal Pace calorie ownership;
- Health Connections;
- Plan Building / Congratulations changes;
- unrelated onboarding redesign.

---

## 11. Exit Criteria Before PR #50 Ready/Merge

### PR topology

- [x] #51 useful tests consolidated into #50.
- [x] #51 closed unmerged as superseded.
- [x] #52 closed unmerged.
- [x] #50 is the only active implementation PR.

### Goal / eligibility

- [x] dynamic mode-aware Goal screen active.
- [x] Goal selection stores/restores migration-safely.
- [x] `Build muscle != Gain weight`.
- [x] consolidated eligibility/reconciliation tests are on #50.
- [ ] fresh post-consolidation CI fully green.
- [ ] final Next/Back/Resume/Progress/Validation matrix verified.

### Target Weight / measurements

- [x] current-source measurement input audit completed.
- [x] confirmed current screens/scaffold/renderer contain no actual picker/input control.
- [ ] approved historical/design/reusable picker reference identified before visual restoration.
- [ ] display = picker/input = draft value after restoration.
- [ ] exact recommendation numeric rule approved or sourced from canonical policy.
- [ ] recommendation never reverses explicit direction.
- [ ] recommendation only seeds fresh eligible state.
- [ ] user value survives Back/Forward/Resume.
- [ ] reversible goal/mode changes do not silently destroy recoverable user target intent.

### Goal Pace / draft

- [ ] no Calories/BMR/TDEE/kcal ownership in Goal Pace.
- [ ] explicit Goal intent is the only runtime direction semantic.
- [ ] slider/haptics/warnings/projection stable.
- [ ] skipped/default `0.5` is not fake user intent.
- [ ] legacy draft restore safe.

### Final technical validation

- [ ] focused tests pass.
- [ ] full Flutter analyze pass.
- [ ] full Dart analyze pass.
- [ ] full Flutter tests pass.
- [ ] full Dart tests pass.
- [ ] PR #50 body updated to match final actual scope/evidence.
- [ ] PR #50 stays Draft until all product + technical gates are satisfied.

### Final Status

`IN PROGRESS` on PR #50. Do not merge to `main` until exit criteria are satisfied.
