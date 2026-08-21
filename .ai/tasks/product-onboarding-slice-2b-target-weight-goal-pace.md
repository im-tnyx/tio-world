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

- **PR #50** is the only active implementation PR. It stays Draft and unmerged until the remaining Slice 2B exit criteria are satisfied.
- **PR #51** is closed/unmerged as superseded. Its two useful eligibility/reconciliation test changes were copied into #50 and blob-verified.
- **PR #52** is closed/unmerged validation-only. Do not reopen or merge it.

### Latest validated production checkpoint

Source/test head before this task-only documentation commit:

```text
029f1c7cbe5482bb77c4be88d2469f4c53ceb994
```

Flutter CI:

```text
run #1079
run id 32489469386
conclusion SUCCESS
```

Validated gates:

- Flutter analyze ✅
- Dart analyze ✅
- full Flutter tests ✅
- full Dart tests ✅

This proves the implemented Goal + eligibility + Target Weight B1 checkpoint is technically green. It does **not** mean the full Slice 2B Product contract is complete.

### Single-PR execution

```text
PR #50 Draft
├─ Dynamic Goal activation                         ✅
├─ Weight-follow-up eligibility / reconciliation   ✅
├─ 2B-B1 Target Weight state/persistence            ✅ validated CI #1079
├─ 2B-B2 measurement input restoration             BLOCKED on approved picker/reference
├─ Target Weight numeric recommendation policy      NEEDS PRODUCT RULE / canonical source
├─ 2B-C Goal Pace + default-intent cleanup          NEXT IMPLEMENTATION WORK
└─ 2B-D full acceptance matrix                      PENDING
        ↓
full CI green
        ↓
Ready/Merge decision
```

Do not create another 2B PR unless the owner explicitly changes this strategy.

---

## 1. Issue #40 product / ownership contract

Issue #40 remains canonical for Product Onboarding structure.

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

The unified user-facing Goal screen is an onboarding presentation/orchestration contract. It must not create a new mixed canonical owner.

### Dynamic Goal screen — implemented

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

- first selection = primary;
- optional compatible second = supporting;
- max 2;
- `Build muscle` never means `Gain weight`;
- no BODY GOAL / WORKOUT GOAL subgroup headings;
- preserve existing Goal card visual/interaction language.

### Target Weight / Goal Pace eligibility — implemented

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

Never infer semantic goal/direction from BMI or `targetWeight - currentWeight`.

Eligibility lives at child-flow-plan level so navigation, resume reconciliation, progress, validation and rendering use the same active plan.

---

## 2. Already completed before B1

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
- active child plans drive progress/navigation
- direction-aware Target Weight validation
- Goal Pace explicit-direction runtime path
- consolidated policy/flow-plan tests from former PR #51.

---

## 3. Slice 2B-B1 — Target Weight state/persistence

### Status: implemented and validated

Owner approved the audit recommendation:

```text
Option B
= local onboarding-draft target-direction association metadata
```

Opposite-direction rule is also frozen:

```text
loss ↔ gain explicit switch
→ old incompatible scalar Target Weight is deliberately cleared
→ new direction may establish a new target
```

Temporary ineligible detours do **not** destroy the stored target.

### Representation

`ProfileOnboardingDraft` now stores:

```text
targetWeightKg: double?
targetWeightDirection: loss | gain | null
```

`targetWeightDirection` is onboarding compatibility metadata only. It is **not** inferred from BMI or target/current numeric delta and is not a new canonical Profile ownership rule.

Local onboarding snapshot schema is now:

```text
v4
```

Persisted JSON profile field:

```text
target_weight_direction
```

No Supabase schema change is required for this local draft change.

### Runtime transition contract

#### Eligible → ineligible

Example:

```text
Lose weight
Target = 64 kg, direction = loss
↓
Maintain weight
```

Result:

```text
Target remains dormant in draft
Target Weight screen is skipped
owner persistence must not consume dormant value
```

#### Ineligible → same direction

```text
Maintain
↓
Lose weight
```

If dormant association is `loss`, exact Target Weight restores. Recommendation is not re-applied over the non-null preserved value.

#### Direct or indirect opposite direction

```text
loss → gain
gain → loss
```

If the stored association differs from the new explicit direction, the old scalar target is deliberately cleared. This prevents a loss target from silently becoming a gain target or vice versa.

#### Legacy v1-v3 draft

Older drafts can contain `target_weight_kg` without `target_weight_direction`.

DTO decoding leaves direction absent. During controller reconciliation, an existing target is associated only when the restored **explicit eligible Goal intent** provides a direction.

Do not infer legacy direction from BMI or numeric delta.

### Recommendation interaction

Current Target Weight recommendation remains a starting-value scaffold.

B1 guarantees:

- an existing preserved target is not overwritten by recommendation seeding;
- opposite-direction target is cleared before a new direction may seed/accept a new target;
- exact recommendation formula is **not** finalized by B1.

Current scaffold values still include:

```text
±5% directional change
BMI floor 18.5
BMI gain guard 30.0
weight clamp 30..200 kg
```

These are implementation scaffold, not automatically approved product/medical authority.

### Owner persistence boundary — fixed for Target Weight

`ProfileSetupMapper` now receives active explicit weight direction and forwards `targetWeightKg` only when:

```text
activeWeightDirection != null
AND
draft.targetWeightDirection == activeWeightDirection
```

Otherwise Profile owner receives null Target Weight.

`TargetsSetupMapper` applies the same Target Weight gate and removes dormant Target Weight from the nutrition recommendation calculator input.

`PersistOnboardingOwnerDataUseCase` derives active direction from `selectedMode + GoalIntentSelection` and passes it to both owner mappers.

This prevents hidden/ineligible/opposite-direction Target Weight from being consumed when durable owner persistence is enabled.

### B1 files changed

Production:

- `apps/features/onboarding/lib/src/domain/models/profile_onboarding_draft.dart`
- `apps/features/onboarding/lib/src/domain/models/onboarding_draft_snapshot.dart`
- `apps/features/onboarding/lib/src/data/mappers/onboarding_draft_snapshot_dto_mapper.dart`
- `apps/features/onboarding/lib/src/presentation/controllers/onboarding_controller.dart`
- `apps/features/onboarding/lib/src/domain/usecases/profile_setup_mapper.dart`
- `apps/features/onboarding/lib/src/domain/usecases/targets_setup_mapper.dart`
- `apps/features/onboarding/lib/src/domain/usecases/persist_onboarding_owner_data_use_case.dart`

Tests:

- `apps/features/onboarding/test/data/onboarding_draft_snapshot_dto_mapper_test.dart`
- `apps/features/onboarding/test/presentation/onboarding_controller_draft_persistence_test.dart`
- `apps/features/onboarding/test/domain/profile_setup_mapper_test.dart`
- `apps/features/onboarding/test/domain/targets_setup_mapper_test.dart`
- `apps/features/onboarding/test/domain/persist_onboarding_owner_data_use_case_test.dart`

### B1 focused acceptance now covered

- v4 target direction round-trip;
- v3 target can decode without invented direction;
- legacy target associates from explicit eligible goal in controller;
- eligible → ineligible preserves target dormant;
- same direction restores exact target;
- opposite direction clears incompatible target;
- hydrated dormant target restores when same direction returns;
- Profile owner excludes dormant target;
- Nutrition/Targets owner excludes dormant target;
- active matching target reaches owner payload;
- full repository analyzer/tests green under CI #1079.

---

## 4. Measurement input / picker audit

### Current-source finding: actual measurement input control is absent

Fresh audit of PR #50 confirmed:

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

Historical picker source could not be proven through the available path-history connector.

### Consequence for 2B-B2

Issue #40 requires preserving the existing measurement wheel/picker language, but current source has no such control.

Therefore:

- do not invent a new picker design;
- do not assume text-only current source means picker removal was intended;
- obtain approved historical/design/reusable reference before visual restoration;
- after reference is available enforce:

```text
visible value == input selected value == canonical draft value
```

Also verify kg/lb and height unit initialization plus Back/Forward/resume exact positioning.

**2B-B2 remains blocked on reference evidence.**

---

## 5. Goal Pace — remaining Slice 2B-C

Approved ownership:

```text
Goal Pace = weekly body-weight change only
```

Direction comes only from explicit Goal intent / `GoalWeightDirection`.

Current known gaps:

1. `GoalPaceScreen` still calculates/displays calorie/BMR/TDEE-derived kcal values.
   - remove this ownership from Goal Pace;
   - Nutrition Targets owns Calories/BMR/TDEE context.

2. `TargetsOnboardingDraft.goalPaceKgPerWeek` is non-null with compatibility default `0.5`.

```text
Goal Pace skipped + draft has 0.5
≠ user explicitly selected 0.5 kg/week
```

3. `TargetsSetupMapper` still forwards the non-null pace because canonical `TargetsSetupData.goalPaceKgPerWeek` is currently required/non-null.

This default-intent problem was intentionally **not** hidden inside B1. It requires a focused 2B-C representation/consumption decision.

Goal Pace UI guardrail:

- preserve slider/haptics/warnings/projection visual language;
- remove only misplaced Nutrition-calorie ownership unless separately approved.

---

## 6. Recommendation formula decision gate

The concept of a fresh eligible Target Weight recommendation is approved.

The exact numeric formula is not independently approved.

Before finalizing recommendation behavior:

- search for a canonical repository/product policy owning the numeric rule;
- if none exists, propose an explicit deterministic rule for owner approval;
- BMI may suppress/restrict a recommendation but cannot choose semantic goal;
- recommendation must never reverse explicit direction;
- insufficient authoritative input must not fabricate personalized certainty.

Do not change numeric recommendation constants incidentally while working on Goal Pace or picker restoration.

---

## 7. Remaining execution order on PR #50

### 2B-B2 — measurement input restoration/synchronization

Blocked on approved reference.

1. obtain historical/design/reusable measurement-input reference;
2. restore/reuse without redesign;
3. display = selected input = draft value;
4. kg/lb + height units synchronized;
5. Back/Forward/resume exact initialization.

### Recommendation rule finalization

1. locate canonical policy or propose rule;
2. explicit approval if no existing authority;
3. focused resolver/controller tests;
4. preserve B1 state semantics.

### 2B-C — Goal Pace + draft semantics

1. remove calorie/BMR/TDEE/kcal ownership from Goal Pace;
2. keep weekly pace direction explicit;
3. preserve slider/projection behavior;
4. fix skipped/default `0.5` fake-intent semantics migration-safely;
5. gate owner consumption appropriately;
6. snapshot bump only if representation truly changes beyond current v4;
7. no Supabase schema solely for this compatibility change unless separately approved.

### 2B-D — full acceptance matrix

Modes/goals:

```text
Nutrition: Lose / Gain / Maintain / Recomposition
Workout: Lose primary / Lose supporting / every training-only goal alone
Hybrid: same goal matrix + Workout Intro setup-now/later compatibility
```

Verify:

- Next;
- Back;
- resume;
- restored drafts;
- progress + accessibility semantics;
- validation;
- current-step reconciliation;
- Target Weight dormant/same/opposite behavior;
- user override preservation;
- measurement units/input sync once picker is restored;
- Goal Pace direction/default semantics;
- owner persistence consumption boundaries.

Then full workspace CI again.

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
- Nutrition macro-target implementation beyond removing misplaced Goal Pace calorie ownership;
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

- [x] direction association architecture approved.
- [x] opposite-direction clear/replace rule approved.
- [x] local draft schema v4.
- [x] same-direction dormant restoration.
- [x] opposite-direction incompatible target clear.
- [x] old v1-v3 safe direction reconciliation from explicit goal.
- [x] recommendation does not overwrite existing non-null preserved target.
- [x] dormant Target Weight excluded from Profile owner persistence.
- [x] dormant Target Weight excluded from Nutrition/Targets target/recommendation input.
- [x] focused tests added.
- [x] full analyzer/tests green at CI #1079.

### Measurement / recommendation

- [x] current-source picker audit complete.
- [ ] approved picker/reference identified.
- [ ] display = input = draft after restoration.
- [ ] exact recommendation numeric policy approved/sourced.
- [ ] focused recommendation acceptance green after final rule.

### Goal Pace

- [ ] no Calories/BMR/TDEE/kcal ownership in Goal Pace.
- [x] explicit Goal direction path already exists.
- [ ] slider/haptics/warnings/projection preserved after cleanup.
- [ ] skipped/default `0.5` is not fake user intent.
- [ ] legacy draft/persistence behavior migration-safe.

### Final technical validation

- [ ] full 2B-D acceptance matrix complete.
- [ ] final Flutter analyze green.
- [ ] final Dart analyze green.
- [ ] final Flutter tests green.
- [ ] final Dart tests green.
- [ ] PR body reflects final actual scope/evidence.
- [ ] PR remains Draft until all Product + technical gates are satisfied.

### Final status

`IN PROGRESS` on PR #50.  
**Next unblocked implementation target:** Slice 2B-C Goal Pace ownership/default semantics.  
**Blocked visual target:** Slice 2B-B2 measurement input restoration until approved picker/reference evidence exists.
