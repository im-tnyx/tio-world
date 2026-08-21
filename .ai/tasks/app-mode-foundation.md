# App Mode Foundation

**Status:** O1 READY — next Product Onboarding implementation slice  
**Primary owners:** `apps/shared`, `apps/app`, onboarding, Settings, `user_app_preferences`  
**Tracker:** #11  
**Onboarding sequence:** `.ai/tasks/product-onboarding-canonical-execution.md`

## Outcome

Give each authenticated user one durable phone mode (`workout`, `nutrition`, or `hybrid`) that drives guided navigation and survives restart, fresh install, cleared local storage, and cross-device login.

## Current runtime

Historical local-first foundation:

```text
AppModeController
→ SharedPreferencesAppModePreference
→ local key app_mode
```

That remains current runtime authority today but is not the final durability contract.

`onboarding_drafts.payload.selected_mode` is draft/resume state only and must never become final account preference authority.

## Canonical owner — LIVE

P1 is complete:

```text
20260821180908_split_account_profile_app_preferences
20260821181005_harden_profile_app_preference_grants
```

```text
user_app_preferences
├─ user_id PK/FK → public.users(id) ON DELETE CASCADE
├─ app_mode
├─ active_tabs
├─ created_at
└─ updated_at
```

`app_mode` allowed values:

```text
workout
nutrition
hybrid
```

`active_tabs` is an ordered stable-destination array and remains nullable for controlled legacy recovery.

RLS is enabled. Authenticated users have SELECT/INSERT/UPDATE on their own row; anon has no table privileges.

## Sequencing correction

P1A account contact verification (#8) is an independent Account/Settings lane. It is important but does **not** block this O1 Product Onboarding slice.

```text
P1 schema ✅
→ O1 durable App Mode / active_tabs   NEXT
→ O2 common Profile owner/section
```

## Canonical semantics

### `app_mode`

Semantic product experience. It determines default guided eligibility/navigation.

### `active_tabs`

Effective ordered navigation preference.

Current guided defaults:

```text
workout   → [home, workout, progress]
nutrition → [home, nutrition, progress]
hybrid    → [home, workout, nutrition, progress]
```

Mode and tabs are related but not competing authorities:

```text
app_mode
→ semantic intent
→ derives defaults

active_tabs
→ effective ordered navigation
→ initially derived from app_mode
→ may later reflect separately approved customization
```

Custom tab editing is out of scope for O1.

## Existing validated local foundation

- [x] `apps/shared` owns `AppMode`, stable destinations and guided mappings;
- [x] app shell derives guided tabs from mode;
- [x] onboarding selects draft mode;
- [x] Settings can change local confirmed mode;
- [x] local mode survives device-local restart;
- [x] routing handles missing/invalid local mode without inventing semantic mode;
- [x] focused controller/navigation tests exist;
- [x] `user_app_preferences` canonical schema exists live.

## O1 implementation checklist

### Domain / repository

- [ ] add backend-neutral App Preferences state/repository contract;
- [ ] validate `app_mode` and ordered `active_tabs` at domain boundary;
- [ ] reject unsupported/duplicate tab IDs;
- [ ] preserve tab order;
- [ ] define explicit no-preference/legacy state without silently choosing Hybrid.

### Supabase adapter

- [ ] read own `user_app_preferences` row;
- [ ] upsert `app_mode` + `active_tabs` as one logical preference operation;
- [ ] no user preference row fabricated from onboarding draft state before successful completion;
- [ ] RLS failures remain visible failures; no local success masking remote failure.

### Onboarding completion

- [ ] confirmed onboarding completion persists `app_mode` + derived `active_tabs` to canonical remote owner;
- [ ] remote preference success occurs before final completion is published;
- [ ] failed remote write does not falsely complete onboarding;
- [ ] draft-selected mode remains draft until success.

### Settings

- [ ] mode changes persist to the same canonical row;
- [ ] mode change never deletes hidden Body/Nutrition/Workout data;
- [ ] local cache updates only with correct canonical success semantics.

### Bootstrap / restore

- [ ] authenticated bootstrap reads remote preference before final guided shell configuration;
- [ ] valid remote state wins over stale local cache;
- [ ] app_mode present + active_tabs null → derive default tabs;
- [ ] both absent for completed legacy account → controlled compatibility/recovery, never silent Hybrid;
- [ ] refresh local SharedPreferences cache after valid canonical read.

### Validation

- [ ] first-device onboarding completion test;
- [ ] local cache cleared + same account login test;
- [ ] second-device login test;
- [ ] stale local vs valid remote precedence test;
- [ ] remote write failure does not publish completion test;
- [ ] Settings mode-change persistence test;
- [ ] invalid/duplicate tab state test;
- [ ] full Flutter analyze;
- [ ] Dart analyze;
- [ ] Flutter tests;
- [ ] Dart tests;
- [ ] exact source/CI checkpoint recorded in #11/#40/#44 and onboarding master task.

## Source-of-truth precedence after O1

```text
authenticated account
→ user_app_preferences
→ valid active_tabs: restore exact navigation
→ app_mode only: derive guided defaults
→ no remote preference on completed legacy account: controlled recovery
→ refresh local cache
```

Before authentication, local mode may remain pre-auth staging only; it must not mutate another authenticated account's canonical preference.

## Out of scope

- custom 3–6 tab editor;
- reserved future destination activation;
- watch synchronization policy;
- UI redesign;
- Profile/Body/Nutrition/Workout repository cutovers beyond required App Mode wiring;
- account contact verification (#8).

## Guardrails

- `user_app_preferences`, not `users`, owns App Mode/navigation;
- `user_profiles` owns common Profile only;
- no permanent local/remote competing authorities;
- no silent mode inference;
- mode visibility never deletes hidden domain data;
- future backend consumes the same preference table/contract.

## Handoff

**Start here for next Product Onboarding work.**  
After O1 is fully validated, update trackers and move to O2 common Profile owner/section.  
Do not start O2 before O1 validation evidence is recorded.