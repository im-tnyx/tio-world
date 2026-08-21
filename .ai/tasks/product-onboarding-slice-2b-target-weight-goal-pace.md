# Product Onboarding Slice 2B — Target Weight and Goal Pace

**Status:** In progress  
**Primary owner:** `apps/features/onboarding`  
**GitHub tracker:** #40  
**Canonical ownership tracker:** #44  
**Canonical implementation PR:** #50 `feat(onboarding): activate unified mode-aware Goal screen`  
**Canonical branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`  
**Execution decision:** keep PR #50 Draft/unmerged until canonical Supabase owner boundaries are approved and the remaining Product/technical gates are satisfied.

---

## 0. Read first — current truth

This file is the durable continuation handoff. Do not rely on chat history.

### PR topology

- PR #50 is the only active `tio-world` implementation PR.
- PR #51 is closed/unmerged as superseded; its useful tests were consolidated into #50.
- PR #52 is closed/unmerged validation-only.

### Validated checkpoints

```text
Goal + eligibility baseline                     ✅
2B-B1 Target Weight state/domain semantics      ✅ CI #1079
2B-C Goal Pace ownership/default semantics      ✅ CI #1090
2B-D1 local acceptance + Review Goal source     ✅ CI #1095
2B-D2 persistence transport audit               ✅ audit complete
Live Supabase owner-table audit                 ✅ audit complete
Canonical owner/schema decision                 ⏳ NEXT GATE (#44)
```

Latest validated D1 source/test checkpoint:

```text
6c3dcb527bc92b3a6b46755d2d8c569682d090f4
Flutter CI #1095 / run 32497930346
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

PR #50 is **not Ready**.

---

## 1. Approved Goal contract

`GoalIntentSelection` is onboarding semantic authority.

Nutrition, single-select:

```text
Lose weight
Gain weight
Maintain weight
Recomposition
```

Workout / Hybrid, max two compatible:

```text
Lose weight
Build muscle
Get stronger
Improve endurance
Stay fit
Recomposition
```

Rules:

- `Build muscle != Gain weight`.
- never infer Goal intent from BMI or current/target numeric delta;
- do not invent unsupported GoalIntent → legacy ProfileGoal mappings.

Weight follow-up eligibility:

```text
Nutrition Lose/Gain                  → Target Weight + Goal Pace
Nutrition Maintain/Recomposition     → skip both
Workout/Hybrid Lose primary/support  → Target Weight + Goal Pace
training-only goals                  → skip both
```

Dynamic Profile/Targets plans use this authority for Next/Back/resume/progress/validation/reconciliation.

---

## 2. 2B-B1 Target Weight state semantics — implemented

Local draft schema v4 stores:

```text
targetWeightKg: double?
targetWeightDirection: loss | gain | null
```

Contract:

- eligible → ineligible preserves Target Weight dormant in onboarding draft;
- ineligible → same direction restores exact value;
- explicit loss ↔ gain clears incompatible old scalar Target Weight;
- legacy target direction associates only from explicit restored Goal;
- recommendation does not overwrite a preserved value;
- no numeric/BMI semantic inference.

Validated CI #1079.

---

## 3. 2B-C Goal Pace semantics — implemented

Goal Pace owns weekly body-weight change only.

Removed from Goal Pace screen:

- BMR/TDEE calculation;
- calorie deficit/surplus math;
- target-kcal UI/info sheet.

Preserved:

- slider;
- haptics;
- pace tags/warnings;
- target-date projection/graph.

Compatibility draft default `0.5` is not user intent when Goal Pace is skipped. Ineligible consumption is neutral `0.0`.

Review hides dormant Target Weight and skipped Goal Pace from explicit Goal direction.

Validated CI #1090.

---

## 4. 2B-D1 local acceptance — implemented

`ReviewScreen` now renders ordered `draft.goalSelection` instead of stale legacy `profile.goals`.

Table-driven acceptance covers:

- Nutrition Lose/Gain/Maintain/Recomposition;
- Workout Lose primary/supporting + all training-only goals;
- Hybrid setup-now and Later with the same matrix;
- restored Target Weight/Goal Pace reconciliation;
- dynamic progress totals;
- Targets Next/Back.

Validated CI #1095.

---

## 5. Persistence architecture correction — `tio-world` Supabase is current authority

Do **not** treat the legacy `tnyx-hub` onboarding HTTP validator as the current schema authority for this work.

The current `tio-world` app repository provider uses:

```text
Supabase configured
→ SupabaseTargetsSetupRepository

otherwise
→ legacy RemoteTargetsSetupRepository
```

The live Supabase project named `tio-world` is active and is the persistence environment that must drive the owner/schema decision.

The legacy HTTP path may be retained as a compatibility/future adapter, but it must not dictate canonical Tio-world ownership.

---

## 6. Live `tio-world` Supabase audit — confirmed mixed ownership

Live public tables observed:

```text
users
onboarding_drafts
user_nutrition_profiles
user_workout_profiles
user_devices
```

### `onboarding_drafts`

Columns:

```text
user_id
schema_version
payload jsonb
created_at
updated_at
```

This is appropriate as onboarding orchestration/resume storage. It is **not** a canonical Profile/Body/Nutrition/Workout owner.

### `users` currently mixes

Account/identity:

```text
id
username
email
mobile
avatar/profile image
timezone
plan/status/account flags
```

Shared profile:

```text
name
gender
date_of_birth + legacy dob
height_cm
activity_level
health_conditions
other_health_condition
unit_preferences
```

Body/goal fields that should not remain casually mixed/mirrored:

```text
current_weight_kg
target_weight_kg
goals
primary_goal
```

### `user_nutrition_profiles` currently mixes

Duplicated Profile/Body:

```text
height_cm
current_weight_kg
target_weight_kg
activity_level
```

Body Goal:

```text
weekly_weight_change_kg
```

Common Wellness:

```text
steps_target
water_target_ml
sleep_target_minutes
bed_time
wake_up_time
```

Nutrition Profile:

```text
preferred_diet
allergies
disliked_foods
```

Other/mixed:

```text
medical_conditions
macro_targets
```

### `user_workout_profiles` currently mixes

Workout Profile/capability:

```text
workout_location
available_equipment
experience_level
focus_areas
health_concerns
```

Workout Targets/plan constraints:

```text
training_days
workout_duration_mins
split_program
special_event_goal
```

### Live Target Weight fact

`public.user_nutrition_profiles.target_weight_kg` is already:

```text
numeric NULLABLE
```

and the live audit found no Target Weight database constraint.

Therefore **no Target Weight nullability migration is currently needed**.

### Duplicate conflict sample

Aggregate live check at audit time:

```text
users total                         2
users with nutrition profile data  1
height conflicts                    0
current-weight conflicts            0
target-weight conflicts             0
activity conflicts                  0
```

This lowers current backfill risk but does not justify duplicate canonical ownership.

---

## 7. Canonical owner decision — NEXT GATE (#44)

Before more persistence implementation in PR #50, approve one durable owner per concept.

Recommended logical owner map for review:

### User / Profile

Shared identity + baseline only:

```text
name
gender
DOB
height
activity level
general health conditions
unit preferences
```

Account/auth fields may stay on `users`; whether shared profile stays on `users` or moves to a dedicated `user_profiles` table must be decided once, then used by both Onboarding and Settings.

### Body / Body Goal

Common across all modes:

```text
current weight
weight history
active body-goal type: lose/gain/maintain/recomposition
active-goal start/starting weight
target weight
weekly weight-change target
```

Preferred clean design to review:

```text
body weight history table
+
active body-goal/plan table
```

Do not make Nutrition the owner of body-weight intent.

### Wellness

Common targets:

```text
steps
water
sleep duration
bedtime/wake time if retained
```

These need a common Wellness owner, not Nutrition ownership.

### Nutrition Profile

Food context only:

```text
diet type/style
allergies/restrictions
preferred/disliked foods
```

### Nutrition Targets

Numeric nutrition goals only:

```text
calories
protein
carbohydrates
fat
fiber
recommended-vs-custom metadata
```

BMR/TDEE are calculated context, not editable canonical goals.

### Workout Profile

Training capability/context:

```text
location/environment
equipment
experience
focus areas
injuries/limitations
```

### Workout Targets

Training objective/plan constraints:

```text
workout goal(s)
training days
duration
split/preference
special event
```

### Onboarding Draft

```text
flow/order/current step/draft/resume only
```

It never becomes a canonical owner.

---

## 8. Correct schema migration order

Do not patch duplicate tables one field at a time.

Correct order:

```text
1. #44 full field trace + canonical owner approval
2. inspect live RLS/constraints/indexes for affected tables
3. define forward-only Supabase schema additions
4. define deterministic backfill precedence for duplicated fields
5. create new owner tables/columns + RLS + constraints
6. backfill existing rows
7. update Tio-world domain repositories/models to new owners
8. dual-read/compatibility period if required
9. verify Onboarding + Settings against same owner repositories
10. stop writes to old duplicate columns
11. only after verification, deprecate/drop old duplicate columns in a later migration
12. rerun PR #50 integrated persistence acceptance
```

No destructive drop in the first migration.

---

## 9. Target Weight transport after owner decision

The earlier D2 audit remains useful, but implementation order changes.

Current Supabase repository conditionally emits:

```dart
if (data.targetWeightKg != null)
  'target_weight_kg': data.targetWeightKg
```

If the final Body owner still uses a nullable active Target Weight field, inactive state must be able to explicitly clear stale canonical state instead of omission.

But **do not implement this into the current mixed Nutrition table as the final architecture before #44 owner approval**.

The legacy HTTP `60.0` fallback remains a defect in that adapter and must eventually be removed, but it is no longer the next blocking migration step.

---

## 10. Remaining PR #50 gates

```text
#44 canonical owner/schema contract          NEXT
Supabase forward migration/backfill          AFTER APPROVAL
repository cutover + persistence acceptance  AFTER SCHEMA
canonical Goal persistence                   WITH OWNER CONTRACT
measurement picker/reference                 BLOCKED ON REFERENCE
Target Weight numeric recommendation policy  NEEDS PRODUCT RULE
final full integrated CI                     LAST
```

PR #50 stays Draft/unmerged.

---

## 11. Guardrails

- one canonical owner per durable concept;
- do not synchronize duplicate canonical columns as a permanent design;
- Onboarding and Settings are entry points, not owners;
- App Mode visibility must not delete hidden domain data;
- no fake GoalIntent → legacy ProfileGoal mappings;
- no destructive Supabase migration before backfill/cutover verification;
- no unrelated UI redesign;
- no recommendation formula change without approval;
- do not invent the missing measurement picker.

---

## 12. Immediate next task

**Audit/approve #44 canonical Supabase owner model.**

Specifically resolve:

1. whether shared User Profile remains on `users` or moves to `user_profiles`;
2. current-weight/history model;
3. active Body Goal table/model;
4. Wellness target table/model;
5. Nutrition Profile vs Nutrition Target split;
6. Workout Profile vs Workout Target split;
7. exact backfill source precedence for every duplicated field;
8. RLS and Settings/Onboarding repository ownership.

Only after that approval should schema migrations or PR #50 persistence rewiring start.
