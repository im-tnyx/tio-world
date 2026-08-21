# Account / Profile / App Preferences Canonical Split

**Status:** P1 schema foundation validated live  
**Canonical owner tracker:** #44  
**Product Onboarding sequence:** `product-onboarding-canonical-execution.md`  
**App Mode tracker:** #11  
**Account/contact persistence tracker:** #8  
**Related onboarding:** #40 / PR #50

## Canonical ownership

```text
users
→ stable account/domain root
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
→ 1:1 app-experience preference owner
→ app_mode
→ ordered active_tabs
```

`users` is not renamed. Canonical domain tables continue to use `public.users(id)` as the future-backend-safe application root.

## P1 — VALIDATED LIVE ✅

Live project: `tio-world` (`oykupyiitspujzpwwvuj`)

Applied migrations:

```text
20260821180908_split_account_profile_app_preferences
20260821181005_harden_profile_app_preference_grants
```

Repo migrations:

```text
supabase/migrations/20260821180908_split_account_profile_app_preferences.sql
supabase/migrations/20260821181005_harden_profile_app_preference_grants.sql
```

P1 result:

```text
public.user_profiles        ✅
public.user_app_preferences ✅
public.users.email_verified_at ✅
```

Live affected rows were zero, so current backfill was a no-op. The migration still contains deterministic/conflict-first behavior for non-empty environments.

Both new tables use `public.users(id)` FKs, RLS, optimized `(select auth.uid()) = user_id` policies, and authenticated SELECT/INSERT/UPDATE only. Anon has no table privileges. A second migration removed automatically inherited broad grants including TRUNCATE.

Normal client roles cannot arbitrarily promote `email_verified_at` / `mobile_verified_at`; changing a contact invalidates only that contact's verification timestamp. Trusted Auth/backend reconciliation is required to mark verification.

No new P1 advisor warning was introduced. Existing unrelated username SECURITY DEFINER, leaked-password protection and historical RLS init-plan warnings remain separate work.

## Sequencing correction — two independent lanes

P1 originally serialized account contact verification before App Mode solely as a work-order convenience. Audit confirmed there is **no Product Onboarding dependency requiring #8 to finish before #11**.

### Product Onboarding lane

Authoritative task: `.ai/tasks/product-onboarding-canonical-execution.md`

```text
O1 durable App Mode / active_tabs       NEXT (#11)
→ O2 common Profile owner/section
→ O3 Body Goal/Profile parity
→ O4 Wellness
→ O5 Nutrition
→ O6 Workout
→ O7 Health Connections
→ O8 Review/resume
→ O9 finalization/Congratulations
→ O10 full acceptance
```

### Account / Settings lane

```text
A1 real email/mobile verification       #8
```

A1 is required before final account/settings acceptance, but it is not a blocker for O1–O3 Product Onboarding persistence.

Only one Product Onboarding slice is active at a time. The account lane may be scheduled separately when explicitly prioritized.

## O1 / App Mode contract

`user_app_preferences` is already live. Runtime still uses device-local SharedPreferences as confirmed App Mode authority, so O1 must:

- add backend-neutral App Preferences repository/domain contract;
- read/write `user_app_preferences` through Supabase;
- persist onboarding confirmed `app_mode` + derived ordered `active_tabs` before completion publishes;
- persist Settings App Mode changes to the same row;
- restore canonical remote mode/tabs at authenticated bootstrap;
- let valid remote state win over stale local cache;
- keep SharedPreferences as cache/pre-auth staging only;
- never silently invent Hybrid;
- never delete hidden domain data on mode change;
- validate fresh-install / cleared-local / second-device behavior;
- record full CI before O2.

Tracker: #11.

## O2 / common Profile contract

After O1 validation, Product Onboarding cuts common Profile persistence to `user_profiles`:

```text
name
gender
date_of_birth
unit_preferences
height_cm
activity_level
health_conditions
other_health_condition
```

Current Weight, Body Goal, Target Weight and Goal Pace are not Profile fields.

Onboarding and Settings must consume the same Profile owner. Legacy `users` Profile columns remain temporarily for compatibility and are removed only after repository cutover proof.

## A1 / account contact verification contract

Tracker: #8.

```text
Phone-first
→ verified mobile
→ later add/change email
→ real Supabase Auth email verification
→ trusted users.email + email_verified_at reconciliation

Email-first
→ verified email
→ later add/change mobile
→ real Supabase Auth phone verification
→ trusted users.mobile + mobile_verified_at reconciliation
```

Requirements:
- remove false `isEmailVerified = true` assumption;
- distinguish missing vs unverified contact;
- no client-authoritative verification booleans/timestamps;
- failed/expired verification stays unverified;
- verifying one contact preserves the other;
- bootstrap/sign-in can reconcile stale provider-neutral account state;
- no unrelated visual redesign.

## Guardrails

- no destructive rename of `users`;
- no applied migration edits;
- no permanent dual-write synchronization;
- no client-authoritative verified timestamps;
- no Profile/App Mode/Body concepts re-coupled into `users` for transport convenience;
- no legacy column drop before canonical repository cutover + acceptance;
- future backend consumes these same Postgres owners/contracts.

## Handoff

**Product Onboarding next:** O1 durable App Mode / active-tabs (#11).  
**Parallel account work:** A1 contact verification (#8).  
**After O1:** O2 common Profile owner/section.  
**Read `product-onboarding-canonical-execution.md` before any further Product Onboarding implementation.**