# Canonical Body Owner Repository Cutover

**Status:** In progress  
**Primary owner:** `apps/features/progress` + app composition with Profile/Settings  
**Affected platforms:** Flutter phone app / Supabase persistence

## Outcome

Make `body_weight_logs` + `user_body_goals` the authoritative Body persistence path without changing UI or inventing goal semantics.

## Canonical ownership

```text
body_weight_logs
→ time-varying weight history
→ latest applicable row = canonical current weight

user_body_goals
→ lose/gain/maintain/recomposition
→ starting weight
→ Target Weight when applicable
→ Goal Pace when applicable
→ lifecycle/status
```

Profile and Nutrition may consume Body data but must not remain canonical Body owners.

## Body Cutover A — VALIDATED ✅

Implemented:

```text
Onboarding draft
→ BodySetupMapper
→ BodySetupRepository
→ SupabaseBodySetupRepository
→ body_weight_logs + user_body_goals
```

Validated source/test checkpoint:

```text
9031dc5e51a71b1bcef905bd93088f36396d3c01
Flutter CI #1135 / run 32505095642
Analyze Flutter packages  ✅
Analyze Dart packages     ✅
Test Flutter packages     ✅
Test Dart packages        ✅
```

Proven behavior:

- only explicit Body intents persist;
- no BMI/delta inference and no `Build muscle = Gain weight` mapping;
- Target Weight is consumed only for the matching explicit loss/gain direction;
- Maintain/Recomposition cannot persist Target Weight/Goal Pace;
- changed Body goal supersedes the old active goal;
- training-only/no-Body intent does not invent a Body direction;
- invalid Body payloads are rejected before Body DB mutation.

## Body Cutover B audit — COMPLETE

### Current read gap

`BodySetupRepository` currently has only:

```dart
Future<void> saveBodySetup(BodySetupData data);
```

There is no canonical read API for latest weight or active Body Goal yet.

`profileDataProvider` still exposes `ProfileSetupRepository.watchProfileSetup()`, so Profile Settings gets current weight from legacy Profile state rather than the Body owner.

### Current Profile ownership leaks

`ProfileSetupData` still contains legacy/mixed Body fields:

- `goals`
- `currentWeightKg`
- `targetWeightKg`

`SupabaseProfileSetupRepository` still writes to `users`:

- `primary_goal`
- `goals`
- `current_weight_kg`
- `target_weight_kg`

It also reads current weight from `users.current_weight_kg` and fabricates `70.0` when missing. That default must not become canonical Body truth.

`ProfileSetupMapper` still maps legacy Profile goals plus current/target weight into `ProfileSetupData`; it also has a `70.0` current-weight compatibility default. Once canonical Body read/write parity exists, these Body fields must leave the Profile persistence contract.

### Current Profile Settings ownership leak

`ProfileSettingsUpdate` currently describes current weight as a Profile-owned mutation.

`ProfileSettingsWriteMapper` writes `current_weight_kg` into `users`.

`SaveProfileSettingsUseCase` validates and forwards current weight through the Profile repository.

`ProfileSettingsRoute` displays `profileData.currentWeightKg` and saves current weight through the Profile use case.

This must become cross-owner app composition:

```text
username     → ProfileAccountRepository
common Profile fields → ProfileSettingsRepository
current weight → BodySetupRepository / Body weight command
```

Do not make the Profile feature depend on Progress merely to coordinate a screen. Cross-owner coordination belongs in app/composition.

### Current Nutrition coupling — do NOT remove in isolation

`TargetsSetupData` and `SupabaseTargetsSetupRepository` are still a mixed legacy contract containing:

- Profile mirrors: height/activity;
- Body mirrors: current weight/Target Weight/Goal Pace;
- Wellness: steps/water/sleep;
- Nutrition targets/recommendation.

`getTargetsSetup()` currently requires legacy `weekly_weight_change_kg` and other Wellness fields. Therefore removing only the Nutrition Body columns during Body Cutover B would create a half-migrated repository contract.

**Decision:** Nutrition Body mirror shutdown moves to the Wellness/Nutrition repository split. Temporary Nutrition mirror writes remain explicitly transitional; no new synchronization logic may be added.

### Canonical read/fallback rule

After migrations are applied, canonical Body tables win whenever data exists.

Do not silently fall back to fabricated `70 kg` or infer a Body Goal from legacy numeric state.

For true pre-cutover compatibility, only an explicit legacy-read fallback may be used when canonical Body data is absent and a real persisted legacy value exists. Canonical data must always take precedence, and the fallback must be removed after cutover verification.

Current production rollout had no affected legacy rows at migration time, so a missing canonical value should normally be treated as unknown/incomplete rather than invented.

### Weight-history write semantics

Onboarding currently uses provenance source `onboarding_setup` and updates that setup snapshot on retry.

Profile Settings must **not overwrite the onboarding snapshot**. A user changing current weight later should create a new weight-history entry with Settings provenance (for example `profile_settings`) and a new `measured_at` timestamp.

Latest applicable `measured_at` wins for current weight.

## Revised implementation order

### B1 — canonical Body read/command contract

- [ ] add backend-neutral Body read model for latest weight + active Body Goal;
- [ ] add `get` and/or `watch` Body-state API to the Progress repository contract;
- [ ] add explicit current-weight command that records a new history row for post-onboarding edits;
- [ ] Supabase read: latest `body_weight_logs` by `measured_at DESC`;
- [ ] Supabase read: `user_body_goals` where `status = active`;
- [ ] keep onboarding retry semantics separate from post-onboarding weight-history inserts;
- [ ] add in-memory parity for tests/local harnesses;
- [ ] add focused canonical-first/no-fabricated-default tests.

Recommended domain shape, naming may be adjusted during implementation:

```text
BodyState
├─ latestWeight
└─ activeGoal

BodyWeightEntry
├─ weightKg
├─ measuredAt
└─ source
```

### B2 — Profile domain boundary cleanup

- [ ] narrow `ProfileSetupData` to common Profile data; remove Body Goal/current/target-weight ownership;
- [ ] remove `goals/currentWeightKg/targetWeightKg` from Profile Supabase writes;
- [ ] remove legacy Body parsing/defaults from Profile read mapping;
- [ ] narrow onboarding `ProfileSetupMapper` to common Profile only;
- [ ] update Profile repository/in-memory tests;
- [ ] keep onboarding draft current weight because onboarding is allowed to collect it; only durable owner changes.

Legacy `ProfileGoal` migration compatibility may remain temporarily if another compatibility path still needs the enum, but it must not remain canonical Profile persistence.

### B3 — Profile Settings cross-owner composition

- [ ] remove `currentWeightKg` from Profile-owned `ProfileSettingsUpdate`;
- [ ] `ProfileSettingsWriteMapper` writes only Profile fields to `users`;
- [ ] `SaveProfileSettingsUseCase` owns only account/common Profile mutations;
- [ ] app-level Profile Settings composition watches both common Profile + canonical Body state;
- [ ] screen current weight comes from canonical Body state;
- [ ] Settings weight save records a new `body_weight_logs` entry;
- [ ] invalidate/refresh both Profile and Body providers after successful save;
- [ ] if canonical current weight is genuinely absent, do not silently persist a UI default as truth;
- [ ] update route/use-case/repository tests.

### B4 — Profile mirror shutdown verification

Verify no active app write path still writes these Profile mirrors:

```text
users.current_weight_kg
users.target_weight_kg
users.goals
users.primary_goal
```

Do not drop the DB columns yet. Column removal is a later forward migration after all owner cutovers and data-integrity acceptance.

### B5 — full validation

- [ ] Profile Settings current weight displays latest canonical log;
- [ ] Settings weight edit creates a new history row;
- [ ] onboarding retry does not create uncontrolled duplicate setup logs;
- [ ] canonical row wins over stale legacy Profile value;
- [ ] no `70 kg` fabricated canonical state;
- [ ] active Target Weight/Goal Pace come from `user_body_goals` where consumed;
- [ ] Profile save does not mutate Body columns;
- [ ] full Flutter analyze;
- [ ] full Dart analyze;
- [ ] full Flutter tests;
- [ ] full Dart tests.

## Dependent cleanup after Body B

Nutrition still contains transitional Body mirrors because its repository is structurally mixed with Wellness/Nutrition targets. Remove those mirrors during the next canonical split:

```text
Wellness → user_wellness_targets
Nutrition context → user_nutrition_profiles
Nutrition numeric targets → user_nutrition_targets
```

At that point remove Nutrition persistence of current weight, Target Weight, Goal Pace, height/activity mirrors and make Nutrition calculations read true Profile/Body owners.

## Known finalization concern — later acceptance gate

Current app composition uses an in-memory Body repository when Supabase is unavailable. A future protected backend needs its own Body adapter using this same backend-neutral domain contract; in-memory fallback must never be mistaken for durable production persistence during final completion acceptance.

This is not a reason to create a parallel backend schema.

## Guardrails

- no UI redesign;
- no Target Weight recommendation formula change;
- no invented measurement picker;
- no fake Goal mapping;
- no BMI/current-target semantic inference;
- no permanent dual-write synchronization;
- no legacy DB column drop during B;
- future backend uses the same canonical owner model.

## Final status

`PARTIAL` — Body Cutover A validated; Body Cutover B audit complete and implementation-ready. Next implementation starts at B1 canonical Body read/command contract.
