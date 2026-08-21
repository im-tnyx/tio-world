# Product Onboarding Slice 2B — Target Weight and Goal Pace

**Status:** In progress  
**Primary owner:** `apps/features/onboarding`  
**Affected platforms:** Flutter phone app  
**GitHub tracker:** #40  
**Canonical implementation PR:** #50 `feat(onboarding): activate unified mode-aware Goal screen`  
**Canonical branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`  
**Latest audited PR #50 head:** `1d0f25e241599b948b0d2d250b93e10e50656785`  
**Owner execution decision:** keep one active implementation PR (#50) until the approved Goal + Target Weight + Goal Pace contract in this task is complete and fully validated. Do not merge #50 to `main` yet.

---

## 0. Canonical Continuation Context — Read First

This file is the durable handoff. Continue from repository state recorded here instead of relying on chat history.

### PR state

#### PR #50 — only active implementation PR

- open, Draft, mergeable
- base: `main`
- head: `agent/onboarding-slice-2-step-1-body-goal-ui`
- audited head after consolidation: `1d0f25e241599b948b0d2d250b93e10e50656785`
- changed files at audit: 55
- prior full green evidence: Flutter CI **#1057**, run id `32484593862`, on head `ec125ed560fbbbf95ccfc031cccd8df3fe7c39c2`
  - Flutter analyze passed
  - Dart analyze passed
  - Flutter tests passed
  - Dart tests passed
- after task/index updates and #51 test consolidation, fresh Flutter CI **#1064**, run id `32487437277`, is running on head `1d0f25e...` at the latest audit.

Green CI proves technical consistency at that snapshot. It does not by itself prove the remaining Product contract is complete.

#### PR #51 — closed, superseded, do not merge

Former stacked PR: `feat(onboarding): enforce goal-aware weight follow-up eligibility`.

Its only two useful changed files were copied into #50 and verified by matching blob content:

1. `apps/features/onboarding/test/domain/goal_weight_follow_up_flow_plan_test.dart`
   - verified blob: `8a61872d37d68535821295d2d047f955e1ec92c3`
2. `apps/features/onboarding/test/domain/weight_goal_flow_policy_test.dart`
   - verified blob: `a4ae3e658875ff131ebcc5b944e271b819846c8a`

PR #51 is now closed and unmerged. It must remain historical/superseded; all continuation happens on #50.

#### PR #52 — closed validation-only PR

- closed
- unmerged
- existed only to trigger `pull_request -> main` CI for the earlier stacked state
- no further action; do not reopen or merge.

### Current single-PR execution

```text
PR #50 Draft
→ eligibility tests consolidated ✅
→ finish Target Weight behavior
→ finish Goal Pace/draft semantics
→ complete full acceptance matrix
→ full CI green
→ update PR body to actual final scope
→ only then Ready/Merge decision
```

Do not create another 2B PR unless the owner explicitly changes this strategy.

---

## 1. Issue #40 Product / Ownership Contract

Issue #40 is canonical for Product Onboarding structure.

Ownership:

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

A unified user-facing Goal screen is allowed, but it must not recreate one mixed canonical persistence owner.

### Dynamic Goal screen — already implemented in #50

#### Nutrition

Single select:

```text
Lose weight
Gain weight
Maintain weight
Recomposition
```

#### Workout / Hybrid

Same six options:

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
- optional compatible second = supporting
- max 2
- no false `Build muscle → Gain weight` mapping
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
2. Height / Current Weight with no answer use deterministic existing defaults, with picker/display synchronized;
3. fresh eligible Target Weight may receive a deterministic goal-aware recommendation when authoritative inputs are sufficient;
4. recommendation is only a starting selection and is user-adjustable;
5. after user adjustment, Back / Forward / Resume must preserve the user's value and must not silently recalculate over it.

### Exact numeric recommendation rule is NOT yet locked

Current #50 scaffold uses:

- ±5% directional change
- BMI floor `18.5`
- gain guard `30.0`
- weight clamp `30..200 kg`

These are implementation scaffold values, not automatically an approved product/medical formula.

Before finalizing:

- audit whether any existing repository/product policy explicitly owns these numbers;
- if not, propose the exact deterministic recommendation rule for approval;
- a safety guard may reduce/suppress a recommendation but must never reverse explicit loss/gain direction;
- insufficient authoritative input should produce a neutral deterministic state or no personalized recommendation, not invented certainty.

BMI/weight status may be a safety input only. It must never choose the semantic goal.

---

## 3. Goal Pace Contract

- Goal Pace = weekly body-weight change only.
- direction comes only from explicit Goal intent / `GoalWeightDirection`.
- preserve existing slider, haptics, warnings, and projection visual language.
- Calories / BMR / TDEE belong to Nutrition Targets, not Goal Pace.
- skipped Goal Pace must not turn a compatibility default into fake user intent.

---

## 4. Already Done in PR #50

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
- `Build muscle != Gain weight`

### Follow-up scaffolding

- `GoalWeightDirection`
- `GoalWeightFollowUpPolicy`
- conditional `ProfileFlowPlan` Target Weight
- conditional `TargetsFlowPlan` Goal Pace
- current-step reconciliation helpers
- active child plans drive controller navigation
- state derives flattened progress from active plans
- direction-aware Target Weight validation
- explicit Goal Pace direction path
- renderers receive explicit weight direction

### Consolidated eligibility verification

Now present directly on #50:

- Nutrition Lose/Gain active; Maintain/Recomposition skipped
- Workout/Hybrid Lose primary/supporting active
- training-only goals do not create body-weight direction
- Build muscle never becomes Gain weight
- missing mode activates no follow-up
- Target Weight and Goal Pace share eligibility source
- ineligible Target Weight reconciles to Current Weight
- ineligible Goal Pace reconciles to Water Target.

---

## 5. Current Audit Findings / Risks

### A. Target Weight is destructively cleared today

`OnboardingController` currently clears `targetWeightKg` when resolved weight direction changes during goal/mode changes.

This is not accepted final behavior.

Required review/target:

- reversible goal/mode changes should not silently destroy recoverable user-entered target intent;
- an ineligible value may remain dormant in draft but must not be consumed downstream while hidden;
- returning to a semantically compatible eligible state should restore user intent where valid;
- recommendation must never overwrite an existing user-entered value.

### B. Recommendation seeds at runtime today

`OnboardingController._prepareProfileForStep(...)` seeds `TargetWeightRecommendationResolver` when entering eligible Target Weight with no target.

The concept is approved; the exact formula still requires the decision gate above.

### C. Picker implementation/source still needs audit

Audited screen files showed displayed measurement state but did not clearly expose the intended historical/approved wheel picker implementation.

Before editing measurement UI:

1. locate reusable/current/historical picker implementation;
2. audit kg/lb and height-unit behavior;
3. audit selected-index initialization;
4. keep existing screen composition/spacing/type/motion;
5. do not substitute a card, text field, slider, or new picker design.

### D. Goal Pace still owns calorie logic

Current `GoalPaceScreen` still calculates/displays BMR/TDEE-like kcal values.

Must be removed from Goal Pace ownership while preserving pace/projection UX.

### E. Goal Pace draft default can look like intent

`TargetsOnboardingDraft.goalPaceKgPerWeek` is currently non-null with default `0.5`; legacy restore also has default behavior.

Required semantics:

```text
Goal Pace skipped + draft has 0.5
≠ user selected 0.5 kg/week
```

Choose the smallest migration-safe fix. Local snapshot schema changes only if representation truly changes. No Supabase schema change solely for this task.

### F. PR #50 description is now stale

The PR body still describes remaining 2B pieces as out of scope, but the current owner decision is to complete them inside #50 before merge.

Update the PR body after implementation stabilizes so review scope and actual diff agree.

---

## 6. Execution Order on PR #50

### 2B-A0 — consolidate #51

- [x] copy new flow-plan matrix/reconciliation test into #50
- [x] copy strengthened weight policy test into #50
- [x] verify matching blob content
- [x] close #51 unmerged as superseded
- [x] leave #52 closed/unmerged
- [ ] fresh #50 CI after consolidation completes green (CI #1064 running at latest audit)

### 2B-A1 — eligibility/navigation truth

Audit and close any remaining gaps in:

- `GoalWeightFollowUpPolicy`
- `BuildProfileFlowPlanUseCase`
- `BuildTargetsFlowPlanUseCase`
- controller current-step reconciliation
- `OnboardingState` progress flattening
- validators
- draft restore of now-ineligible Target Weight / Goal Pace.

Acceptance:

- approved mode/goal matrix exact;
- Next/Back/Resume/Progress/Validation/rendering agree;
- hidden screens create no validation obligation;
- no training-only goal invents body-weight direction.

### 2B-B — Target Weight initialization + user preservation

Order:

1. picker source/reuse audit;
2. display/picker/draft synchronization;
3. numeric recommendation policy audit/approval gate;
4. fresh eligible recommendation seeding only;
5. preserve user adjustment across Back/Forward/resume;
6. stop destructive clearing of recoverable target intent on reversible goal/mode changes;
7. verify kg/lb display with canonical kg storage.

No redesign.

### 2B-C — Goal Pace + draft semantics

- remove Calories/BMR/TDEE/kcal responsibility from Goal Pace;
- preserve slider/haptics/warnings/projection;
- direction only from explicit Goal intent;
- prevent skipped default `0.5` from becoming fake intent;
- old drafts restore safely;
- local snapshot bump only if needed.

### 2B-D — full acceptance

Test matrix:

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
same goal matrix
+ existing Workout Intro branch compatibility
```

For applicable paths verify:

- Next
- Back
- Resume
- restored draft
- progress/accessibility semantics
- validation
- Target Weight initialization
- user override preservation
- units
- Goal Pace direction
- skipped/default semantics.

Then full Flutter/Dart analyze + tests required by repository CI.

---

## 7. Expected File Impact

Audit before editing.

### Flow / eligibility

- `apps/features/onboarding/lib/src/domain/usecases/goal_weight_follow_up_policy.dart`
- `apps/features/onboarding/lib/src/domain/usecases/weight_goal_flow_policy.dart`
- `apps/features/onboarding/lib/src/domain/usecases/build_profile_flow_plan_use_case.dart`
- `apps/features/onboarding/lib/src/domain/usecases/build_targets_flow_plan_use_case.dart`
- `apps/features/onboarding/lib/src/domain/usecases/build_onboarding_progress_plan_use_case.dart`
- `apps/features/onboarding/lib/src/presentation/controllers/onboarding_controller.dart`
- `apps/features/onboarding/lib/src/presentation/state/onboarding_state.dart`

### Target Weight

- `apps/features/onboarding/lib/src/domain/usecases/target_weight_recommendation_resolver.dart`
- `apps/features/onboarding/lib/src/domain/usecases/profile_step_validator.dart`
- `apps/features/onboarding/lib/src/presentation/renderer/profile_step_renderer.dart`
- `apps/features/onboarding/lib/src/presentation/screens/profile/target_weight_screen.dart`
- reusable measurement picker/component source found during audit.

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

## 8. UI / Design-System Guardrails

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
- no new picker design without separate approval;
- preserve Goal Pace slider/projection visual language;
- preserve spacing, typography, unit treatment, motion, selected states, and accessibility semantics unless separately approved.

---

## 9. Non-Goals

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

## 10. Exit Criteria Before PR #50 Ready/Merge

### PR topology

- [x] #51 useful tests consolidated into #50.
- [x] #51 closed unmerged as superseded.
- [x] #52 closed unmerged.
- [x] #50 is the only active implementation PR for this work.

### Goal / eligibility

- [x] dynamic mode-aware Goal screen active.
- [x] Goal selection stores/restores migration-safely.
- [x] `Build muscle != Gain weight`.
- [x] consolidated eligibility/reconciliation tests are on #50.
- [ ] fresh CI after consolidation green.
- [ ] final Next/Back/Resume/Progress/Validation matrix verified.

### Target Weight

- [ ] picker/reusable measurement interaction audited.
- [ ] display = picker = draft value.
- [ ] exact recommendation numeric rule approved or sourced from an already-approved canonical policy.
- [ ] recommendation never reverses explicit direction.
- [ ] recommendation only seeds fresh eligible state.
- [ ] user value survives Back/Forward/resume.
- [ ] reversible goal/mode changes do not silently destroy recoverable user target intent.

### Goal Pace / draft

- [ ] no Calories/BMR/TDEE/kcal ownership in Goal Pace.
- [ ] explicit Goal intent is the only runtime direction semantic.
- [ ] slider/haptics/warnings/projection remain stable.
- [ ] skipped/default `0.5` is not fake user intent.
- [ ] legacy draft restore safe.

### Final technical validation

- [ ] focused tests pass.
- [ ] full Flutter analyze pass.
- [ ] full Dart analyze pass.
- [ ] full Flutter tests pass.
- [ ] full Dart tests pass.
- [ ] PR #50 body updated to match final actual scope/evidence.
- [ ] PR #50 remains Draft until all product + technical gates above are satisfied.

### Final Status

`IN PROGRESS` on PR #50. Do not merge to `main` until exit criteria are satisfied.
