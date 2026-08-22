# Product Onboarding O11 — Canonical Schema Cleanup

**Status:** PLANNED / BLOCKED  
**Issue:** #54  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50  
**Execution gate:** start only after O10 integrated Product Onboarding acceptance is frozen

## Objective

Finish the additive canonical-owner migration by removing transitional legacy/mirrored onboarding columns only after every production read/write path has cut over to its approved canonical owner.

O11 is intentionally destructive and therefore runs last. O2–O10 may refine this task and collect evidence, but they must not perform legacy column drops as side effects.

## Non-negotiable outcome

One durable owner per concept:

```text
users                      → account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + active navigation
user_devices               → devices
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep
user_nutrition_profiles    → diet/allergy/food context
user_nutrition_targets     → calories/macros/fiber targets
user_workout_profiles      → workout context/capability
user_workout_targets       → workout goals/schedule/plan constraints
onboarding_drafts          → draft/resume orchestration only
```

No permanent mirrored Profile, Body, Wellness, Nutrition-target or Workout-target authority may remain after O11.

## Current live-schema audit baseline

Audit performed against live Supabase `tio-world` and working branch `agent/onboarding-slice-2-step-1-body-goal-ui`.

Exact duplicate public tables were not found. Duplicate-looking data is primarily transitional ownership overlap created by additive canonical migrations.

Observed semantic overlaps:

```text
users ↔ user_profiles
  name
  gender
  date_of_birth
  height_cm
  activity_level
  health_conditions
  other_health_condition
  unit_preferences

users ↔ user_nutrition_profiles
  height_cm
  current_weight_kg
  target_weight_kg
  activity_level

user_nutrition_profiles ↔ user_wellness_targets
  steps_target
  water_target_ml
  sleep_target_minutes
  bed_time
  wake_up_time

user_nutrition_profiles ↔ user_body_goals
  target_weight_kg
  weekly_weight_change_kg

user_workout_profiles ↔ user_workout_targets
  training_days
  split_program
```

`users.date_of_birth` and `users.dob` are an explicit same-table semantic duplicate and must not both survive O11.

`users.avatar_url` vs `users.profile_image` remains unresolved and requires a code-usage/persistence audit before one canonical avatar field is chosen.

## Execution slices

```text
O11A Profile legacy cleanup
O11B Body legacy cleanup
O11C Wellness + Nutrition legacy cleanup
O11D Workout legacy cleanup
O11E Final schema/grants/contract validation
```

Each destructive slice requires its own pre-drop evidence and forward-only migration. Do not combine all drops into an unreviewed single migration.

---

# O11A — Profile legacy cleanup

## Canonical owner

`public.user_profiles`

Final Profile shape:

```text
user_id
name
gender
date_of_birth
height_cm
activity_level
health_conditions
other_health_condition
unit_preferences
created_at
updated_at
```

## Candidate removals from `public.users`

```text
name
 gender
 date_of_birth
 dob
 height_cm
 activity_level
 health_conditions
 other_health_condition
 unit_preferences
```

The whitespace above is non-semantic; migration SQL must use exact identifiers.

## Preconditions

- O2 integrated canonical Profile read/write/resume acceptance complete;
- onboarding reads/writes `user_profiles` only for common Profile data;
- Profile Settings reads/writes the same canonical owner;
- authenticated bootstrap/profile hydration no longer relies on legacy `users` Profile fields;
- fresh install, second-device and resumed draft coverage prove canonical Profile hydration;
- repo-wide production search shows no remaining legacy Profile reader/writer;
- live legacy/canonical values are conflict-checked before drop.

## DOB rule

Final canonical field is only:

```text
user_profiles.date_of_birth
```

`users.date_of_birth` and `users.dob` are both removed once Profile cutover proof is complete.

---

# O11B — Body legacy cleanup

## Canonical owners

```text
body_weight_logs → current/history weight
user_body_goals  → Body Goal + Target Weight + Goal Pace
```

## Candidate removals

From `public.users`:

```text
current_weight_kg
target_weight_kg
goals
primary_goal
```

From `public.user_nutrition_profiles` where still legacy/mirrored:

```text
current_weight_kg
target_weight_kg
weekly_weight_change_kg
```

## Preconditions

- O3 Body Goal/Profile parity acceptance complete;
- all Current Weight reads resolve through `body_weight_logs` semantics;
- all Body Goal / Target Weight / Goal Pace writes resolve through `user_body_goals`;
- no legacy `users.goals` / `users.primary_goal` Body meaning is consumed by production code;
- historical current-weight semantics remain valid after snapshot-column removal;
- conflict checks block cleanup if canonical and legacy values disagree.

---

# O11C — Wellness + Nutrition legacy cleanup

## Canonical owners

```text
user_wellness_targets   → steps/water/sleep
user_nutrition_profiles → diet/allergy/food/medical context
user_nutrition_targets  → calories/macros/fiber targets
```

## Candidate removals from `public.user_nutrition_profiles`

```text
height_cm
current_weight_kg
target_weight_kg
weekly_weight_change_kg
bed_time
wake_up_time
activity_level
steps_target
water_target_ml
sleep_target_minutes
macro_targets
```

Do not mechanically drop every candidate. Before each removal, confirm that the field is not still part of the final nutrition-context contract.

Expected final Nutrition Profile scope is context such as:

```text
preferred_diet
allergies
disliked_foods
medical_conditions
```

Numeric nutrition goals belong to `user_nutrition_targets`.

## Preconditions

- O4 Wellness acceptance complete;
- O5 Nutrition Profile/Targets acceptance complete;
- typed target reads/writes no longer depend on `macro_targets`;
- wellness hydration no longer consumes Nutrition Profile target fields;
- onboarding review/resume preserves Nutrition and Wellness answers through canonical owners;
- Settings or plan-building surfaces are audited for all candidates.

---

# O11D — Workout legacy cleanup

## Canonical owners

```text
user_workout_profiles → workout context/capability
user_workout_targets  → workout goals/schedule/plan constraints
```

## Candidate removals from `public.user_workout_profiles`

```text
training_days
workout_duration_mins
split_program
special_event_goal
```

Expected retained Profile/context concepts include fields such as:

```text
experience_level
workout_location
available_equipment
focus_areas
health_concerns
```

## Preconditions

- O6 Workout acceptance complete;
- Workout target/schedule reads and writes use `user_workout_targets`;
- no target/planning code still treats `user_workout_profiles` as authority;
- review/resume/finalization coverage proves canonical restore.

---

# Avatar cleanup decision

Before O11 final cleanup, audit:

```text
users.avatar_url
users.profile_image
```

Determine:
- every production read path;
- every upload/write path;
- Storage/object-key assumptions;
- account/profile UI expectations;
- migration/backfill requirement.

Choose exactly one canonical account avatar column. Migrate data losslessly, cut readers/writers, then remove the other field.

Do not choose a canonical field only from naming preference.

---

# O11E — Final schema/grants/contract validation

## Final `public.users` intent

Keep account/domain-root concepts only. Expected fields include:

```text
id
username
email
email_verified_at
mobile
mobile_verified_at
<single canonical avatar field>
timezone
plan
is_active
is_onboarded
account_setup_completed_at
referral_code
referred_by_id
created_at
updated_at
deleted_at
last_active_at
```

Fields may remain only when they have an explicit account/domain-root contract. Do not use this expected list as permission to remove unrelated established account functionality without auditing code and data first.

## Hard blockers before first DROP

- [ ] O2 canonical Profile acceptance complete
- [ ] O3 Body acceptance complete
- [ ] O4 Wellness acceptance complete
- [ ] O5 Nutrition acceptance complete
- [ ] O6 Workout acceptance complete
- [ ] O7 Health Connections complete where stored-field dependencies exist
- [ ] O8 Review/resume/edit-back acceptance complete
- [ ] O9 finalization complete
- [ ] O10 full integrated Product Onboarding acceptance green
- [ ] Settings/account surfaces audited
- [ ] repo-wide production search completed for every candidate field
- [ ] generated Supabase types audited for legacy usages
- [ ] live canonical-vs-legacy conflict checks pass
- [ ] nullability/data-loss audit passes
- [ ] forward-only migration reviewed

## Migration discipline

- never edit applied migrations;
- create a new migration with the current Supabase CLI workflow when O11 becomes active;
- destructive migrations are conflict-first;
- no semantic guessing or fabricated defaults;
- no permanent dual-write synchronization;
- do not drop a legacy field merely because its canonical table exists;
- canonical repository cutover plus acceptance evidence is required first;
- apply one cleanup slice at a time when practical;
- regenerate TypeScript/database types after DDL;
- run database advisors after DDL;
- rerun full app CI and focused persistence/resume tests.

## Final acceptance

- [ ] one durable owner per Product Onboarding concept
- [ ] no `users.date_of_birth` / `users.dob` duplication
- [ ] no common Profile mirror remains in `users`
- [ ] Current Weight authority exists only through `body_weight_logs`
- [ ] Body Goal/Target Weight/Goal Pace authority exists only through `user_body_goals`
- [ ] Wellness targets are not mirrored in Nutrition Profile
- [ ] typed Nutrition targets are not competing with legacy `macro_targets`
- [ ] Workout planning fields are not mirrored across Profile and Targets
- [ ] exactly one account avatar field remains
- [ ] no runtime reference to dropped columns
- [ ] live FK/RLS/constraint semantics remain valid
- [ ] fresh signup + onboarding pass
- [ ] draft resume/edit-back pass
- [ ] Settings read/write pass
- [ ] authenticated bootstrap/fresh install pass
- [ ] second-device restore pass
- [ ] final Supabase security/performance advisors reviewed
- [ ] exact migration + CI evidence recorded on #54 and parent trackers

## Out of scope until activated

While O2–O10 are active, O11 may only:

- refine this ownership/drop matrix;
- record code-usage findings;
- record schema/grant audit findings;
- add non-destructive tests that protect canonical ownership expectations.

It must not:

- drop or rename live legacy columns;
- edit already-applied migration SQL;
- introduce permanent sync triggers between legacy and canonical owners;
- broaden Product Onboarding UI scope.

## Handoff

O11 remains blocked until O10. During each earlier owner slice, record newly eliminated legacy dependencies here so final cleanup becomes evidence-driven rather than a second architecture redesign.