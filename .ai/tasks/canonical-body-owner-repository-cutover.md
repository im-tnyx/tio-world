# Canonical Body Owner Repository Cutover

**Status:** In progress  
**Primary owner:** `apps/features/progress` + onboarding composition  
**Affected platforms:** Flutter phone app / Supabase persistence

## 1. Discovery

### User Outcome

Make the live canonical Body tables the authoritative persistence path without changing UI or inventing goal semantics.

### Success Criteria

- `body_weight_logs` owns persisted current weight.
- `user_body_goals` owns explicit Body Goal, Target Weight, Goal Pace and lifecycle.
- onboarding completion writes Body data through a Body repository instead of Profile/Nutrition mirrors.
- Maintain/Recomposition never persist Target Weight or Goal Pace.
- no BMI/delta inference and no `Build muscle = Gain weight` mapping.
- legacy columns remain for compatibility until later cutover proof; no permanent dual-write.

### Scope

Body Cutover A only:
- establish Progress-owned Body domain/repository contract;
- Supabase implementation over `body_weight_logs` + `user_body_goals`;
- wire app provider;
- wire onboarding owner persistence to Body repository;
- remove onboarding Body consumption from Profile/Targets mappers where needed;
- focused repository + onboarding tests.

### Non-Goals

- UI changes;
- Profile Settings Body read/write cutover (next sub-slice);
- Wellness/Nutrition/Workout target repository split;
- legacy column drops;
- recommendation formula changes;
- measurement picker work;
- protected backend implementation.

## 2. Codebase Exploration

### Verified Evidence

- live migrations `20260821161923_create_canonical_owner_tables` and `20260821162207_backfill_canonical_owner_data` are applied.
- `SupabaseProfileSetupRepository` still writes `current_weight_kg`, `target_weight_kg`, `goals`, `primary_goal` to `users`.
- `SupabaseTargetsSetupRepository` still writes current/target weight and weekly pace to `user_nutrition_profiles`.
- `ProfileSettingsWriteMapper` still writes `current_weight_kg` to `users`.
- `apps/features/progress` is an existing scaffold with no Body persistence domain yet.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Body repository lives in Progress | Approved for this slice | Weight/progress is canonical owner and avoids Profile/Nutrition ownership | #44 contract |
| Onboarding uses canonical Body repository directly | Approved | Onboarding is orchestration, not owner | #40/#44 |
| Settings compatibility remains temporarily | Deferred | Keep slice small; cut over after canonical write path is proven | next sub-slice |

## 4. Architecture Design

```text
Onboarding draft
  -> BodySetupMapper
  -> BodyRepository (Progress domain)
  -> SupabaseBodyRepository
  -> body_weight_logs + user_body_goals
```

Profile repository continues common Profile persistence only for onboarding path. Nutrition targets must not be the permanent Body owner.

## 5. Implementation Plan

- [ ] add Progress Body domain model/repository + Supabase implementation
- [ ] export public Progress contract and add Supabase dependency
- [ ] add onboarding dependency on Progress
- [ ] add Body mapper from explicit `GoalIntentSelection` + Profile/Targets draft
- [ ] persist Body owner in `PersistOnboardingOwnerDataUseCase`
- [ ] stop onboarding Profile mapper from semantically consuming Target Weight/legacy Goal
- [ ] stop onboarding Targets mapper from treating Body fields as durable owner values
- [ ] wire app provider/completion coordinator
- [ ] add focused tests
- [ ] run CI / update handoff

## 6. Quality Review

### Validation Run

Not run yet.

## 7. Final Handoff

### Known Limitations

Profile Settings still has legacy Body writes until the next owner-parity sub-slice.

### Final Status

`PARTIAL` until implementation + CI complete.
