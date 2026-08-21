# Account / Profile / App Preferences Canonical Split

**Status:** Ready — next canonical foundation after Body Cutover B1 validation  
**Canonical owner tracker:** #44  
**App Mode tracker:** #11  
**Account/contact persistence tracker:** #8  
**Related onboarding tracker:** #40 / PR #50

## Outcome

Split the current mixed `public.users` responsibilities into explicit durable owners without renaming or destructively replacing the existing `users` table.

Approved canonical ownership:

```text
users
→ account/domain root
→ auth-linked account identity/status
→ username/contact/avatar/timezone/plan/account lifecycle
→ email + email_verified_at
→ mobile + mobile_verified_at

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
- live `users` has `email`, `mobile`, and `mobile_verified_at`, but **no `email_verified_at`**;
- Supabase Auth exposes trusted `email_confirmed_at` and `phone_confirmed_at` timestamps;
- there is currently no trigger synchronizing Auth confirmation timestamps into `public.users`;
- Account Settings currently defaults `isEmailVerified = true` when a real value is not supplied;
- the app router passes phone verification from Profile state but does not pass a real email-verification state;
- the Account Settings email surface is display/verify-oriented and does not yet provide the complete durable add/change-email verification flow required for phone-first accounts;
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

## Account contact verification contract

Email and mobile are account-root contact identities. Their verification state belongs with the account root, not `user_profiles` and not `user_app_preferences`.

Canonical application fields:

```text
users.email
users.email_verified_at
users.mobile
users.mobile_verified_at
```

Current Supabase Auth verification evidence:

```text
auth.users.email_confirmed_at
→ trusted evidence that the current auth email is verified

auth.users.phone_confirmed_at
→ trusted evidence that the current auth phone is verified
```

Rules:

- `email_verified_at` / `mobile_verified_at` must never be trusted from a client-supplied boolean or arbitrary timestamp;
- the application/domain timestamps are provider-neutral account state reconciled from trusted auth/provider evidence;
- changing email clears/replaces email verification until the new address is confirmed;
- changing mobile clears/replaces mobile verification until the new number is confirmed;
- a phone-first account may have `email = null` and later add + verify email from Account Settings;
- an email-first account may have `mobile = null` and later add + verify mobile from Account Settings;
- verification of one contact does not imply verification of the other;
- UI must not show Verified merely because the field exists;
- future backend adapters must preserve the same provider-neutral account contract even if Supabase Auth is later replaced.

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

**Goal:** create backend-neutral 1:1 canonical tables and the missing provider-neutral email verification field without changing Flutter runtime ownership yet.

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

public.users
└─ ADD email_verified_at timestamptz NULL
```

P1 requirements:

- [ ] re-audit live source columns/value shapes before DDL;
- [ ] create a new forward-only migration; never edit applied migrations;
- [ ] add `users.email_verified_at timestamptz null` additively; preserve existing `mobile_verified_at`;
- [ ] create `user_profiles` + `user_app_preferences`;
- [ ] RLS enabled on both new tables;
- [ ] authenticated ownership policies use `(select auth.uid()) = user_id` with UPDATE `USING` + `WITH CHECK`;
- [ ] explicit Data API grants as required;
- [ ] validate `app_mode` against `workout|nutrition|hybrid`;
- [ ] `active_tabs` stores ordered stable destination IDs and remains nullable for legacy compatibility;
- [ ] no duplicate `dob` concept in `user_profiles`; canonical DOB column is `date_of_birth`;
- [ ] deterministic backfill from real legacy `users` values only;
- [ ] if trusted Auth confirmation timestamps are backfilled, copy only exact current identity matches; do not infer verification;
- [ ] conflict/invalid values block or remain explicitly unresolved; never fabricate;
- [ ] no legacy `users` column drop;
- [ ] Supabase security/performance advisors + validation SQL after migration.

P1 does **not** cut over Flutter repositories yet and does not make client code a trusted writer of verification timestamps.

## Slice P1A — Account contact identity + verification cutover

**Tracker:** #8

**Goal:** make email/mobile add-change-verify behavior truthful and symmetric for phone-first and email-first accounts.

Required flow:

```text
Phone-first signup
→ auth phone verified
→ users.mobile + mobile_verified_at reconciled
→ users.email may be null
→ Account Settings: Add email
→ Supabase Auth email verification
→ after confirmed auth state
→ users.email + email_verified_at reconciled

Email-first signup
→ auth email verified
→ users.email + email_verified_at reconciled
→ users.mobile may be null
→ Account Settings: Add mobile
→ Supabase Auth phone verification
→ after confirmed auth state
→ users.mobile + mobile_verified_at reconciled
```

P1A requirements:

- [ ] add backend-neutral account contact/verification model or repository contract at the account owner boundary;
- [ ] Account Settings reads actual email/mobile verification state; remove the default `isEmailVerified = true` assumption;
- [ ] email can be absent for a phone-first account without being fabricated;
- [ ] mobile can be absent for an email-first account without being fabricated;
- [ ] implement real add/change email through Supabase Auth rather than a local fake OTP success path;
- [ ] implement/retain real add/change phone verification through trusted auth flow;
- [ ] after verification, reconcile `public.users.email/mobile` and verification timestamps from current trusted auth identity;
- [ ] if email/mobile changes, previous verification is invalidated until the new contact is confirmed;
- [ ] do not expose a normal authenticated table update path that allows arbitrary promotion from unverified → verified;
- [ ] choose a safe trusted reconciliation mechanism (for example a verified-auth-backed RPC/server path or equivalent) rather than accepting a client timestamp;
- [ ] Account Settings must show Verify/Add actions based on actual state, not defaults;
- [ ] fresh-login/bootstrap reconciliation tests for email-first and phone-first users;
- [ ] add-email-after-phone-signup regression test;
- [ ] add-phone-after-email-signup regression test;
- [ ] failed/expired verification never marks the application contact verified;
- [ ] full relevant Flutter/Dart CI.

P1A is persistence/auth behavior work, not permission for an unrelated Account Settings visual redesign.

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

Only after P1, P1A, and P2–P6 are validated:

- [ ] Onboarding and Settings consume the same canonical owner contracts;
- [ ] fresh install / second device restores account contacts + verification state, Profile + App Mode correctly;
- [ ] phone-first account can later add/verify email without losing the verified phone;
- [ ] email-first account can later add/verify mobile without losing the verified email;
- [ ] canonical Body/Wellness/Nutrition/Workout state survives resume and Settings edits;
- [ ] no active legacy mirrored write paths remain;
- [ ] run integrated persistence/data-integrity acceptance;
- [ ] author later forward migration to remove obsolete duplicate columns only when evidence proves safe.

## Final target model

```text
users
→ account/domain root
→ email/mobile + provider-neutral verified timestamps

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

For contact verification, future auth providers may supply different verification claims, but Tio-world's provider-neutral application contract remains `email_verified_at` / `mobile_verified_at` on the account root.

## Guardrails

- no destructive rename of `users`;
- no applied migration edits;
- no permanent dual-write synchronization;
- no client-authoritative verification timestamp;
- no silent semantic inference or fabricated defaults;
- no UI redesign as part of ownership migration;
- no custom tab expansion until its own product slice;
- no legacy column drop before repository cutover + validation;
- PR #50 remains Draft/unmerged until its onboarding persistence gates are complete.

## Handoff

**Current validated slice:** Body B1 / CI #1153.  
**Next implementation slice:** P1 additive `user_profiles` + `user_app_preferences` + `users.email_verified_at` schema audit/migration.  
**After P1 validation:** P1A account contact verification, then P2 App Mode.  
**Do not jump directly to P1A/P2/P3/P4 before P1 is validated.**