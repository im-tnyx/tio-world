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
Body Cutover B audit                             ✅
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

Canonical Body persistence is established under `apps/features/progress`:

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

This is a canonical write foundation, not the final single-owner cutover, because Profile/Settings and the mixed legacy Targets repository still contain Body mirrors.

## Body Cutover B audit decision

The current `TargetsSetupRepository` mixes Body + Wellness + Nutrition and its read contract still requires legacy `weekly_weight_change_kg`/Wellness columns. Removing only its Body columns during Body B would create a half-migrated repository.

Therefore Body B is intentionally narrowed to **canonical Body read/command + Profile/Settings parity + Profile mirror shutdown**. Nutrition-side Body mirrors are removed with the Wellness/Nutrition repository split immediately afterward.

## Next phase — Body Cutover B

```text
B1. canonical Body read/command contract
    → latest current weight from body_weight_logs
    → active Body Goal from user_body_goals
    → post-onboarding weight edits create new history rows

B2. Profile owner cleanup
    → ProfileSetupData/common Profile no longer owns goals/current/target weight
    → SupabaseProfileSetupRepository stops users Body mirror reads/writes
    → onboarding ProfileSetupMapper maps common Profile only

B3. Profile Settings cross-owner composition
    → Profile fields stay Profile-owned
    → current weight saves through Body repository
    → screen reads canonical Body state
    → refresh Profile + Body providers

B4. verify Profile-side mirror shutdown
    → no active writes to users.current_weight_kg
    → no active writes to users.target_weight_kg
    → no active writes to users.goals / users.primary_goal

B5. full Flutter/Dart CI
```

Canonical Body data wins over stale legacy values. Do not fabricate `70 kg` as canonical truth. If a true pre-cutover compatibility read is needed, it must be explicit, persisted-value-only, canonical-first, and temporary.

Profile Settings weight edits must create a new `body_weight_logs` history row with post-onboarding provenance; they must not overwrite the onboarding setup snapshot.

## Immediately after Body Cutover B

The next split removes the remaining Nutrition-side Body mirrors together with the structurally mixed Wellness/Nutrition contract:

```text
Wellness
→ user_wellness_targets

Nutrition context
→ user_nutrition_profiles

Nutrition numeric targets
→ user_nutrition_targets

Then remove from Nutrition persistence:
→ current weight mirror
→ Target Weight mirror
→ Goal Pace mirror
→ height/activity mirrors
```

Nutrition calculations should read true Profile/Body owners rather than persisting duplicate inputs.

After that:

```text
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
Wellness/Nutrition split + Nutrition mirrors    immediately after Body B
Workout owner cutover                           after Nutrition
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
