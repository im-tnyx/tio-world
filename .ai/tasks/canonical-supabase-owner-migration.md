# Canonical Supabase Owner Migration

**Status:** Schema + conflict-safe backfill applied and verified; repository cutover NEXT  
**Canonical owner tracker:** #44  
**Related onboarding tracker:** #40 / PR #50

## Outcome

Tio-world now has the approved canonical owner tables in the live `tio-world` Supabase project. The rollout is additive and future-backend-safe: new domain tables reference `public.users(id)`, while Supabase Auth/RLS remains the current access adapter.

## Approved durable owners

```text
users
user_devices
body_weight_logs
user_body_goals
user_wellness_targets
user_nutrition_profiles
user_nutrition_targets
user_workout_profiles
user_workout_targets
onboarding_drafts
```

Key ownership:

- `users` = account + common Profile; no `user_profiles` table.
- `user_devices` = separate 1:N device owner.
- `body_weight_logs` = weight history/current-weight source.
- `user_body_goals` = lose/gain/maintain/recomposition + Target Weight + Goal Pace + lifecycle.
- `user_wellness_targets` = steps/water/sleep common targets.
- `user_nutrition_profiles` = diet/allergy/preference context only after cutover.
- `user_nutrition_targets` = typed calories/macros/fiber + recommendation/custom metadata.
- `user_workout_profiles` = location/equipment/experience/focus/injuries.
- `user_workout_targets` = Workout goal priority + days/duration/split/special-event constraints.
- `onboarding_drafts` = draft/resume only, never canonical intent.

## Live migrations applied

Database migration history and repository filenames are aligned exactly:

```text
20260821161923_create_canonical_owner_tables.sql
20260821162207_backfill_canonical_owner_data.sql
```

Repository paths:

```text
supabase/migrations/20260821161923_create_canonical_owner_tables.sql
supabase/migrations/20260821162207_backfill_canonical_owner_data.sql
```

Do not edit these applied migrations in place. Any future change must be a new forward migration.

## Schema contract now live

### `body_weight_logs`

- UUID row id
- FK `user_id → public.users(id) ON DELETE CASCADE`
- positive `weight_kg`
- `measured_at`, source/provenance metadata
- `(user_id, measured_at DESC)` index
- updated-at trigger

### `user_body_goals`

- historical rows + one active goal per user via partial unique index
- goal type restricted to `lose_weight | gain_weight | maintain_weight | recomposition`
- Target Weight / weekly pace nullable
- **Maintain/Recomposition are DB-constrained to null Target Weight + pace**
- optional `intent_rank` 1/2 preserves unified Goal priority across Body/Workout owners
- lifecycle/status timestamps

### `user_wellness_targets`

1:1 owner for steps, water, sleep duration, optional bed/wake targets.

### `user_nutrition_targets`

1:1 typed numeric Nutrition targets. BMR/TDEE are deliberately not columns.

### `user_workout_targets`

1:1 current Workout target/plan-constraint owner. Workout-specific goals are restricted to:

```text
build_muscle
get_stronger
improve_endurance
stay_fit
```

Body goals are not mirrored here. Goal rank fields preserve primary/supporting ordering when known.

## Security / backend-safe rules verified

All new owner tables:

- reference `public.users`, not `auth.users`, as the domain FK boundary;
- have RLS enabled;
- explicitly grant authenticated CRUD required by the current app;
- use optimized owner policies with `(select auth.uid()) = user_id`;
- remain usable by a future protected backend through server credentials without changing table semantics.

Post-migration Supabase advisors show **no new RLS-init-plan warnings for the new tables**. Fresh-table unused-index INFO is expected before production query traffic.

Pre-existing unrelated advisor items remain on older tables/functions (legacy direct `auth.uid()` policies, username SECURITY DEFINER RPC warnings, leaked-password protection setting) and are not caused by this migration.

## Backfill contract applied

The backfill is conflict-first and non-destructive:

- conflicting duplicate Profile/Body values block migration;
- fractional Water/Calories that would require lossy casts block migration;
- multiple recognized Body Goal candidates block migration;
- missing `users.height_cm` / `activity_level` may be filled from legacy Nutrition only after conflict checks;
- current weight migrates to one provenance-marked `body_weight_logs` snapshot;
- Body Goal migrates only from exact explicit semantics; never BMI/delta/Target-Weight inference;
- Target Weight + pace migrate only for explicit Lose/Gain;
- Wellness fields migrate to `user_wellness_targets`;
- numeric macro targets migrate to typed `user_nutrition_targets`, customization semantics marked `unknown`;
- Workout plan fields migrate to `user_workout_targets`;
- legacy Goal synonyms are not guessed/remapped.

At rollout time the affected live legacy tables had **0 rows**, so the applied backfill was a clean no-op. The migration remains deterministic for other/non-empty environments.

## Post-migration validation evidence

Verified live:

```text
canonical row counts                 0 (expected: no existing users/data)
duplicate active Body Goal groups    0
invalid Maintain/Recomp follow-ups   0
FKs bypassing public.users           0
RLS enabled on all new tables        yes
authenticated CRUD grants            yes
migration history ↔ repo versions    aligned
```

## Legacy compatibility state

Old mixed columns/tables are intentionally still present. They are **not yet removed** because app repositories still write/read them.

Do not drop yet:

```text
users.current_weight_kg
users.target_weight_kg
users.goals
users.primary_goal
mixed Body/Wellness/target columns in user_nutrition_profiles
plan-target fields still present in user_workout_profiles
```

No permanent bidirectional sync should be introduced.

## Next implementation phase — repository/model cutover

Work in this order:

```text
1. define canonical repository/domain contracts per owner
2. cut Body/current-weight persistence to body_weight_logs + user_body_goals
3. cut Wellness persistence to user_wellness_targets
4. split Nutrition Profile vs user_nutrition_targets writes
5. split Workout Profile vs user_workout_targets writes
6. make Onboarding + Settings consume the same owner repositories
7. remove legacy Target Weight 60kg/fallback adapter behavior where still reachable
8. stop all writes to legacy mirrored columns
9. verify reads/backward compatibility
10. run full onboarding persistence acceptance + Flutter/Dart CI
11. later forward migration removes obsolete columns only after cutover proof
```

PR #50 remains Draft/unmerged until repository cutover + onboarding persistence acceptance are green.

## Guardrails

- one durable owner per concept;
- no fake Goal mappings;
- no numeric/BMI semantic inference;
- App Mode visibility must not delete hidden owner data;
- Settings and Onboarding are entry points, not owners;
- future backend must use the same canonical tables, not a parallel schema;
- no legacy column drop before verified repository cutover;
- no Target Weight recommendation-formula change in this migration work;
- no UI redesign/picker invention here.
