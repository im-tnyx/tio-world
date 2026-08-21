# Product Onboarding Slice 2B — Target Weight and Goal Pace

**Status:** In progress  
**Primary owner:** `apps/features/onboarding`  
**GitHub tracker:** #40  
**Canonical implementation PR:** #50 `feat(onboarding): activate unified mode-aware Goal screen`  
**Canonical branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`  
**Execution decision:** keep one active implementation PR (#50) in `tio-world`. Do not merge to `main` until the remaining Product + technical gates are satisfied. A separate backend PR in `tnyx-hub` is allowed/required only when an API contract change cannot live in the app repository.

---

## 0. Canonical continuation context — read first

This file is the durable handoff. Continue from repository state here instead of relying on chat history.

### PR topology

- **PR #50** is the only active `tio-world` implementation PR. It remains Draft/unmerged.
- **PR #51** is closed/unmerged as superseded. Its two useful eligibility/reconciliation tests were consolidated into #50.
- **PR #52** is closed/unmerged validation-only. Do not reopen or merge it.

### Latest validated checkpoints

```text
Goal + eligibility baseline                     ✅
2B-B1 Target Weight state/domain persistence    ✅ CI #1079
2B-C Goal Pace ownership/default semantics      ✅ CI #1090
2B-D1 local acceptance + Review Goal source     ✅ CI #1095
2B-D2 transport contract audit                  ✅ audit complete, implementation pending
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

This does **not** make PR #50 Ready. D2 transport implementation, canonical Goal owner persistence, measurement input restoration, and final Target Weight recommendation policy remain unresolved.

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

### Important D2 audit correction

The B1 guarantee is safe at the onboarding-domain mapper boundary, but repeat owner writes need explicit clear semantics in both HTTP and Supabase persistence paths. Omitting an inactive target can retain stale previously persisted state. See 2B-D2 below.

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

## 6. 2B-D2 Target Weight owner transport — AUDIT COMPLETE, IMPLEMENTATION PENDING

### Audit scope

Audited end-to-end Target Weight transport across:

- onboarding `TargetsSetupMapper` output;
- Nutrition `TargetsSetupData`;
- HTTP `TargetsSetupDtoMapper`;
- `RemoteTargetsSetupRepository`;
- `HttpTargetsSetupRemoteDataSource`;
- app repository wiring;
- backend onboarding `targetSchema`;
- backend `saveDraft()` merge/validation semantics;
- backend finalization payload;
- atomic finalization RPC;
- Supabase `TargetsSetupRepository` parity;
- current remote tests.

No production source was changed in this audit.

### Confirmed client defect

Nutrition domain already has the correct authority:

```text
TargetsSetupData.targetWeightKg: double?
```

But HTTP DTO currently ignores it and emits:

```text
'ttargetWeight': fallbackTargetWeightKg ?? 60.0
```

`RemoteTargetsSetupRepository` separately calls an optional `targetWeightResolver`, and app wiring constructs that repository without a resolver.

Result today:

```text
skipped Target Weight
→ onboarding mapper: null        ✅
→ TargetsSetupData: null         ✅
→ HTTP DTO: 60.0                 ❌ fabricated intent
```

Existing remote tests encode this compatibility path by injecting resolver values instead of testing domain-authoritative active/null cases.

### Confirmed backend constraint

`/api/v1/onboarding/target` sends:

```text
{ data: <target payload>, isCompleted: true }
```

Current backend `targetSchema` requires:

```text
targetWeight: number 20..300
```

Backend `saveDraft()` performs strict section validation when `isCompleted == true`.

Therefore changing the client to send `null` before the backend contract changes would produce HTTP 400.

### Omission is NOT safe

Backend `saveDraft()` shallow-merges new target payload over existing `target_data`:

```text
mergedData = { ...currentSectionData, ...payloadData }
```

Therefore this sequence is unsafe:

```text
Lose weight
→ backend targetWeight = 64
→ user changes to Maintain
→ client omits targetWeight
→ merged backend target_data still contains 64   ❌ stale hidden intent
```

The inactive state must explicitly overwrite old backend draft state.

### Required backend contract

For completed Target sections, the clean transport contract is:

```text
targetWeight: number | null
```

Recommended validator shape:

```text
targetWeight: z.number().min(20).max(300).nullable()
```

Keep the key required, but allow `null`.

Why required-nullable instead of optional:

- active flow explicitly sends a number;
- inactive/skipped flow explicitly sends null;
- a missing key cannot silently preserve stale backend Target Weight during merge;
- existing released clients already send a number, so backend-first deployment remains backward-compatible.

### Backend finalization is already null-capable

`FinalizeTargetData.targetWeight` is already optional.

Finalization uses:

```text
target_weight_kg: toNullableNumber(targetData.targetWeight)
```

and `toNullableNumber(null/undefined)` returns null.

The atomic finalization RPC reads the target field into nullable numeric form and writes `target_weight_kg` accordingly.

Repository database baseline also declares `user_nutrition_profiles.target_weight_kg` nullable. That baseline explicitly says it is inferred rather than a verified live export, so live DB nullability must still be verified before deployment; do not claim production schema proof from that file alone.

### Supabase parity defect

`SupabaseTargetsSetupRepository` currently builds canonical payload with:

```text
if (data.targetWeightKg != null)
  'target_weight_kg': data.targetWeightKg
```

This is safe for a fresh null insert, but not necessarily for an existing row that already has a Target Weight. An omitted key on a later upsert can leave the previous canonical value unchanged.

Required current-intent semantics:

```text
active target   → target_weight_kg = actual number
inactive target → target_weight_kg = null
```

Therefore canonical Supabase payload should explicitly carry the nullable field rather than conditionally omitting it, subject to live schema verification.

### Required D2 implementation split

#### D2-A backend first — `tnyx-hub`

A small backend PR is required because #50 cannot change another repository.

Change:

- onboarding `targetSchema.targetWeight` from required number to required nullable number;
- add validator/service tests for:
  - active number accepted;
  - null accepted;
  - missing key rejected on completed target payload;
  - out-of-range number rejected;
  - existing target overwritten by explicit null during merge if service-level test infrastructure supports it;
- add/extend finalizer coverage proving null produces `target_weight_kg = null`.

Deployment order:

```text
backend nullable contract first
↓
client D2-B second
```

Do not ship the client-null behavior before backend support exists.

#### D2-B client — PR #50 in `tio-world`

After backend contract exists:

- `TargetsSetupDtoMapper` must use `data.targetWeightKg` directly;
- payload must include `targetWeight` even when the value is null;
- remove fabricated `60.0` fallback;
- remove `fallbackTargetWeightKg` mapper parameter if no longer needed;
- remove `targetWeightResolver` compatibility path from `RemoteTargetsSetupRepository` if no remaining caller requires it;
- app repository wiring remains straightforward, with no Target Weight resolver;
- update remote tests:
  - active `targetWeightKg = 58.5` → `targetWeight: 58.5`;
  - skipped `targetWeightKg = null` → `targetWeight: null`;
  - no resolver/fallback number exists.

#### D2-C Supabase parity — PR #50

- canonical `user_nutrition_profiles` upsert must explicitly send nullable `target_weight_kg`;
- add coverage for active number and inactive null/clear behavior where repository test infrastructure allows;
- do not add a schema migration solely for this code change unless live schema verification proves null is disallowed.

### D2 acceptance contract

```text
Active Lose/Gain
onboarding active target
→ TargetsSetupData.targetWeightKg = number
→ HTTP targetWeight = same number
→ Supabase target_weight_kg = same number
→ final canonical target = same number

Maintain/Recomposition/training-only
onboarding target dormant in local draft
→ TargetsSetupData.targetWeightKg = null
→ HTTP targetWeight = null
→ backend target_data.targetWeight = null
→ Supabase target_weight_kg = null
→ final canonical target = null
```

Local onboarding draft may retain the dormant user value for reversible goal changes. Owner transports must consume only current eligible intent.

### Cross-repository PR rule

The single-PR strategy still means one active implementation PR in `tio-world` (#50). D2 requires a separate, narrowly scoped `tnyx-hub` backend PR because the API validator lives in another repository. Do not create another `tio-world` 2B PR.

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
Gain weight       = Build muscle    ❌
Recomposition     = Keep fit        ❌
Improve endurance = Boost strength  ❌
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

## 10. Next execution order

```text
2B-D1 local acceptance / Review                 ✅ CI #1095
        ↓
2B-D2 transport audit                            ✅
        ↓
D2-A tnyx-hub backend nullable contract          NEXT
        ↓ deploy backend contract
D2-B tio-world HTTP transport on PR #50          THEN
D2-C tio-world Supabase explicit-null parity      THEN
        ↓
D2 active/null transport acceptance              REQUIRED
        ↓
canonical Goal owner / completion decision       REQUIRED
        ↓
measurement picker/reference                     BLOCKED
        ↓
Target Weight numeric policy                     NEEDS RULE
        ↓
final integrated acceptance + full CI
        ↓
Ready/Merge decision
```

Do not create another `tio-world` 2B PR unless the owner explicitly changes the single-PR strategy.

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
- [x] #50 only active `tio-world` implementation PR.
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
- [x] D2 HTTP/backend/Supabase transport audit.
- [x] explicit-null requirement identified from backend merge semantics.
- [x] backend-first rollout order identified.

### Remaining blockers

- [ ] `tnyx-hub` target completion validator accepts required `number | null` Target Weight.
- [ ] backend active/null contract tests green.
- [ ] PR #50 HTTP transport uses `TargetsSetupData.targetWeightKg` directly.
- [ ] fabricated `60.0` and resolver fallback removed.
- [ ] PR #50 Supabase owner write explicitly clears inactive Target Weight with null.
- [ ] active + skipped Target Weight transport tests green across supported paths.
- [ ] live DB nullability verified before rollout or migration supplied if verification disproves it.
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
**Next technical target:** D2-A backend required-nullable Target Weight contract in `tnyx-hub`.  
**Then:** D2-B/D2-C client transport parity on PR #50.  
**Separate architecture gate:** canonical unified Goal persistence ownership.  
**Blocked visual target:** measurement picker restoration.  
**Product rule gate:** exact Target Weight recommendation policy.
