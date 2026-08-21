# Product Onboarding Slice 2B — Target Weight and Goal Pace

**Status:** In progress  
**Primary owner:** `apps/features/onboarding`  
**Affected platforms:** Flutter phone app  
**GitHub tracker:** #40  
**Canonical implementation PR:** #50 `feat(onboarding): activate unified mode-aware Goal screen`  
**Canonical branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`  
**Execution decision:** keep one active implementation PR (#50) until the approved Goal + Target Weight + Goal Pace contract is complete and fully validated. Do not merge #50 to `main` yet.

---

## 0. Canonical continuation context — read first

This file is the durable handoff. Continue from repository state here instead of relying on chat history.

### PR topology

- **PR #50** is the only active implementation PR. It is Draft, based on `main`, and must stay unmerged until this task's exit criteria are satisfied.
- **PR #51** is closed and unmerged as superseded. Its only two useful test changes were copied into #50:
  - `apps/features/onboarding/test/domain/goal_weight_follow_up_flow_plan_test.dart`, blob `8a61872d37d68535821295d2d047f955e1ec92c3`
  - `apps/features/onboarding/test/domain/weight_goal_flow_policy_test.dart`, blob `a4ae3e658875ff131ebcc5b944e271b819846c8a`
- **PR #52** is closed and unmerged. It was validation-only and must not be reopened or merged.
- Consolidated production/test behavior was on #50 before later task-only audit commits. Prior full-green evidence is Flutter CI **#1057** on `ec125ed560fbbbf95ccfc031cccd8df3fe7c39c2`; post-consolidation analyzers also passed on later runs. Task-only commits may move the branch head without changing runtime behavior.

```text
PR #50 Draft
→ eligibility tests consolidated ✅
→ Target Weight state/persistence
→ measurement input restoration when approved reference exists
→ Goal Pace/draft semantics
→ full acceptance matrix
→ full CI green
→ PR body updated to actual final scope
→ only then Ready/Merge decision
```

Do not create another Slice 2B PR unless the owner explicitly changes this strategy.

---

## 1. Issue #40 product / ownership contract

Issue #40 is canonical for Product Onboarding structure.

```text
Onboarding = flow/order/step identity/draft-resume/review/finalization orchestration
Profile = shared identity and baseline
Body / Wellness = Body Goal and body metrics/goal plan
Nutrition = Nutrition Profile + numeric Nutrition Targets
Workout = Workout Profile + Workout Goals/Targets
```

A unified user-facing Goal screen is an onboarding presentation/orchestration decision. It must not recreate a mixed canonical persistence owner.

### Dynamic Goal screen — already implemented in #50

**Nutrition, single-select**

```text
Lose weight
Gain weight
Maintain weight
Recomposition
```

**Workout / Hybrid, max 2 compatible**

```text
Lose weight
Build muscle
Get stronger
Improve endurance
Stay fit
Recomposition
```

Rules:

- first selection = primary;
- optional compatible second = supporting;
- max 2;
- `Build muscle` never means `Gain weight`;
- no BODY GOAL / WORKOUT GOAL subgroup headings;
- preserve existing Goal card visual/interaction language.

### Target Weight / Goal Pace eligibility

`GoalIntentSelection` is semantic authority.

```text
Nutrition Lose            → Target Weight + Goal Pace
Nutrition Gain            → Target Weight + Goal Pace
Nutrition Maintain        → skip both
Nutrition Recomposition   → skip both

Workout/Hybrid Lose primary or supporting → Target Weight + Goal Pace
Workout/Hybrid training-only goals alone   → skip both
```

Never infer body-weight direction from BMI, current-target difference, or a training-only goal. Eligibility must live at flow-plan level so Next, Back, Resume, progress, validation, restored drafts, and rendering agree.

---

## 2. Measurement / recommendation contract

Do not redesign Height / Current Weight / Target Weight measurement UX.

Required invariant:

```text
visible value == selected input position == canonical draft value
```

Initialization priority:

1. restore saved/resumed answer exactly;
2. Height / Current Weight with no answer use deterministic existing defaults and keep display/input synchronized;
3. fresh eligible Target Weight may receive a deterministic goal-aware recommendation when authoritative inputs are sufficient;
4. recommendation is only a starting selection and remains user-adjustable;
5. after user adjustment, Back / Forward / Resume preserves the user's value and does not silently recalculate over it.

### Exact numeric recommendation rule is not approved yet

Current scaffold uses:

- ±5% directional change;
- BMI floor `18.5`;
- gain BMI guard `30.0`;
- weight clamp `30..200 kg`.

Current tests assert examples such as `80 kg → 76 kg` for loss and `80 kg → 84 kg` for gain. Those tests prove current implementation behavior, not product/medical approval.

Before finalizing the formula:

- locate a canonical repository/product policy if one exists;
- otherwise obtain explicit approval for the exact deterministic rule;
- safety guards may reduce/suppress a recommendation but never reverse explicit direction;
- insufficient authoritative input must not fabricate personalized certainty.

BMI/weight status may be a safety input only. It cannot choose the semantic goal.

---

## 3. Measurement input / picker audit

### Current-source finding: actual measurement input control is absent

Fresh audit of #50 confirms:

- `HeightScreen` renders formatted height text + information card;
- `CurrentWeightScreen` renders formatted weight text + BMI card;
- `TargetWeightScreen` renders formatted target text + target-analysis card;
- all three accept `onChanged` but do not use/invoke it in their screen bodies;
- `ProfileStepRenderer` only passes controller callbacks;
- `ProfileScreenScaffold` only renders header + supplied child + errors and injects no picker/input.

Repository search found no current indexed implementation for `ListWheelScrollView`, `CupertinoPicker`, `FixedExtentScrollController`, `MeasurementPicker`, or an identifiable wheel/picker component. Commit search surfaced measurement-unit editor work but no historical measurement wheel. Connector path-history lookup was unavailable, so historical picker source remains unproven.

### Consequence

Issue #40 says preserve the existing wheel/picker interaction, but audited current source has no such input control.

Therefore:

- do not invent a new picker visual/interaction;
- do not assume current text-only screens prove picker removal was intended;
- obtain an approved historical/design/reusable reference before visual restoration;
- non-visual state/persistence work may proceed where the contract is explicit.

---

## 4. Already done in #50

### Goal activation

- `GoalIntent`;
- ordered `GoalIntentSelection(primaryGoal, supportingGoal)`;
- mode-aware selection policy;
- Nutrition single-select;
- Workout/Hybrid compatible max-two behavior;
- active `GoalIntentScreen`;
- draft schema v3 Goal selection;
- migration-aware v1/v2 restore;
- unsupported legacy mappings do not invent intent;
- `Build muscle != Gain weight`.

### Follow-up scaffolding

- `GoalWeightDirection`;
- `GoalWeightFollowUpPolicy`;
- conditional Profile Target Weight plan;
- conditional Targets Goal Pace plan;
- current-step reconciliation helpers;
- active child plans drive navigation/progress;
- direction-aware Target Weight validation;
- explicit Goal Pace direction path;
- renderers receive explicit direction.

### Consolidated eligibility verification

- Nutrition Lose/Gain active, Maintain/Recomposition skipped;
- Workout/Hybrid Lose primary/supporting active;
- training-only goals do not create body-weight direction;
- Build muscle never becomes Gain weight;
- missing mode activates no weight follow-up;
- Target Weight and Goal Pace share eligibility source;
- ineligible Target Weight reconciles to Current Weight;
- ineligible Goal Pace reconciles to Water Target.

---

## 5. 2B-B1 Target Weight state/persistence audit — completed findings

### Finding B1-1 — destructive clearing exists in two runtime paths

`OnboardingController` currently clears `profile.targetWeightKg` when resolved weight direction changes in both:

- `selectMode(...)`;
- `_updateGoalSelection(...)`.

This can destroy a user-entered Target Weight when the user temporarily moves to an ineligible goal/mode and later returns.

**Do not implement a simple "remove both clears" patch by itself.** Hidden stale values are currently consumed unconditionally by owner mappers, so preservation without consumption gating creates another bug.

### Finding B1-2 — recommendation is stored as the same scalar as user input

`_prepareProfileForStep(...)` seeds `TargetWeightRecommendationResolver` when entering/restoring Target Weight with `targetWeightKg == null`.

`ProfileOnboardingDraft` stores only:

```text
double? targetWeightKg
```

There is no recommendation/user-source marker and no direction association metadata. `updateProfileTargetWeight(...)` writes the same scalar.

Current behavior already guarantees one useful invariant: once a non-null target exists, `_prepareProfileForStep(...)` does not overwrite it with another recommendation. However, the model cannot identify which weight direction a dormant target belonged to after the current goal becomes ineligible.

### Finding B1-3 — draft serialization preserves value but not provenance/direction association

Draft snapshot schema is currently **v3**. DTO serialization stores `target_weight_kg` directly but no target-direction/source metadata.

If the user has a loss target, switches to Maintain/Recomposition, saves/resumes, and later switches to another eligible goal, the stored scalar alone cannot robustly distinguish same-direction restoration from an incompatible opposite-direction historical target.

### Finding B1-4 — owner persistence consumes hidden Target Weight unconditionally

`ProfileSetupMapper.map(ProfileOnboardingDraft)` always forwards:

```text
targetWeightKg: draft.targetWeightKg
```

It receives no App Mode / Goal eligibility context.

`PersistOnboardingOwnerDataUseCase` calls `profileMapper.map(draft.profile)` without goal context.

So if a dormant Target Weight is preserved while the current goal is ineligible, current Profile owner persistence would still consume it when durable completion is later enabled.

### Finding B1-5 — Targets persistence has the same problem

`TargetsSetupMapper` currently forwards, without eligibility context:

- `goalPaceKgPerWeek`;
- `profileDraft.targetWeightKg`;
- current measurements;
- nutrition recommendation context.

`PersistOnboardingOwnerDataUseCase` calls it with Profile + Targets drafts only. It does not pass `selectedMode`, `GoalIntentSelection`, active Profile/Targets flow plans, or `GoalWeightDirection`.

Therefore hidden Target Weight and skipped Goal Pace defaults are not protected at the canonical consumption boundary.

### Finding B1-6 — validation is not the main defect

`ProfileStepValidator` correctly validates Target Weight against explicit `GoalWeightDirection` and does not infer semantic intent from numeric delta.

`TargetStepValidator` also uses explicit direction for Goal Pace.

`OnboardingState` derives Profile/Targets plans and direction from the same explicit `GoalIntentSelection`. Flow truth is already centralized enough for B1.

### Finding B1-7 — current completion gate masks but does not solve persistence defects

`OnboardingCompletionValidator` defaults `hasDurableOwnerPersistence = false`, so Finish is currently blocked in the default runtime until owner persistence is enabled.

This prevents the hidden-value bug from leaking through Finish today, but the mapper contract must be corrected before durable completion is enabled.

### Finding B1-8 — focused tests are missing

Current tests do not directly prove:

- Target Weight survives eligible → ineligible → same eligible goal transitions;
- Target Weight survives draft save/resume while temporarily ineligible;
- recommendation is not re-seeded over a preserved user value;
- opposite-direction transitions are handled deliberately;
- hidden Target Weight is excluded from owner persistence;
- skipped Goal Pace default is excluded from owner persistence.

Existing mapper tests currently encode unconditional forwarding behavior.

---

## 6. 2B-B1 decision gate — smallest robust model

### What is already clear

A recommendation-vs-user **source marker is not yet proven necessary** for B1. A non-null target already prevents automatic recommendation overwrite, and the contract does not require recalculating an untouched recommendation after measurements change.

The unresolved need is **direction association / incompatible-direction handling**.

### Option A — no new metadata

Preserve the scalar across ineligible goals and use the current explicit goal plus numeric validation to decide whether it can be active again.

Pros:

- no schema bump;
- smallest code change.

Cons:

- after save/resume while ineligible, previous semantic direction is lost;
- opposite-direction historical values are ambiguous;
- current-weight changes can make an old same-direction target numerically invalid without revealing whether it is historical, user-edited, or opposite-direction;
- cannot truthfully restore direction-specific intent in all reversible cases.

**Audit result:** acceptable only if product explicitly accepts these limitations. Not preferred for robust reversible resume behavior.

### Option B — local draft target-direction association metadata

Temporarily associate the compatibility `targetWeightKg` with the explicit direction that owned it, e.g. a local draft field conceptually equivalent to:

```text
targetWeightDirection: loss | gain | null
```

This is onboarding-draft compatibility metadata, not a new canonical Profile owner rule.

Behavior:

- eligible target entry/recommendation/user update records current explicit direction;
- switch to an ineligible goal preserves `targetWeightKg + associated direction` dormant;
- returning to the same direction restores exactly;
- switching to the opposite direction can deliberately treat the old target as incompatible instead of guessing from BMI/delta;
- persistence mappers consume target only when current explicit direction/eligibility matches the stored association;
- old v1-v3 drafts with no association require safe reconciliation, not invented semantics.

Pros:

- robust same-direction restore across Back/Forward/resume/ineligible detours;
- no false semantic inference from BMI or target-current delta;
- enables clean eligibility-aware persistence.

Cost:

- local snapshot representation changes, likely requiring **schema v4** if persisted;
- migration tests required;
- still a compatibility bridge until canonical Body Goal/Measurement ownership lands.

**Audit recommendation:** Option B is the smallest robust architecture if owner requires reversible resume behavior exactly as approved. Do not implement until this representation decision is accepted.

### Opposite-direction policy still needs explicit product rule

One scalar cannot preserve separate loss and gain targets simultaneously. If the user explicitly changes from loss to gain or gain to loss, choose and document one rule before implementation, for example:

- incompatible prior target remains dormant only until replaced, then new direction owns the scalar; or
- explicit opposite-direction switch clears/replaces the old target as a deliberate product action.

Do not silently infer that rule from current numeric values.

---

## 7. Goal Pace audit context

- Goal Pace = weekly body-weight change only;
- direction comes only from explicit Goal intent / `GoalWeightDirection`;
- preserve slider, haptics, warnings, projection visual language;
- Calories / BMR / TDEE belong to Nutrition Targets, not Goal Pace;
- `TargetsOnboardingDraft.goalPaceKgPerWeek` is currently non-null default `0.5`, so skipped Goal Pace can look like user intent;
- `TargetsSetupMapper` currently forwards that default unconditionally.

Goal Pace ownership/default cleanup remains Slice 2B-C after B1 state/persistence boundary is decided.

---

## 8. Execution order on PR #50

### 2B-A0 — consolidation

- [x] copy #51 flow-plan matrix/reconciliation test into #50;
- [x] copy #51 strengthened policy test into #50;
- [x] verify matching blobs;
- [x] close #51 unmerged;
- [x] leave #52 closed/unmerged.

### 2B-A1 — eligibility/navigation truth

- [x] approved policy matrix implemented;
- [x] active Profile/Targets plans derive from explicit Goal selection;
- [x] direction validators use explicit direction;
- [x] reconciliation tests on #50;
- [ ] final integrated Next/Back/Resume/Progress/Validation matrix at 2B-D.

### 2B-B1 — non-visual Target Weight state/persistence

**Audit complete. Implementation blocked on representation/opposite-direction decision.**

After decision:

1. preserve same-direction user target across temporary ineligible goal/mode changes;
2. prevent recommendations from overwriting an existing preserved target;
3. make opposite-direction behavior explicit;
4. gate Profile/Targets owner consumption by current explicit eligibility;
5. add draft/resume and mapper tests;
6. bump local snapshot schema only if chosen representation requires it;
7. do not alter exact recommendation formula in B1.

### 2B-B2 — measurement input restoration/synchronization

Blocked on approved picker/reference evidence.

1. obtain historical/design/reusable reference;
2. restore/reuse without redesign;
3. enforce display = input selection = draft;
4. verify kg/lb and height units;
5. verify Back/Forward/resume initialization.

### 2B-C — Goal Pace + draft semantics

- remove Calories/BMR/TDEE/kcal responsibility from Goal Pace;
- preserve slider/haptics/warnings/projection;
- direction only from explicit Goal intent;
- prevent skipped default `0.5` from becoming fake intent;
- make owner persistence eligibility-aware;
- restore old drafts safely;
- local snapshot bump only if representation changes.

### 2B-D — full acceptance

```text
Nutrition: Lose / Gain / Maintain / Recomposition
Workout: Lose primary / Lose supporting / each non-weight goal alone
Hybrid: same matrix + Workout Intro branch compatibility
```

Verify Next, Back, Resume, draft restore, progress/accessibility, validation, Target Weight preservation, opposite-direction rule, units/input synchronization, Goal Pace direction, hidden-value persistence gating, and legacy migration. Then run full Flutter/Dart analyze + tests.

---

## 9. Expected file impact

### Target Weight state/persistence

- `apps/features/onboarding/lib/src/presentation/controllers/onboarding_controller.dart`
- `apps/features/onboarding/lib/src/domain/models/profile_onboarding_draft.dart` only if approved metadata is required
- `apps/features/onboarding/lib/src/data/mappers/onboarding_draft_snapshot_dto_mapper.dart` only if representation changes
- `apps/features/onboarding/lib/src/domain/models/onboarding_draft_snapshot.dart` only if schema changes
- `apps/features/onboarding/lib/src/domain/usecases/profile_setup_mapper.dart`
- `apps/features/onboarding/lib/src/domain/usecases/targets_setup_mapper.dart`
- `apps/features/onboarding/lib/src/domain/usecases/persist_onboarding_owner_data_use_case.dart`
- `apps/features/onboarding/lib/src/domain/usecases/profile_step_validator.dart` verify only unless contract gap appears
- `apps/features/onboarding/lib/src/domain/usecases/target_weight_recommendation_resolver.dart` B1 must not change numeric formula.

### Measurement UI after reference approval

- `apps/features/onboarding/lib/src/presentation/renderer/profile_step_renderer.dart`
- `apps/features/onboarding/lib/src/presentation/screens/profile/height_screen.dart`
- `apps/features/onboarding/lib/src/presentation/screens/profile/current_weight_screen.dart`
- `apps/features/onboarding/lib/src/presentation/screens/profile/target_weight_screen.dart`
- approved reusable/historical input component.

### Goal Pace

- `apps/features/onboarding/lib/src/domain/models/targets_onboarding_draft.dart`
- `apps/features/onboarding/lib/src/domain/usecases/goal_pace_resolver.dart`
- `apps/features/onboarding/lib/src/domain/usecases/target_step_validator.dart`
- `apps/features/onboarding/lib/src/presentation/screens/targets/goal_pace_screen.dart`
- `apps/features/onboarding/lib/src/presentation/renderer/target_step_renderer.dart`
- snapshot mapper/schema only if representation changes.

### Required tests

At minimum review/update/add:

- `apps/features/onboarding/test/domain/onboarding_controller_test.dart`
- `apps/features/onboarding/test/presentation/onboarding_controller_draft_persistence_test.dart`
- `apps/features/onboarding/test/domain/profile_setup_mapper_test.dart`
- `apps/features/onboarding/test/domain/targets_setup_mapper_test.dart`
- `apps/features/onboarding/test/domain/target_weight_recommendation_resolver_test.dart`
- `apps/features/onboarding/test/domain/profile_step_validator_test.dart`
- `apps/features/onboarding/test/data/onboarding_draft_snapshot_dto_mapper_test.dart`
- `apps/features/onboarding/test/domain/goal_weight_follow_up_flow_plan_test.dart`
- `apps/features/onboarding/test/domain/weight_goal_flow_policy_test.dart`
- focused Goal Pace widget/domain tests in 2B-C;
- full onboarding flow/progress tests in 2B-D.

---

## 10. UI / design-system guardrails

Before Flutter UI changes read:

1. root `AGENTS.md`;
2. `apps/features/AGENTS.md`;
3. `.ai/tasks/design-system-token-consolidation.md`;
4. `apps/core/lib/src/theme/README.md`;
5. any more specific nested `AGENTS.md`.

Use existing `package:tio_core/core.dart` reusable surface first.

Mandatory:

- no Goal card redesign;
- no Height/Current Weight/Target Weight redesign;
- no invented picker design;
- preserve Goal Pace slider/projection visual language;
- preserve spacing, typography, unit treatment, motion, selected states, and accessibility semantics unless separately approved.

---

## 11. Non-goals

Not authorized here:

- canonical Body Goal / Body Measurement owner-schema migration;
- canonical Workout Goal owner migration;
- Supabase schema migration solely for this slice;
- Health Concerns / Injuries & Limitations;
- Special Event;
- Workout Profile / Equipment taxonomy;
- Nutrition macro-target implementation beyond removing misplaced Goal Pace calorie ownership;
- Health Connections;
- Plan Building / Congratulations changes;
- unrelated onboarding redesign.

---

## 12. Exit criteria before PR #50 Ready/Merge

### PR topology

- [x] #51 useful tests consolidated into #50;
- [x] #51 closed unmerged;
- [x] #52 closed unmerged;
- [x] #50 only active implementation PR.

### Goal / eligibility

- [x] dynamic mode-aware Goal active;
- [x] migration-safe Goal selection restore;
- [x] `Build muscle != Gain weight`;
- [x] eligibility/reconciliation tests on #50;
- [ ] final integrated Next/Back/Resume/Progress/Validation matrix.

### Target Weight state/persistence

- [x] B1 current behavior audit completed;
- [x] destructive clearing locations identified;
- [x] recommendation scalar/provenance limitation identified;
- [x] unconditional Profile/Targets persistence consumption identified;
- [x] missing preservation/persistence tests identified;
- [ ] target direction-association / no-metadata representation decision approved;
- [ ] explicit opposite-direction policy approved;
- [ ] same-direction reversible user target survives Back/Forward/Resume/ineligible detours;
- [ ] recommendation never overwrites existing preserved target;
- [ ] hidden/ineligible target is not consumed by owner persistence;
- [ ] migration tests pass if schema changes.

### Measurement input

- [x] current-source audit completed;
- [x] confirmed actual picker/input absent;
- [ ] approved historical/design/reusable input reference identified;
- [ ] display = input = draft after restoration;
- [ ] kg/lb + height unit initialization verified.

### Recommendation

- [ ] exact numeric recommendation rule approved or sourced from canonical policy;
- [ ] recommendation never reverses explicit direction.

### Goal Pace / draft

- [ ] no Calories/BMR/TDEE/kcal ownership in Goal Pace;
- [ ] explicit Goal intent only runtime direction semantic;
- [ ] slider/haptics/warnings/projection stable;
- [ ] skipped/default `0.5` is not fake intent;
- [ ] hidden/skipped pace is not consumed by owner persistence;
- [ ] legacy draft restore safe.

### Final technical validation

- [ ] focused tests pass;
- [ ] full Flutter analyze pass;
- [ ] full Dart analyze pass;
- [ ] full Flutter tests pass;
- [ ] full Dart tests pass;
- [ ] PR #50 body matches final actual scope/evidence;
- [ ] PR #50 remains Draft until all product + technical gates are satisfied.

### Final status

`IN PROGRESS` on PR #50. Do not merge to `main` until exit criteria are satisfied.
