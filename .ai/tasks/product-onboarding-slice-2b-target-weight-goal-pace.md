# Product Onboarding Slice 2B — Target Weight and Goal Pace

**Status:** In progress  
**Primary owner:** `apps/features/onboarding`  
**GitHub tracker:** #40  
**Canonical ownership tracker:** #44  
**Canonical implementation PR:** #50 `feat(onboarding): activate unified mode-aware Goal screen`  
**Canonical branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

PR #50 stays Draft/unmerged until the approved Supabase owner migration/cutover and remaining Product gates are complete.

---

## 0. Current truth

Validated checkpoints:

```text
Goal + eligibility baseline                     ✅
2B-B1 Target Weight state/domain semantics      ✅ CI #1079
2B-C Goal Pace ownership/default semantics      ✅ CI #1090
2B-D1 local acceptance + Review Goal source     ✅ CI #1095
Persistence transport audit                     ✅
Live tio-world Supabase ownership audit          ✅
#44 canonical owner contract                     ✅ APPROVED
Forward Supabase migration/backfill design       ⏳ NEXT
```

Latest validated source/test checkpoint:

```text
6c3dcb527bc92b3a6b46755d2d8c569682d090f4
Flutter CI #1095 / run 32497930346
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

The current persistence authority is the live **`tio-world` Supabase project**, not the legacy `tnyx-hub` onboarding HTTP contract.

---

## 1. Approved Goal + weight-follow-up contract

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

- Nutrition is single-select.
- Workout/Hybrid may use one compatible supporting goal.
- `Build muscle != Gain weight`.
- Never infer Goal intent from BMI or current/target numeric difference.
- Do not invent unsupported GoalIntent → legacy ProfileGoal mappings.

Local draft schema v4 stores Target Weight value + associated loss/gain direction. Temporary ineligible detours preserve dormant values; same direction restores; explicit opposite direction clears the incompatible scalar target.

Goal Pace owns weekly body-weight change only. Calories/BMR/TDEE were removed from the Goal Pace screen; slider/haptics/warnings/projection remain.

---

## 2. Approved canonical Supabase owner contract (#44)

This owner map is final for the next migration design.

### `users` — Account + Common User Profile

Keep `users`; do **not** create `user_profiles`.

Canonical common fields include:

```text
account/auth/status identity
name
username where applicable
gender
DOB
height
activity level
general health conditions
unit preferences
timezone/profile image/common profile metadata
```

The following must migrate away from `users` canonical ownership:

```text
current_weight_kg
target_weight_kg
goals / primary_goal mixed body/workout intent
```

### `user_devices` — Device owner

Retain as separate 1:N owner:

```text
users 1 ─── N user_devices
```

Own device identity/fingerprint, platform/OS, app build/version, push token, last device activity and device-specific runtime/capability metadata.

No Body/Nutrition/Workout/common Profile data belongs here.

### `body_weight_logs` — Weight history / current-weight source

Canonical owner for time-varying body weight.

Latest applicable log is the canonical current-weight source. Do not retain `current_weight_kg` as a second canonical value in `users` or Nutrition.

### `user_body_goals` — Body Goal plans

Common across Workout/Nutrition/Hybrid.

Owns:

```text
goal_type = lose | gain | maintain | recomposition
starting_weight
target_weight when applicable
weekly_weight_change when applicable
started_at
ended/completed timestamp
active/status
```

Target Weight + Goal Pace belong here, not in Nutrition Profile and not in `users`.

Implementation should enforce at most one active plan per user while retaining history.

### `user_wellness_targets` — Common Wellness

Owns:

```text
steps target
water target
sleep duration target
bedtime/wake time if retained by product
```

These are cross-mode Wellness values, not Nutrition-owned values.

### `user_nutrition_profiles` — Nutrition context only

Owns food/diet context:

```text
diet/preferred diet
allergies/restrictions
preferred/disliked foods
future nutrition-context fields
```

Must stop canonically owning mirrored Profile/Body/Wellness fields such as height, current/target weight, activity, weekly body pace, steps/water/sleep.

### `user_nutrition_targets` — Numeric Nutrition targets

Owns:

```text
calories
protein
carbohydrates
fat
fiber
recommended-vs-custom state/metadata
future approved nutrient/meal targets
```

BMR/TDEE are calculated context, not editable canonical goals.

### `user_workout_profiles` — Workout capability/context

Owns:

```text
location/environment
available equipment
experience level
focus areas
injuries / physical limitations
```

### `user_workout_targets` — Workout objective/plan constraints

Owns:

```text
workout goal
training days
preferred duration
split/training preference
special event/date when applicable
other approved training target constraints
```

### Workout Runtime Settings — separate owner

Rest timers, RPE/RIR runtime behavior, keep-awake, graph/display rules, music, PR notifications, Wear/device runtime behavior, etc. are not Workout Profile/Targets.

### `onboarding_drafts` — orchestration only

Keep `schema_version + payload` for flow/current-step/draft/resume/compatibility metadata.

It is not a canonical health/profile owner. Dormant/skipped values must never become canonical intent merely because they exist in the draft.

---

## 3. Live Supabase facts verified before approval

Live public owner-related tables include:

```text
users
user_devices
onboarding_drafts
user_nutrition_profiles
user_workout_profiles
```

Current live schema is mixed:

- `users` duplicates Body Goal/measurement fields;
- `user_nutrition_profiles` duplicates Profile/Body fields and mixes Wellness + Nutrition targets;
- `user_workout_profiles` mixes Profile + Workout Targets.

Live `user_nutrition_profiles.target_weight_kg` is already nullable numeric.

Aggregate duplicate audit at approval time found zero conflicts for overlapping height/current-weight/target-weight/activity values. This lowers current migration risk but does not justify keeping duplicate canonical writes.

---

## 4. Approved migration order

Do not patch current mixed tables field-by-field and do not drop old columns in the first migration.

```text
1. Canonical owner contract                         ✅
2. Design forward-only Supabase migration           NEXT
3. Define exact legacy → canonical backfill matrix
4. Review constraints, indexes and RLS
5. Create missing canonical tables
6. Backfill existing rows with explicit precedence
7. Validate counts/conflicts/null semantics
8. Cut Tio-world repositories/models to new owners
9. Make Onboarding + Settings use same repositories
10. Stop writes to old mirrored columns
11. Compatibility/dual-read only where intentional
12. Verify production/app behavior
13. Remove legacy duplicate columns in later cleanup
14. Re-run PR #50 integrated persistence acceptance
```

No blind bidirectional synchronization.

---

## 5. Backfill rules that must be designed next

Migration plan must explicitly resolve:

```text
users.current_weight_kg / nutrition current weight
→ body_weight_logs

users.target_weight_kg / nutrition target weight
→ user_body_goals.target_weight only with valid body-goal semantics

legacy goals / primary_goal
→ user_body_goals or user_workout_targets only when meaning is lossless

nutrition weekly_weight_change_kg
→ user_body_goals only with eligible explicit body-goal semantics

nutrition steps/water/sleep
→ user_wellness_targets

nutrition food context
→ user_nutrition_profiles

nutrition macro targets
→ user_nutrition_targets

workout location/equipment/experience/focus/limitations
→ user_workout_profiles

workout training days/duration/split/special event
→ user_workout_targets
```

Ambiguous legacy values must not be guessed or fabricated.

---

## 6. PR #50 persistence implications

Do not make the current mixed `user_nutrition_profiles` table the final Target Weight owner just to fix nullable transport.

After `user_body_goals` exists and repositories cut over:

- active eligible Target Weight persists to active Body Goal;
- skipped/ineligible Target Weight remains dormant only in onboarding draft and must not overwrite canonical active intent incorrectly;
- Goal Pace persists with the Body Goal plan, not Nutrition;
- Nutrition calculation reads Body/Profile owners rather than mirroring those inputs into Nutrition tables.

The legacy HTTP `60.0` fallback remains a defect in the fallback adapter and should eventually be removed, but it is not the current schema authority or the next migration step.

---

## 7. App Mode invariant

```text
Workout mode   → common + Body/Wellness + Workout owners eligible
Nutrition mode → common + Body/Wellness + Nutrition owners eligible
Hybrid mode    → common + Body/Wellness + Nutrition + Workout owners eligible
```

Changing mode changes visibility, not durable data ownership. Hidden Nutrition/Workout data is not deleted merely because a mode hides it.

---

## 8. Remaining gates before PR #50 Ready

```text
forward Supabase migration/backfill design       NEXT
migration + RLS/constraints/indexes              after review
repository/model cutover                         after schema
Onboarding + Settings owner parity               after cutover
canonical unified Goal persistence               with new owners
measurement picker/reference                     blocked on reference
Target Weight recommendation numeric policy      needs explicit rule
final integrated acceptance + full CI            last
```

Guardrails:

- one canonical owner per durable concept;
- no permanent mirrored canonical values;
- Onboarding and Settings are entry points, not owners;
- `users` remains common Profile owner;
- `user_devices` stays separate device-only owner;
- current weight belongs to weight history;
- Body Goal is common across modes;
- no fake Goal mappings;
- no destructive first migration;
- no unrelated UI redesign;
- no recommendation formula changes without approval;
- do not invent the missing measurement picker.

## Immediate next task

**Design the forward-only Supabase migration and exact backfill matrix for the approved #44 owner contract. Do not mutate the live schema until that migration plan is reviewed.**
