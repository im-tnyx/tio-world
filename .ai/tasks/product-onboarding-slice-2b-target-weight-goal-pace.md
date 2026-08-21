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
Weight-follow-up eligibility                    ✅
2B-B1 Target Weight draft semantics             ✅ CI #1079
2B-C Goal Pace ownership/UI cleanup             ✅ CI #1090
2B-D1 integrated local acceptance + Review      ✅ CI #1095
Canonical Supabase base owner schema            ✅ LIVE
Conflict-safe legacy backfill                   ✅ LIVE
Body Cutover A canonical write foundation       ✅ CI #1135
Body Cutover B1 canonical read/history contract ✅ CI #1153
Account/Profile/App Preferences split approved  ✅
P1 user_profiles + user_app_preferences         ⏳ NEXT
P2 App Mode durable account preference          ⏳ AFTER P1
P3 common Profile repository cutover            ⏳ AFTER P2
P4 Body B2/B3 Profile/Settings composition      ⏳ AFTER P3
```

Latest validated source/test checkpoint:

```text
e3822b81d2c8793191cfb8a208257fd2bc8bc7dd
Flutter CI #1153 / run 32508150413
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Approved Goal contract

`GoalIntentSelection` remains onboarding semantic authority.

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

Goal Pace owns weekly body-weight change only. BMR/TDEE/calorie math is not Goal Pace ownership.

## Canonical owner architecture — revised authority

```text
users
→ account/domain root only

user_profiles
→ common Profile

user_app_preferences
→ App Mode + ordered active navigation preferences

user_devices
→ devices

body_weight_logs
→ weight history/current weight

user_body_goals
→ Body Goal + Target Weight + Goal Pace + lifecycle

user_wellness_targets
→ steps/water/sleep

user_nutrition_profiles
→ diet/allergy/food context

user_nutrition_targets
→ calories/macros/fiber + recommended/custom state

user_workout_profiles
→ Workout context/capability

user_workout_targets
→ Workout goals/plan constraints

onboarding_drafts
→ draft/resume only
```

The earlier `users = account + common Profile` decision is superseded. Do not rename `users`; it remains the stable root for canonical owner FKs and future backend adapters.

## Existing live migrations

```text
20260821161923_create_canonical_owner_tables
20260821162207_backfill_canonical_owner_data
```

Applied migrations must never be edited in place. The new `user_profiles` + `user_app_preferences` decision requires a new forward migration.

## Body Cutover evidence

### Body A — validated ✅

```text
9031dc5e51a71b1bcef905bd93088f36396d3c01
Flutter CI #1135 / run 32505095642 ✅
```

Onboarding Body writes now target `body_weight_logs` + `user_body_goals`.

### Body B1 — validated ✅

```text
e3822b81d2c8793191cfb8a208257fd2bc8bc7dd
Flutter CI #1153 / run 32508150413 ✅
```

B1 provides backend-neutral canonical Body reads/history commands, latest-weight reads, active Body Goal reads, no fabricated `70 kg`, and separate onboarding-retry vs post-onboarding history semantics.

## Canonical next sequence

The authoritative sequencing task is:

`.ai/tasks/account-profile-app-preferences-canonical-split.md`

```text
P1. additive schema
    → create user_profiles
    → create user_app_preferences
    → RLS/grants/constraints/backfill/advisors

P2. durable App Mode/navigation
    → user_app_preferences canonical owner
    → onboarding + Settings remote write
    → authenticated bootstrap remote restore
    → SharedPreferences cache/staging only

P3. common Profile cutover
    → onboarding/Profile Settings common fields → user_profiles
    → account fields stay on users
    → stop legacy users Profile writes after parity

P4. resume Body B2/B3
    → remove Body ownership from Profile models/mappers
    → Profile Settings current weight → BodyRepository
    → stop users Body mirror writes

P5. Wellness/Nutrition split
P6. Workout Profile/Targets split
P7. integrated persistence acceptance
later legacy-column cleanup migration
```

Only one implementation slice should be active at a time. Do not jump from P1 directly to P4.

## App Mode persistence gate

Live audit confirmed App Mode is currently local-only through `SharedPreferencesAppModePreference`; there is no canonical DB `app_mode`/`active_tabs` owner.

Final owner is `user_app_preferences`, tracked by Issue #11.

`onboarding_drafts.payload.selected_mode` is draft/resume state, not final account preference authority.

## Common Profile gate

Common Profile moves to `user_profiles`:

- name;
- gender;
- single canonical `date_of_birth`;
- height;
- activity level;
- general health conditions;
- unit preferences.

Body fields never move into `user_profiles`.

## Remaining Product/technical gates

```text
P1 Profile/App Preferences schema                NEXT
P2 durable App Mode                              after P1
P3 common Profile repository cutover             after P2
P4 Body/Profile Settings parity + mirror stop     after P3
P5 Wellness/Nutrition split                      after P4
P6 Workout owner cutover                         after P5
integrated persistence acceptance                after owner cutovers
measurement picker/reference                     blocked on approved reference
Target Weight recommendation numeric policy      needs explicit product rule
legacy duplicate-column cleanup migration        only after verified cutover
final full workspace CI                          last
```

## Guardrails

- one canonical durable owner per concept;
- no permanent mirrored canonical values;
- `users` remains account/root; no destructive rename;
- `user_profiles` owns common Profile only;
- `user_app_preferences` owns App Mode/navigation only;
- App Mode visibility never deletes hidden owner data;
- Onboarding/Settings are entry points, not owners;
- no fake Goal mapping or BMI/delta semantic inference;
- do not edit applied migrations in place;
- no old-column drop before verified repository cutover;
- no Target Weight recommendation-formula change without approval;
- no UI redesign or invented picker in this persistence phase.
