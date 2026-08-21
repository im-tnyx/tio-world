# Canonical Body Owner Repository Cutover

**Status:** In progress — Body B1 validated; B2/B3 paused behind Profile foundation P1/P3  
**Primary owner:** `apps/features/progress` + app composition with Profile/Settings  
**Affected platforms:** Flutter phone app / Supabase persistence

## Active execution checkpoint

```text
Canonical PR: #50 (Draft / unmerged)
Branch: agent/onboarding-slice-2-step-1-body-goal-ui
Body B1 source/test head: e3822b81d2c8793191cfb8a208257fd2bc8bc7dd
Flutter CI #1153 / run 32508150413 ✅ all four gates
```

Body B1 is complete. Do not start the old B2 Profile cleanup directly against `users`; the canonical Profile owner has now been approved as `user_profiles`.

Read `.ai/tasks/account-profile-app-preferences-canonical-split.md` before resuming B2/B3.

## Outcome

Make `body_weight_logs` + `user_body_goals` the authoritative Body persistence path without changing UI or inventing Goal semantics.

## Canonical Body ownership

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

Common Profile is now planned under `user_profiles`, not `users`.

## Body Cutover A — VALIDATED ✅

```text
Onboarding draft
→ BodySetupMapper
→ BodySetupRepository
→ SupabaseBodySetupRepository
→ body_weight_logs + user_body_goals
```

Validated checkpoint:

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

## Body Cutover B1 — VALIDATED ✅

Implemented:

- backend-neutral `BodyRepository` while onboarding retains narrow `BodySetupRepository`;
- `BodyState` for latest canonical weight + active Body Goal;
- `BodyWeightEntry` / `BodyWeightRecord` history contract;
- canonical read from latest `body_weight_logs` by `measured_at DESC`;
- canonical active Goal read from `user_body_goals` status `active`;
- missing canonical value stays unknown/null; no fabricated `70 kg`;
- malformed canonical rows are rejected instead of defaulted/inferred;
- post-onboarding weight command appends a new history row;
- onboarding setup retry remains separate and may reconcile its reserved `onboarding_setup` snapshot;
- post-onboarding command cannot misuse reserved `onboarding_setup` provenance;
- in-memory parity + focused mapper/read/history tests.

Validated checkpoint:

```text
e3822b81d2c8793191cfb8a208257fd2bc8bc7dd
Flutter CI #1153 / run 32508150413
Analyze Flutter packages  ✅
Analyze Dart packages     ✅
Test Flutter packages     ✅
Test Dart packages        ✅
```

## Profile architecture correction

Earlier Body B planning assumed common Profile would remain on `users`. That assumption is superseded.

Final direction:

```text
users
→ account/domain root

user_profiles
→ common Profile

body_weight_logs + user_body_goals
→ Body
```

Therefore B2/B3 must run only after the additive `user_profiles` foundation and Profile repository cutover are ready.

## Current source leaks to remove later

Legacy Profile models/repositories still contain Body fields:

- `goals`;
- `currentWeightKg`;
- `targetWeightKg`;
- writes to `users.current_weight_kg`;
- writes to `users.target_weight_kg`;
- writes to `users.goals`;
- writes to `users.primary_goal`;
- legacy Profile read/default behavior including fabricated `70.0` compatibility value.

Profile Settings also still treats current weight as a Profile-owned mutation.

These are now **P4 / Body B2-B3 cleanup**, after `user_profiles` becomes canonical.

## Dependency before Body B2/B3

From `.ai/tasks/account-profile-app-preferences-canonical-split.md`:

```text
P1 create user_profiles + user_app_preferences
        ↓
P2 durable App Mode/preferences cutover
        ↓
P3 common Profile repository cutover to user_profiles
        ↓
P4 resume Body B2/B3
```

P2 and P3 may be separate validated slices; do not combine them just to reach Body faster.

## Body B2/B3 — resume only at P4

### B2 — remove Body ownership from Profile contract

- [ ] remove Body Goal/current/target-weight ownership from Profile models/mappers;
- [ ] stop Profile-side legacy Body writes;
- [ ] remove Profile legacy Body parsing/defaults;
- [ ] keep onboarding draft current weight because onboarding may collect it, while durable owner remains Body;
- [ ] preserve backend-neutral Body contracts.

### B3 — Profile Settings cross-owner composition

Target composition:

```text
account fields
→ users/account repository

common Profile fields
→ user_profiles/Profile repository

current weight
→ BodyRepository.recordCurrentWeight(...)

Target Weight / Goal Pace / Body Goal
→ user_body_goals
```

- [ ] screen reads current weight from canonical Body state;
- [ ] Settings current-weight edit appends a `body_weight_logs` row with `profile_settings` provenance;
- [ ] Settings common Profile save writes `user_profiles`;
- [ ] invalidate/refresh both Profile and Body state after save;
- [ ] canonical Body state wins over stale legacy values;
- [ ] unknown canonical weight stays unknown and is never silently persisted as a UI default.

### B4 — Profile Body mirror shutdown verification

Verify no active app write path still writes:

```text
users.current_weight_kg
users.target_weight_kg
users.goals
users.primary_goal
```

Do not drop DB columns yet.

### B5 — full Body/Profile validation

- [ ] Profile Settings current weight displays latest canonical log;
- [ ] Settings weight edit creates a new history row;
- [ ] onboarding retry does not create uncontrolled duplicate setup logs;
- [ ] canonical row wins over stale legacy Profile value;
- [ ] no `70 kg` fabricated canonical state;
- [ ] active Target Weight/Goal Pace come from `user_body_goals`;
- [ ] Profile save does not mutate legacy Body columns;
- [ ] full Flutter analyze;
- [ ] full Dart analyze;
- [ ] full Flutter tests;
- [ ] full Dart tests.

## Nutrition-side Body mirrors — later dependent cleanup

Do not remove Nutrition Body mirrors in isolation. Current `TargetsSetupRepository` still mixes Body + Wellness + Nutrition.

Remove them only during the Wellness/Nutrition split:

```text
Wellness → user_wellness_targets
Nutrition context → user_nutrition_profiles
Nutrition numeric targets → user_nutrition_targets
```

Then Nutrition calculators/repositories read true `user_profiles` + Body owners instead of persisting duplicate inputs.

## Guardrails

- no UI redesign;
- no Target Weight recommendation formula change;
- no invented measurement picker;
- no fake Goal mapping;
- no BMI/current-target semantic inference;
- no permanent dual-write synchronization;
- no legacy DB column drop during Body cutover;
- future backend uses the same canonical owner model.

## Final status

`PARTIAL` — Body Cutover A and B1 validated. Next work is **not** Body B2 directly; first complete P1/P2/P3 from the Account/Profile/App Preferences split task, then resume Body at P4.
