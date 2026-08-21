# Account / Profile / App Preferences Canonical Split

**Status:** Ready — next canonical foundation after Body Cutover B1 validation  
**Canonical owner tracker:** #44  
**App Mode tracker:** #11  
**Related onboarding tracker:** #40 / PR #50

## Outcome

Split the current mixed `public.users` responsibilities into explicit durable owners without renaming or destructively replacing the existing `users` table.

Approved canonical ownership:

```text
users
→ account/domain root
→ auth-linked account identity/status
→ username/contact/avatar/timezone/plan/account lifecycle

user_profiles
→ 1:1 common personal/profile baseline
→ name
→ gender
→ date_of_birth
→ height_cm
→ activity_level
→ general health conditions
→ unit_preferences

user_app_preferences
→ 1:1 account-level app experience preferences
→ app_mode
→ active_tabs
→ future app-level preferences only when separately approved

user_devices
→ 1:N device/runtime identity
```

Body, Wellness, Nutrition and Workout remain separate canonical owners:

```text
body_weight_logs
user_body_goals
user_wellness_targets
user_nutrition_profiles
user_nutrition_targets
user_workout_profiles
user_workout_targets
onboarding_drafts
```

## Superseded decision

The earlier #44 decision that `users` should permanently own common Profile data is superseded.

Do **not** rename `users` to `user_profiles`.

`users` remains the stable domain/account root so existing foreign keys such as `body_weight_logs.user_id -> public.users(id)` remain valid and future backend adapters can use the same root identity.

## Current verified state

- live `tio-world` Supabase has no `user_profiles` table;
- live `tio-world` Supabase has no `user_app_preferences` table;
- live `users` still contains common Profile and legacy Body mirror columns;
- live DB has no canonical `app_mode` or `active_tabs` column anywhere in `public`;
- confirmed App Mode currently persists through device-local `SharedPreferencesAppModePreference`;
- `onboarding_drafts.payload.selected_mode` is draft/resume state only, not final account preference ownership;
- canonical Body tables are already live and Body Cutover B1 is validated.

Body B1 validated checkpoint:

```text
e3822b81d2c8793191cfb8a208257fd2bc8bc7dd
Flutter CI #1153 / run 32508150413
Analyze Flutter packages  ✅
Analyze Dart packages     ✅
Test Flutter packages     ✅
Test Dart packages        ✅
```

## Execution protocol

Only one implementation slice is active at a time.

Each slice must:

1. update this task before source/schema changes if scope changes;
2. preserve previous canonical owners and data;
3. run focused tests plus the applicable full CI/security checks;
4. update #44 and the related focused issue after validation;
5. record exact validated commit/CI evidence before the next slice begins.

No later slice should be started merely because source code has landed; validation must pass first.

## Slice P1 — additive schema foundation

**Goal:** create backend-neutral 1:1 canonical tables without changing app runtime ownership yet.

Planned schema:

```text
user_profiles
├─ user_id PK/FK → public.users(id) ON DELETE CASCADE
├─ name
├─ gender
├─ date_of_birth
├─ height_cm
├─ activity_level
├─ health_conditions
├─ other_health_condition
├─ unit_preferences
├─ created_at
└─ updated_at

user_app_preferences
├─ user_id PK/FK → public.users(id) ON DELETE CASCADE
├─ app_mode
├─ active_tabs
├─ created_at
└─ updated_at
```

P1 requirements:

- [ ] re-audit live source columns/value shapes before DDL;
- [ ] create a new forward-only migration; never edit applied migrations;
- [ ] RLS enabled on both tables;
- [ ] authenticated ownership policies use `(select auth.uid()) = user_id` with UPDATE `USING` + `WITH CHECK`;
- [ ] explicit Data API grants as required;
- [ ] validate `app_mode` against `workout|nutrition|hybrid`;
- [ ] `active_tabs` stores ordered stable destination IDs and remains nullable for legacy compatibility;
- [ ] no duplicate `dob` concept in `user_profiles`; canonical DOB column is `date_of_birth`;
- [ ] deterministic backfill from real legacy `users` values only;
- [ ] conflict/invalid values block or remain explicitly unresolved; never fabricate;
- [ ] no legacy `users` column drop;
- [ ] Supabase security/performance advisors + validation SQL after migration.

P1 does **not** cut over Flutter repositories yet.

## Slice P2 — durable App Mode / navigation preference cutover

**Tracker:** #11

**Goal:** make `user_app_preferences` the canonical account-level App Mode/navigation owner while SharedPreferences becomes cache/staging only.

Canonical semantics:

```text
app_mode
→ semantic product experience: workout | nutrition | hybrid
→ derives default guided destinations

active_tabs
→ effective ordered navigation preference
→ initially derived from app_mode
→ later may reflect separately approved customization
```

P2 requirements:

- [ ] add backend-neutral App Preferences repository/domain contract;
- [ ] Supabase adapter reads/writes `user_app_preferences`;
- [ ] onboarding completion persists confirmed `app_mode` + derived `active_tabs` durably before publishing completion;
- [ ] Settings App Mode change persists the same canonical row;
- [ ] authenticated bootstrap restores remote preference before final guided shell configuration;
- [ ] valid remote canonical state wins over stale local cache;
- [ ] SharedPreferences remains fast-path/cache and pre-auth staging, not account authority;
- [ ] completed legacy user with no remote mode must not silently become Hybrid;
- [ ] cross-device/fresh-install/cleared-local-data tests;
- [ ] no custom-tab UI expansion in this slice.

## Slice P3 — common Profile repository cutover

**Goal:** make `user_profiles` the sole durable owner of common Profile data.

P3 requirements:

- [ ] create/read/update common Profile through `user_profiles`;
- [ ] narrow Profile repository models to Profile-owned fields;
- [ ] onboarding common Profile persistence writes `user_profiles`;
- [ ] Profile Settings common Profile writes `user_profiles`;
- [ ] account-only fields continue through `users`/account repository;
- [ ] remove fabricated Profile defaults when canonical values are absent;
- [ ] stop active writes to legacy `users` Profile mirrors after canonical parity is proven;
- [ ] canonical `user_profiles` rows win over stale legacy `users` values;
- [ ] no legacy column drop yet.

Canonical common Profile fields are not Body fields. Current Weight, Target Weight, Goal Pace and Body Goal never move into `user_profiles`.

## Slice P4 — resume Body Cutover B2/B3 against new Profile owner

After P3 validation, continue the existing Body task:

```text
Body read/current weight → body_weight_logs
Body Goal/Target Weight/Goal Pace → user_body_goals
common Profile → user_profiles
account identity → users
```

P4 requirements:

- [ ] remove Body fields from Profile-owned models/mappers;
- [ ] Profile Settings composes common Profile + Body owners at app boundary;
- [ ] current-weight edit appends a `body_weight_logs` row with `profile_settings` provenance;
- [ ] stop legacy `users.current_weight_kg`, `users.target_weight_kg`, `users.goals`, `users.primary_goal` writes;
- [ ] prove no fabricated `70 kg` fallback;
- [ ] full Body/Profile persistence acceptance.

## Slice P5 — Wellness / Nutrition canonical split

```text
Wellness → user_wellness_targets
Nutrition context → user_nutrition_profiles
Nutrition numeric targets → user_nutrition_targets
```

P5 also removes transitional Nutrition mirrors of Profile/Body values only after calculators/repositories read the true owners.

## Slice P6 — Workout Profile / Targets cutover

```text
Workout Profile → user_workout_profiles
Workout Targets → user_workout_targets
```

No Body Goal mirroring into Workout just for convenience.

## Slice P7 — integrated acceptance and legacy cleanup

Only after P1–P6 are validated:

- [ ] Onboarding and Settings consume the same canonical owner contracts;
- [ ] fresh install / second device restores account Profile + App Mode correctly;
- [ ] canonical Body/Wellness/Nutrition/Workout state survives resume and Settings edits;
- [ ] no active legacy mirrored write paths remain;
- [ ] run integrated persistence/data-integrity acceptance;
- [ ] author later forward migration to remove obsolete duplicate columns only when evidence proves safe.

## Final target model

```text
users
→ account/domain root

user_profiles
→ common Profile

user_app_preferences
→ App Mode + active navigation preferences

user_devices
→ devices

body_weight_logs
user_body_goals
user_wellness_targets
user_nutrition_profiles
user_nutrition_targets
user_workout_profiles
user_workout_targets

onboarding_drafts
→ draft/resume orchestration only
```

## Future backend rule

A future protected backend must use these same canonical Postgres owners and backend-neutral repository contracts. Do not create a parallel backend schema or re-couple Profile/App Mode/Body data into `users` for transport convenience.

## Guardrails

- no destructive rename of `users`;
- no applied migration edits;
- no permanent dual-write synchronization;
- no silent semantic inference or fabricated defaults;
- no UI redesign as part of ownership migration;
- no custom tab expansion until its own product slice;
- no legacy column drop before repository cutover + validation;
- PR #50 remains Draft/unmerged until its onboarding persistence gates are complete.

## Handoff

**Current validated slice:** Body B1 / CI #1153.  
**Next implementation slice:** P1 additive `user_profiles` + `user_app_preferences` schema audit/migration.  
**Do not jump directly to P2/P3/P4 before P1 is validated.**
