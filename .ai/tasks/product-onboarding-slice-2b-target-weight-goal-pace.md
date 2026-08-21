# Product Onboarding Slice 2B — Target Weight and Goal Pace

**Status:** In progress  
**Primary owner:** `apps/features/onboarding`  
**GitHub tracker:** #40  
**Canonical implementation PR:** #50 `feat(onboarding): activate unified mode-aware Goal screen`  
**Canonical branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`  
**Execution decision:** keep one active implementation PR (#50) until the approved Goal + Target Weight + Goal Pace contract is complete and validated. Do not merge #50 to `main` yet.

---

## 0. Canonical continuation context — read first

This file is the durable handoff. Continue from repository state here instead of relying on chat history.

### PR topology

- **PR #50** is the only active implementation PR. It stays Draft and unmerged until the remaining exit criteria are satisfied.
- **PR #51** is closed/unmerged as superseded. Its two useful eligibility/reconciliation tests were copied into #50 and blob-verified.
- **PR #52** is closed/unmerged validation-only. Do not reopen or merge it.

### Latest validated production checkpoint

```text
head: 0109839f0b5e940815709aa8444142a79828e391
Flutter CI: #1090
run id: 32494752657
conclusion: SUCCESS
```

Validated gates:

- Flutter analyze ✅
- Dart analyze ✅
- full Flutter tests ✅
- full Dart tests ✅

This proves the implemented Goal + eligibility + Target Weight B1 + Goal Pace 2B-C checkpoint is technically green. It does **not** mean the full Slice 2B Product contract is ready to merge.

### Single-PR execution state

```text
PR #50 Draft
├─ Dynamic Goal activation                         ✅
├─ Weight-follow-up eligibility / reconciliation   ✅
├─ 2B-B1 Target Weight state/persistence            ✅ CI #1079
├─ 2B-C Goal Pace ownership/default semantics       ✅ CI #1090
├─ 2B-B2 measurement input restoration             BLOCKED on approved picker/reference
├─ Target Weight numeric recommendation policy      NEEDS PRODUCT RULE / canonical source
└─ 2B-D full acceptance matrix                      NEXT UNBLOCKED AUDIT/VALIDATION
        ↓
final CI green
        ↓
Ready/Merge decision
```

Do not create another 2B PR unless the owner explicitly changes this strategy.

---

## 1. Issue #40 product / ownership contract

Issue #40 is canonical for Product Onboarding structure.

```text
Onboarding
= flow/order/step identity/draft-resume/review/finalization orchestration

Profile
= shared identity/baseline

Body / Wellness
= Body Goal + body measurements/goal plan

Nutrition
= Nutrition Profile + numeric Nutrition Targets

Workout
= Workout Profile + Workout Goals/Targets
```

The unified user-facing Goal screen is an onboarding presentation/orchestration contract. It must not create a mixed canonical persistence owner.

### Dynamic Goal screen — implemented

Nutrition, single-select:

```text
Lose weight
Gain weight
Maintain weight
Recomposition
```

Workout / Hybrid, max 2 compatible:

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

### Target Weight / Goal Pace eligibility — implemented

`GoalIntentSelection` is semantic authority.

Nutrition:

```text
Lose weight      → Target Weight + Goal Pace
Gain weight      → Target Weight + Goal Pace
Maintain weight  → skip both
Recomposition    → skip both
```

Workout / Hybrid:

```text
Lose weight primary OR supporting → Target Weight + Goal Pace
all training-only goals alone     → skip both
```

Never infer semantic goal/direction from BMI or `targetWeight - currentWeight`.

Eligibility lives at child-flow-plan level so navigation, resume reconciliation, progress, validation, rendering, Review and owner consumption can use one explicit source of truth.

---

## 2. Completed foundation

### Goal activation

- `GoalIntent`
- ordered `GoalIntentSelection(primaryGoal, supportingGoal)`
- mode-aware `GoalIntentSelectionPolicy`
- active `GoalIntentScreen`
- Nutrition single-select
- Workout/Hybrid compatible max-two behavior
- migration-safe Goal selection persistence
- unsupported legacy mappings do not invent intent
- `Build muscle != Gain weight`.

### Weight-follow-up foundation

- `GoalWeightDirection`
- `GoalWeightFollowUpPolicy`
- `WeightGoalFlowPolicy` compatibility surface
- conditional Profile Target Weight plan
- conditional Targets Goal Pace plan
- current-step reconciliation
- active child plans drive navigation/progress
- direction-aware Target Weight validation
- explicit-direction Goal Pace runtime path
- consolidated policy/flow-plan tests from former PR #51.

---

## 3. Slice 2B-B1 — Target Weight state/persistence

### Status: implemented and validated

Local onboarding draft now stores:

```text
targetWeightKg: double?
targetWeightDirection: loss | gain | null
```

`targetWeightDirection` is onboarding compatibility metadata only. It is not inferred from BMI or numeric target/current delta and is not a new canonical Profile ownership rule.

Local onboarding snapshot schema is **v4** with persisted profile field:

```text
target_weight_direction
```

No Supabase schema change was required.

### Runtime contract

Eligible → ineligible:

- preserve Target Weight dormant in draft;
- skip Target Weight screen;
- do not consume dormant value downstream.

Ineligible → same direction:

- restore exact dormant Target Weight;
- recommendation does not overwrite the non-null preserved value.

Explicit loss ↔ gain switch:

- old incompatible scalar Target Weight is deliberately cleared;
- new direction can establish a new target.

Legacy v1-v3 draft:

- DTO can decode target without direction;
- controller associates direction only from restored **explicit eligible Goal intent**;
- never infer from BMI or numeric delta.

### Owner persistence boundary

`ProfileSetupMapper` and `TargetsSetupMapper` consume Target Weight only when:

```text
activeWeightDirection != null
AND
draft.targetWeightDirection == activeWeightDirection
```

Otherwise owner payload receives no Target Weight. Dormant Target Weight is also removed from nutrition recommendation inputs.

### B1 validation evidence

CI #1079, run `32489469386`, source/test head `029f1c7be5482bb77c4be88d2469f4c53ceb994`:

- Flutter analyze ✅
- Dart analyze ✅
- Flutter tests ✅
- Dart tests ✅

Focused tests cover v4 round-trip, v3 migration, same-direction restore, ineligible detour, opposite-direction clear, hydration/resume and owner persistence gating.

---

## 4. Measurement input / picker audit — 2B-B2

### Status: blocked on approved visual/reference evidence

Current PR #50 source audit confirmed:

- `HeightScreen` renders formatted height + information card;
- `CurrentWeightScreen` renders formatted weight + BMI card;
- `TargetWeightScreen` renders formatted target + analysis card;
- all three accept `onChanged` but do not invoke it in current screen bodies;
- `ProfileStepRenderer` only passes callbacks;
- `ProfileScreenScaffold` does not inject an input control.

Current indexed repository search found no active implementation for:

```text
ListWheelScrollView
CupertinoPicker
FixedExtentScrollController
MeasurementPicker
```

Issue #40 requires preserving the existing measurement wheel/picker language. Therefore:

- do not invent a new picker design;
- do not assume text-only current source means picker removal was intended;
- obtain approved historical/design/reusable reference before visual restoration;
- then enforce:

```text
visible value == selected input value == canonical draft value
```

Also verify kg/lb, height units, Back/Forward and resume exact positioning.

---

## 5. Slice 2B-C — Goal Pace ownership/default semantics

### Status: implemented and validated

Approved ownership:

```text
Goal Pace = weekly body-weight change only
```

Direction comes only from explicit `GoalWeightDirection` derived from `GoalIntentSelection`.

### Goal Pace screen cleanup

`GoalPaceScreen` no longer owns or displays:

- BMR calculation;
- TDEE calculation;
- calorie deficit/surplus math;
- target-kcal chip;
- Target Calories info sheet.

Preserved:

- 0.1..1.5 kg/week slider;
- haptic selection feedback;
- pace classification tag;
- aggressive loss/gain warning chip and Attention sheet;
- target-date projection;
- projection graph;
- current/target weight badges;
- existing screen/card/slider/projection keys and visual language.

Nutrition Targets remains the owner of calories/BMR/TDEE/macros.

### Skipped/default `0.5` semantics

`TargetsOnboardingDraft.goalPaceKgPerWeek` intentionally remains the non-null compatibility/UI starting value `0.5`.

No new answer-marker and no schema v5 were needed.

Semantic rule:

```text
draft 0.5 + active explicit weight direction   → active Goal Pace value
draft 0.5 + no active weight direction         → compatibility value only, NOT user intent
```

`TargetsSetupMapper` now consumes:

```text
active direction   → draft.goalPaceKgPerWeek
no direction       → 0.0
```

The verified target API accepts `goalPaceKgPerWeek` from `0` through `2`, so `0.0` is the transport-compatible no-pace value. This prevents a skipped `0.5` from being persisted as an explicit user-selected pace without widening the owner schema.

`TargetStepRenderer` also passes an effective `0.0` pace into `NutritionTargetScreen` when Goal Pace is not active.

### Review boundary fixed

`ReviewScreen` previously used target/current numeric difference to decide whether to show Goal Pace. That violated the explicit-goal contract.

Review now derives active weight direction from:

```text
selectedMode + GoalIntentSelection
```

and:

- hides dormant Target Weight when the current goal is ineligible;
- hides skipped/default Goal Pace `0.5`;
- shows Target Weight only when stored target direction matches active direction;
- shows Goal Pace only when explicit weight direction is active;
- gives Nutrition Target calculation an eligibility-filtered Profile/Targets view.

No numeric delta is used as semantic goal authority.

### 2B-C files changed

Production:

- `apps/features/onboarding/lib/src/domain/usecases/targets_setup_mapper.dart`
- `apps/features/onboarding/lib/src/presentation/renderer/target_step_renderer.dart`
- `apps/features/onboarding/lib/src/presentation/screens/targets/goal_pace_screen.dart`
- `apps/features/onboarding/lib/src/presentation/screens/review/review_screen.dart`

Tests:

- `apps/features/onboarding/test/domain/targets_setup_mapper_test.dart`
- `apps/features/onboarding/test/domain/persist_onboarding_owner_data_use_case_test.dart`
- `apps/features/onboarding/test/presentation/targets_section_test.dart`
- `apps/features/onboarding/test/presentation/review_section_test.dart`

### 2B-C validation evidence

Final source/test head:

```text
0109839f0b5e940815709aa8444142a79828e391
```

Flutter CI #1090, run `32494752657`:

- Flutter analyze ✅
- Dart analyze ✅
- full Flutter tests ✅
- full Dart tests ✅

A preceding CI #1089 found one test-fixture-only error (`WorkoutFlowPlan.steps` required); production code was not implicated. The fixture was corrected and #1090 is fully green.

### Known separate compatibility gap — do not silently expand 2B-C

The existing Nutrition target calculator still consumes legacy `ProfileGoal` strings and contains its own internal pace fallbacks when pace is `<= 0`.

That calculator ownership/migration is separate from the approved Goal Pace cleanup and is explicitly outside this task's Nutrition macro-target implementation scope, except that this slice prevents skipped Goal Pace from being presented/persisted as user intent.

Do not rewrite the Nutrition calculator incidentally while finishing Slice 2B-D.

---

## 6. Target Weight recommendation formula decision gate

The concept of a fresh eligible Target Weight recommendation is approved.

The exact numeric formula is not independently approved.

Current scaffold includes:

```text
±5% directional change
BMI floor 18.5
BMI gain guard 30.0
weight clamp 30..200 kg
```

These are implementation scaffold, not automatically approved product/medical authority.

Before finalizing recommendation behavior:

- search for canonical repository/product policy owning the numeric rule;
- if none exists, propose an explicit deterministic rule for owner approval;
- BMI may suppress/restrict a recommendation but cannot choose semantic goal;
- recommendation must never reverse explicit direction;
- insufficient authoritative input must not fabricate personalized certainty.

Do not change recommendation constants incidentally during acceptance work.

---

## 7. Next execution order on PR #50

### 2B-D — full acceptance matrix — next unblocked work

Modes/goals:

```text
Nutrition: Lose / Gain / Maintain / Recomposition
Workout: Lose primary / Lose supporting / every training-only goal alone
Hybrid: same goal matrix + Workout Intro setup-now/later compatibility
```

Verify one integrated truth across:

- Next;
- Back;
- resume;
- restored drafts;
- progress + accessibility semantics;
- validation;
- current-step reconciliation;
- Review visibility;
- Target Weight dormant/same/opposite behavior;
- user override preservation;
- Goal Pace active/skipped semantics;
- owner persistence consumption boundaries.

Then rerun full workspace CI.

### 2B-B2 — measurement input restoration

Still blocked on approved picker/reference evidence.

### Recommendation rule finalization

Still requires a canonical policy source or explicit product rule approval.

---

## 8. UI / design-system guardrails

Before any Flutter visual implementation read:

1. root `AGENTS.md`;
2. `apps/features/AGENTS.md`;
3. `.ai/tasks/design-system-token-consolidation.md`;
4. `apps/core/lib/src/theme/README.md`;
5. more specific nested `AGENTS.md` if present.

Use existing `package:tio_core/core.dart` reusable surface first.

Mandatory:

- no Goal card redesign;
- no invented Height/Current Weight/Target Weight picker;
- no unrelated measurement-screen redesign;
- preserve Goal Pace slider/projection language;
- preserve spacing, typography, unit treatment, motion and accessibility unless separately approved.

---

## 9. Non-goals

Not authorized by this task:

- canonical Body Goal / Body Measurement owner migration;
- canonical Workout Goal owner migration;
- Supabase schema migration solely for this slice;
- Health Concerns / Injuries & Limitations implementation;
- Special Event changes;
- Workout Profile / Equipment taxonomy;
- Nutrition macro-target implementation beyond removing misplaced Goal Pace calorie ownership and eligibility-filtering the compatibility input;
- Health Connections;
- Plan Building / Congratulations changes;
- unrelated onboarding redesign.

---

## 10. Exit criteria before PR #50 Ready/Merge

### PR topology

- [x] #51 useful tests consolidated into #50.
- [x] #51 closed unmerged.
- [x] #52 closed unmerged.
- [x] #50 only active implementation PR.

### Goal / eligibility

- [x] dynamic mode-aware Goal screen.
- [x] migration-safe ordered Goal selection.
- [x] `Build muscle != Gain weight`.
- [x] approved weight-follow-up eligibility matrix.
- [x] flow-plan reconciliation coverage.
- [ ] final integrated 2B-D navigation/progress/resume matrix.

### Target Weight B1

- [x] direction association architecture.
- [x] same-direction dormant restoration.
- [x] opposite-direction incompatible target clear.
- [x] old v1-v3 safe direction reconciliation from explicit goal.
- [x] recommendation does not overwrite existing non-null preserved target.
- [x] dormant Target Weight excluded from Profile and Nutrition/Targets consumption.
- [x] full analyzer/tests green at CI #1079.

### Goal Pace 2B-C

- [x] no Calories/BMR/TDEE/kcal ownership in Goal Pace screen.
- [x] explicit Goal direction is runtime semantic authority.
- [x] slider/haptics/warnings/projection preserved.
- [x] skipped/default `0.5` is not persisted as user-selected pace.
- [x] ineligible transport/owner pace is neutral `0.0`.
- [x] Review hides skipped/dormant pace and Target Weight.
- [x] no schema v5 required.
- [x] full analyzer/tests green at CI #1090.

### Measurement / recommendation

- [x] current-source picker audit complete.
- [ ] approved picker/reference identified.
- [ ] display = input = draft after restoration.
- [ ] exact recommendation numeric policy approved/sourced.
- [ ] focused recommendation acceptance green after final rule.

### Final technical validation

- [ ] full 2B-D acceptance matrix complete.
- [ ] final Flutter analyze green after all remaining implementation.
- [ ] final Dart analyze green after all remaining implementation.
- [ ] final Flutter tests green after all remaining implementation.
- [ ] final Dart tests green after all remaining implementation.
- [ ] PR body reflects final actual scope/evidence.
- [ ] PR remains Draft until all Product + technical gates are satisfied.

### Final status

`IN PROGRESS` on PR #50.  
**Next unblocked target:** Slice 2B-D integrated acceptance audit/coverage.  
**Blocked visual target:** 2B-B2 measurement input restoration until approved picker/reference evidence exists.  
**Product decision gate:** exact Target Weight recommendation numeric policy.
