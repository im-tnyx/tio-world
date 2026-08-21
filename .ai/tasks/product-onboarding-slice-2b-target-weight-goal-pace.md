# Product Onboarding Slice 2B — Target Weight and Goal Pace

**Status:** In progress  
**Primary owner:** `apps/features/onboarding`  
**GitHub tracker:** #40  
**Canonical ownership tracker:** #44  
**Canonical implementation PR:** #50  
**Canonical branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

PR #50 remains Draft/unmerged.

## Current validated/product truth

```text
Unified Goal activation                         ✅
Weight-follow-up eligibility                     ✅
2B-B1 Target Weight draft semantics             ✅ CI #1079
2B-C Goal Pace ownership/UI cleanup             ✅ CI #1090
2B-D1 integrated local acceptance + Review      ✅ CI #1095
Persistence/owner audit                          ✅
#44 canonical owner contract                     ✅
Canonical Supabase schema migration              ✅ LIVE
Conflict-safe legacy backfill                    ✅ LIVE
Repository/model owner cutover                   ⏳ NEXT
```

Latest validated Flutter source/test checkpoint before schema/docs work:

```text
6c3dcb527bc92b3a6b46755d2d8c569682d090f4
Flutter CI #1095 / run 32497930346
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Approved Goal contract

`GoalIntentSelection` is onboarding semantic authority.

Nutrition:

```text
Lose weight      → Target Weight + Goal Pace
Gain weight      → Target Weight + Goal Pace
Maintain weight  → skip both
Recomposition    → skip both
```

Workout / Hybrid:

```text
Lose weight primary/supporting → Target Weight + Goal Pace
training-only goals            → skip both
```

Rules:

- Nutrition single-select.
- Workout/Hybrid max two compatible goals.
- `Build muscle != Gain weight`.
- No Goal inference from BMI/current-target delta.
- No fake GoalIntent → legacy ProfileGoal mappings.

Local draft schema v4 stores Target Weight + loss/gain association. Eligible→ineligible preserves dormant value; same direction restores; opposite loss↔gain clears incompatible scalar Target Weight.

Goal Pace owns weekly body-weight change only. BMR/TDEE/calorie math was removed from Goal Pace; slider/haptics/warnings/projection remain.

## Canonical Supabase owner contract — now live

```text
users
→ account + common Profile

user_devices
→ separate 1:N device owner

body_weight_logs
→ weight history / current-weight source

user_body_goals
→ lose/gain/maintain/recomposition
→ starting weight / Target Weight / weekly pace / lifecycle

user_wellness_targets
→ steps / water / sleep / optional bed-wake targets

user_nutrition_profiles
→ diet/allergy/food-preference context

user_nutrition_targets
→ calories/protein/carbs/fat/fiber + recommendation/custom metadata

user_workout_profiles
→ location/equipment/experience/focus/injuries

user_workout_targets
→ Workout-specific goal priority + days/duration/split/special event

onboarding_drafts
→ draft/resume only
```

New domain owner FKs point to `public.users(id)`, not directly to `auth.users`, so a future protected backend can consume the same data model.

## Live migrations applied

```text
20260821161923_create_canonical_owner_tables
20260821162207_backfill_canonical_owner_data
```

Repository filenames match the live migration versions exactly.

The first migration is additive only; no legacy columns were dropped.

The second migration is conflict-first/non-destructive and refuses ambiguous/lossy data instead of guessing intent. At rollout time the affected live legacy tables contained 0 rows, so the backfill was a clean no-op.

## Live DB invariants verified

- all five new tables created;
- FKs reference `public.users`;
- one active Body Goal per user enforced;
- Maintain/Recomposition cannot store Target Weight/Goal Pace;
- RLS enabled on all new tables;
- authenticated CRUD grants present;
- optimized `(select auth.uid()) = user_id` policies present;
- no new RLS-init-plan advisor warning for the new tables;
- no invalid/orphan canonical rows;
- new canonical row counts currently 0 as expected.

## Next phase — repository/model cutover

Do **not** add permanent dual-write synchronization. Cut each owner deliberately:

```text
1. Body/current-weight repositories
   → body_weight_logs + user_body_goals

2. Wellness repository
   → user_wellness_targets

3. Nutrition persistence split
   → user_nutrition_profiles context
   → user_nutrition_targets numeric goals

4. Workout persistence split
   → user_workout_profiles capability/context
   → user_workout_targets goals/plan constraints

5. Onboarding + Settings
   → same canonical repository contracts

6. Stop writes to legacy mirrored columns

7. Remove legacy HTTP Target Weight 60kg fallback if adapter remains reachable

8. Re-run persistence acceptance + full Flutter/Dart CI
```

## PR #50 persistence semantics after cutover

- active eligible Target Weight → active `user_body_goals.target_weight_kg`;
- active Goal Pace → active Body Goal weekly pace;
- skipped/ineligible Target Weight stays dormant in onboarding draft and is not canonical intent;
- Maintain/Recomposition canonical Target Weight/pace are structurally null;
- current weight comes from `body_weight_logs`;
- Nutrition reads common Profile/Body owners instead of mirrored Nutrition copies;
- unified Workout training goals persist to `user_workout_targets`, Body goals to `user_body_goals`, with rank preserving primary/supporting order where applicable.

## Remaining Product/technical gates

```text
repository/model owner cutover                  NEXT
Onboarding + Settings owner parity              NEXT
legacy mirrored write shutdown                  after cutover
integrated persistence acceptance               after cutover
measurement picker/reference                    blocked on approved reference
Target Weight recommendation numeric policy     needs explicit product rule
legacy duplicate-column cleanup migration       only after verified cutover
final full workspace CI                         last
```

## Guardrails

- one canonical durable owner per concept;
- no permanent mirrored canonical values;
- App Mode visibility never deletes hidden owner data;
- Onboarding/Settings are entry points, not owners;
- no fake Goal mapping or BMI/delta semantic inference;
- do not edit applied migrations in place;
- no old-column drop before verified repository cutover;
- no Target Weight recommendation-formula change without approval;
- no UI redesign or invented picker in this persistence phase.
