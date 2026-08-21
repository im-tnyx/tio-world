# Product Onboarding Slice 2B — Target Weight and Goal Pace

**Status:** In progress  
**Primary owner:** `apps/features/onboarding`  
**GitHub tracker:** #40  
**Canonical implementation PR:** #50 `feat(onboarding): activate unified mode-aware Goal screen`  
**Canonical branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`  
**Execution decision:** keep one active implementation PR (#50). Do not merge to `main` until the remaining Product + technical gates are satisfied.

---

## 0. Canonical continuation context — read first

This file is the durable handoff. Continue from repository state here instead of relying on chat history.

### PR topology

- **PR #50** is the only active implementation PR. It remains Draft/unmerged.
- **PR #51** is closed/unmerged as superseded. Its two useful eligibility/reconciliation tests were consolidated into #50.
- **PR #52** is closed/unmerged validation-only. Do not reopen or merge it.

### Latest validated checkpoints

```text
Goal + eligibility baseline                     ✅
2B-B1 Target Weight state/domain persistence    ✅ CI #1079
2B-C Goal Pace ownership/default semantics      ✅ CI #1090
2B-D1 local acceptance + Review Goal source     ✅ CI #1095
```

Latest D1 source/test head:

```text
6c3dcb527bc92b3a6b46755d2d8c569682d090f4
Flutter CI #1095
run id: 32497930346
conclusion: SUCCESS
```

CI #1095 gates:

- Flutter analyze ✅
- Dart analyze ✅
- full Flutter tests ✅
- full Dart tests ✅

This does **not** make PR #50 Ready. Remote Target Weight transport, canonical Goal owner persistence, measurement input restoration, and final Target Weight recommendation policy remain unresolved.

---

## 1. Issue #40 ownership contract

```text
Product Onboarding
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

The unified Goal screen is an onboarding presentation/orchestration contract. It must not create a mixed canonical owner or invent semantic mappings.

### Approved unified Goal contract

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

Mandatory semantics:

- Nutrition is single-select.
- Workout/Hybrid may have one compatible supporting goal.
- `Build muscle != Gain weight`.
- Never infer Goal intent from BMI or current/target numeric difference.
- Do not map unsupported new Goal intents into legacy owner enums just to make persistence compile.

---

## 2. Weight follow-up eligibility — implemented

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
training-only goals alone         → skip both
```

Eligibility is consumed by dynamic `ProfileFlowPlan` and `TargetsFlowPlan`, so Next/Back/resume/progress/validation/reconciliation use the same source of truth.

---

## 3. 2B-B1 Target Weight state/domain persistence — validated

Local onboarding draft stores:

```text
targetWeightKg: double?
targetWeightDirection: loss | gain | null
```

Local snapshot schema is v4 with `target_weight_direction`.

Runtime contract:

- eligible → ineligible: preserve Target Weight dormant in onboarding draft;
- ineligible → same direction: restore exact value;
- explicit loss ↔ gain: clear incompatible old scalar Target Weight;
- legacy v1-v3 target direction associates only from explicit restored Goal intent;
- recommendation does not overwrite an existing preserved target;
- no BMI/numeric-delta semantic inference.

Onboarding-domain owner mappers consume Target Weight only when stored direction matches the current active explicit direction.

Validated by CI #1079.

### Important D audit correction

The B1 guarantee is currently safe at the onboarding-domain mapper boundary and Supabase owner path, but **not yet safe through the legacy HTTP Targets transport**. See 2B-D2 below.

---

## 4. 2B-C Goal Pace ownership/default semantics — validated

Goal Pace owns weekly body-weight change only.

Removed from `GoalPaceScreen`:

- BMR calculation;
- TDEE calculation;
- calorie deficit/surplus math;
- target-kcal chip;
- calorie info sheet.

Preserved:

- slider 0.1..1.5 kg/week;
- haptics;
- pace tags/warnings;
- target-date projection + graph;
- existing visual language.

Draft compatibility value remains `0.5`, but it is semantic user intent only when explicit weight direction is active.

Ineligible/skipped Goal Pace maps to neutral owner/transport value `0.0`, not fake selected `0.5`.

Review hides skipped Goal Pace and dormant Target Weight using explicit Goal direction.

Validated by CI #1090.

---

## 5. 2B-D1 local acceptance + Review Goal source — implemented and validated

### Production correction

`ReviewScreen` previously displayed legacy `profile.goals` even though the active Goal screen writes `draft.goalSelection`.

Review now renders `GoalIntentSelection` directly, preserving ordered primary/supporting semantics.

Examples:

```text
Lose weight + Improve endurance
→ Review: "Lose weight, Improve endurance"

Nutrition Maintain weight
→ Review: "Maintain weight"
```

A stale legacy `profile.goals = {keepFit}` no longer overrides what the user actually selected in the unified Goal screen.

No canonical Goal persistence mapping was added.

### Integrated acceptance matrix

New table-driven test:

`apps/features/onboarding/test/domain/goal_weight_follow_up_acceptance_matrix_test.dart`

It covers:

- Nutrition Lose / Gain / Maintain / Recomposition;
- Workout Lose primary;
- Workout Lose supporting;
- every Workout training-only goal;
- Hybrid setup-now with Lose primary/supporting + all training-only goals;
- Hybrid later with Lose primary/supporting + all training-only goals.

For every case it verifies:

- Target Weight plan eligibility;
- Goal Pace plan eligibility;
- restored draft parked on Target Weight / Goal Pace reconciles correctly when ineligible;
- dynamic progress denominator;
- Targets Next after Water Target;
- Targets Back returns consistently through the active plan.

Validated expected progress totals:

```text
Nutrition Lose/Gain                 17
Nutrition Maintain/Recomposition    15
Workout Lose (gym)                  25
Workout training-only (gym)         23
Hybrid setupNow Lose (gym)          26
Hybrid setupNow training-only       24
Hybrid later Lose                   18
Hybrid later training-only          16
```

Widget coverage verifies Review uses unified Goal data rather than stale legacy `ProfileGoal` data.

### D1 validation evidence

```text
head: 6c3dcb527bc92b3a6b46755d2d8c569682d090f4
Flutter CI: #1095
run id: 32497930346
```

All analyzer/test gates green.

---

## 6. 2B-D2 remote Target Weight transport — NEXT IMPLEMENTATION GATE

### Current defect

Onboarding `TargetsSetupMapper` can correctly produce:

```text
targetWeightKg = null
```

for skipped/dormant Target Weight.

But legacy HTTP `TargetsSetupDtoMapper` currently emits:

```text
'ttargetWeight': fallbackTargetWeightKg ?? 60.0
```

and app wiring constructs `RemoteTargetsSetupRepository` without a target-weight resolver.

Therefore a skipped/ineligible Target Weight can become fabricated `60.0` at the HTTP boundary. Backend finalization can then persist that as canonical `target_weight_kg`.

### Required D2 contract

- active Target Weight transport must use `TargetsSetupData.targetWeightKg`;
- skipped/ineligible Target Weight must not fabricate a numeric value;
- HTTP/backend draft boundary must support omitted/null Target Weight, or completion must safely avoid that incompatible path;
- add active + skipped remote payload tests;
- do not choose a fallback number.

Backend validator/finalizer compatibility must be audited before changing the client transport because the legacy `targetSchema` currently requires numeric `targetWeight`.

---

## 7. Canonical Goal owner persistence — separate decision gate

This remains unresolved and must not be hidden by compatibility mappings.

Current facts:

- active onboarding Goal lives in `GoalIntentSelection`;
- `ProfileSetupMapper` still maps legacy `ProfileOnboardingDraft.goals`;
- canonical `ProfileGoal` vocabulary cannot represent all new Goal intents;
- backend Profile validation requires at least one `goals` item;
- client Nutrition recommendation still reads legacy `profile.goals.firstOrNull`;
- backend finalizer derives metabolic behavior from legacy Profile goal strings and has no authoritative unified `gain_weight` path.

Do not invent mappings such as:

```text
Gain weight      = Build muscle   ❌
Recomposition    = Keep fit       ❌
Improve endurance = Boost strength ❌
```

Canonical Body/Workout/Nutrition Goal persistence needs an explicit owner contract, or completion must remain gated until that contract exists.

---

## 8. Measurement input / picker — blocked

Current source has no active Height/Current Weight/Target Weight input control. The screens display values/cards and accept callbacks, but no wheel/picker implementation was found in current indexed source.

Issue #40 requires preserving the historical measurement wheel/picker language.

Therefore:

- do not invent a new picker;
- obtain approved historical/design/reusable reference first;
- then guarantee:

```text
visible value == selected input position == canonical draft value
```

including Back/Forward/resume and units.

---

## 9. Target Weight recommendation numeric policy — needs product/canonical source

The concept of a deterministic starting recommendation is approved. Exact numeric policy is not.

Current scaffold uses:

```text
±5% directional change
BMI floor 18.5
BMI gain guard 30.0
weight clamp 30..200 kg
```

Treat these as scaffold, not final medical/product authority.

Rules:

- Goal intent is explicit semantic authority;
- BMI may only be a safety input;
- recommendation must never reverse explicit direction;
- user override must survive Back/Forward/resume;
- no invented personalization when authoritative input is insufficient.

---

## 10. Next execution order on PR #50

```text
2B-D1 local acceptance / Review             ✅ CI #1095
        ↓
2B-D2 remote Target Weight transport        NEXT
        ↓
canonical Goal owner / completion decision  REQUIRED
        ↓
measurement picker/reference                BLOCKED
        ↓
Target Weight numeric policy                NEEDS RULE
        ↓
final integrated acceptance + full CI
        ↓
Ready/Merge decision
```

Do not create another 2B PR unless the owner explicitly changes the single-PR strategy.

---

## 11. Non-goals

Not authorized incidentally:

- fake GoalIntent → legacy ProfileGoal mappings;
- canonical Body/Workout Goal schema migration without explicit decision;
- unrelated Supabase schema redesign;
- Injuries & Limitations / Health Concerns changes;
- Special Event changes;
- Equipment taxonomy changes;
- unrelated onboarding redesign;
- changing the Target Weight recommendation constants without approval;
- inventing a replacement measurement picker.

---

## 12. Exit criteria before PR #50 Ready/Merge

### Completed

- [x] #51 tests consolidated; #51 closed unmerged.
- [x] #52 closed unmerged.
- [x] #50 only active implementation PR.
- [x] unified mode-aware Goal screen.
- [x] approved weight-follow-up eligibility.
- [x] Target Weight direction association / dormant restore / opposite clear.
- [x] v4 local draft migration.
- [x] Goal Pace calorie ownership cleanup.
- [x] skipped Goal Pace neutral semantics.
- [x] Review Target Weight/Goal Pace explicit-direction visibility.
- [x] Review unified Goal source correction.
- [x] table-driven local mode/goal acceptance matrix.
- [x] D1 full workspace validation CI #1095.

### Remaining blockers

- [ ] remote HTTP Target Weight transport cannot fabricate `60.0`.
- [ ] backend/client nullability contract for skipped Target Weight resolved.
- [ ] canonical Goal owner/persistence or safe completion-gating decision.
- [ ] client/backend Nutrition Goal semantics no longer silently depend on incompatible legacy goal meaning.
- [ ] approved measurement picker/reference found and restored.
- [ ] display/input/draft measurement synchronization validated.
- [ ] Target Weight numeric recommendation policy explicitly approved/sourced.
- [ ] final full integrated acceptance after remaining fixes.
- [ ] final Flutter analyze green.
- [ ] final Dart analyze green.
- [ ] final Flutter tests green.
- [ ] final Dart tests green.
- [ ] PR body reflects final truth.

### Final status

`IN PROGRESS` on PR #50.  
**Next unblocked technical target:** 2B-D2 remote Target Weight transport/backend compatibility audit + fix.  
**Separate architecture gate:** canonical unified Goal persistence ownership.  
**Blocked visual target:** measurement picker restoration.  
**Product rule gate:** exact Target Weight recommendation policy.
