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
Body Cutover A canonical write foundation        ✅ CI #1135
Body Cutover B Profile/Settings parity            ⏳ NEXT
Wellness/Nutrition/Workout repository cutover    ⏳ AFTER BODY B
```

Latest validated production/source/test checkpoint:

```text
9031dc5e51a71b1bcef905bd93088f36396d3c01
Flutter CI #1135 / run 32505095642
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Later task/docs-only commits do not replace this source/test checkpoint unless a newer full CI run validates source changes.

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

## Canonical Supabase owner contract — live

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

The migration is additive and conflict-first. Applied migration files must never be edited in place. Legacy mixed columns remain physically present until repository cutover proves they are no longer read/written.

## Body Cutover A — validated

Canonical Body persistence is now established under `apps/features/progress`:

```text
Onboarding draft
  → BodySetupMapper
  → BodySetupRepository
  → SupabaseBodySetupRepository
  → body_weight_logs + user_body_goals
```

Validated behavior:

- onboarding completion writes current-weight state to `body_weight_logs`;
- explicit Body Goal state writes/reconciles `user_body_goals`;
- same goal type updates the active plan; changed goal type supersedes the previous active plan;
- training-only/no-Body selection does not invent Body direction;
- Maintain/Recomposition cannot persist Target Weight/Goal Pace;
- Target Weight is consumed only when its stored direction matches the explicit active loss/gain direction;
- invalid Body payloads are rejected before Body DB mutation;
- full Flutter/Dart CI #1135 passed.

This is a canonical write foundation, not the final single-owner cutover, because Profile/Settings and compatibility repositories still contain legacy Body reads/writes.

## Next phase — Body Cutover B

Do this before Wellness/Nutrition/Workout cutover:

```text
1. add canonical Body read API
   → latest current weight from body_weight_logs
   → active Body Goal from user_body_goals

2. make Profile/Profile Settings display canonical Body state

3. make Profile Settings current-weight mutation write body_weight_logs

4. expose active Body Goal/Target Weight from user_body_goals where needed

5. refresh/invalidate canonical Body state after Settings mutation

6. prove stale/default read regressions are absent

7. stop Profile onboarding Body mirror writes

8. stop Nutrition Body mirror writes

9. stop Profile Settings users.current_weight_kg write

10. full Flutter/Dart CI
```

No permanent dual-write synchronization.

## After Body Cutover B

```text
Wellness
→ user_wellness_targets

Nutrition
→ user_nutrition_profiles context only
→ user_nutrition_targets numeric targets

Workout
→ user_workout_profiles context/capability
→ user_workout_targets plan/goal constraints

Onboarding + Settings
→ same canonical repositories

Then
→ integrated persistence acceptance
→ legacy duplicate-column cleanup only after proof
```

## Remaining Product/technical gates

```text
Body Cutover B Profile/Settings parity          NEXT
Wellness/Nutrition/Workout cutover              after Body B
legacy mirrored write shutdown                  during owner cutover
integrated persistence acceptance               after owner cutover
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
