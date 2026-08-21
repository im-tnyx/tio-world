# Canonical Supabase Owner Migration

**Status:** Schema + conflict-safe backfill applied; Body Cutover A validated; repository cutover in progress  
**Canonical owner tracker:** #44  
**Related onboarding tracker:** #40 / PR #50

## Outcome

Tio-world has the approved canonical owner tables in the live `tio-world` Supabase project. The rollout is additive and future-backend-safe: new domain tables reference `public.users(id)`, while Supabase Auth/RLS remains the current access adapter.

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

Ownership:

- `users` = account + common Profile; no separate `user_profiles` table.
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

```text
supabase/migrations/20260821161923_create_canonical_owner_tables.sql
supabase/migrations/20260821162207_backfill_canonical_owner_data.sql
```

Do not edit these applied migrations in place. Any future schema change must use a new forward migration.

## Live schema/security contract verified

- new domain FKs reference `public.users(id)`, not `auth.users(id)` directly;
- RLS enabled;
- authenticated CRUD grants present;
- optimized `(select auth.uid()) = user_id` owner policies;
- one active Body Goal per user enforced;
- Maintain/Recomposition cannot store Target Weight/Goal Pace;
- no invalid/orphan canonical rows found after migration;
- no new RLS-init-plan advisor warnings for the new tables.

At rollout time the affected legacy owner tables had 0 rows, so the conflict-safe backfill was a clean no-op. The migration remains deterministic for non-empty environments and never guesses ambiguous Goal semantics.

## Legacy compatibility state

Old mixed columns/tables remain physically present because repository cutover is not complete.

Do not drop yet:

```text
users.current_weight_kg
users.target_weight_kg
users.goals
users.primary_goal
mixed Body/Wellness/target columns in user_nutrition_profiles
plan-target fields still present in user_workout_profiles
```

No permanent bidirectional synchronization should be introduced.

## Repository cutover progress

### Body Cutover A — validated

Implemented under `apps/features/progress` and onboarding composition:

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

The Body repository only maps explicit Body semantics, preserves Target Weight direction association, rejects invalid Maintain/Recomposition follow-ups before DB mutation, and does not infer Body goals from BMI/delta/training-only intent.

### Body Cutover B — NEXT

Canonical read/write parity must be proven before legacy mirrors are stopped:

```text
1. canonical Body read API
   → latest current weight from body_weight_logs
   → active Body Goal from user_body_goals
2. Profile/Profile Settings read canonical Body state
3. Profile Settings current-weight save writes canonical Body owner
4. canonical provider refresh/invalidation
5. prove no stale/default reads
6. stop users/Profile Body mirror writes
7. stop Nutrition Body mirror writes
8. full Flutter/Dart CI
```

## Remaining owner cutover order

After Body Cutover B:

```text
Wellness
→ user_wellness_targets

Nutrition
→ user_nutrition_profiles context
→ user_nutrition_targets numeric targets

Workout
→ user_workout_profiles capability/context
→ user_workout_targets goals/plan constraints

Then
→ Onboarding + Settings same owner contracts
→ stop all remaining legacy mirrored writes
→ integrated persistence acceptance
→ later cleanup migration removes obsolete columns only after proof
```

## Guardrails

- one durable owner per concept;
- no fake Goal mappings;
- no numeric/BMI semantic inference;
- App Mode visibility must not delete hidden owner data;
- Settings and Onboarding are entry points, not owners;
- future backend must use the same canonical tables, not a parallel schema;
- no legacy column drop before verified repository cutover;
- no Target Weight recommendation-formula change in migration work;
- no UI redesign/picker invention here.
