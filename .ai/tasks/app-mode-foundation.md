# App Mode Foundation — O1 Durable Account Preference

**Status:** Ready — O1A is the next Product Onboarding implementation slice  
**Primary owners:** `apps/shared`, `apps/app`, onboarding, Settings, `user_app_preferences`  
**Tracker:** #11  
**Product Onboarding tracker:** #40  
**Canonical sequence:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**PR:** #50 remains Draft/unmerged

## Outcome

Make App Mode a durable authenticated-account preference that survives restart, cleared local storage, fresh install and second-device login.

Canonical owner is already LIVE:

```text
user_app_preferences
├─ user_id PK/FK → public.users(id) ON DELETE CASCADE
├─ app_mode       → workout | nutrition | hybrid | null
├─ active_tabs    → ordered stable destination IDs | null
├─ created_at
└─ updated_at
```

Applied P1 migrations:

```text
20260821180908_split_account_profile_app_preferences
20260821181005_harden_profile_app_preference_grants
```

RLS is enabled. Authenticated users have SELECT/INSERT/UPDATE on their own row; anon has no table privileges.

## Current verified runtime gap

```text
AppModeController
→ AppModePreference
→ SharedPreferencesAppModePreference
→ local key `app_mode`
```

`CompleteOnboardingUseCase` still publishes confirmed mode through `AppModePreference.write(selectedMode)` after owner persistence/finalizer and before completion status. The concrete app adapter is currently local SharedPreferences.

`AppModeBootstrap`/`main.dart` load the local controller before routing. Authenticated bootstrap does not yet restore `user_app_preferences`.

Therefore a completed account can lose guided mode after local data is cleared or on another device.

## Canonical semantics

```text
app_mode
→ semantic product experience
→ workout | nutrition | hybrid
→ derives default guided destinations

active_tabs
→ effective ordered navigation preference
→ initially derived from app_mode
→ may later reflect separately approved customization
```

Current guided defaults:

```text
workout   → [home, workout, progress]
nutrition → [home, nutrition, progress]
hybrid    → [home, workout, nutrition, progress]
```

Never silently invent Hybrid.

## O1 execution protocol

Only one O1 sub-slice is active at a time. Each sub-slice must land focused tests before the next begins. Full workspace CI is required at O1F before O2 starts.

### O1A — domain/repository contract — NEXT

Goal: introduce the backend-neutral account preference model without changing runtime authority yet.

- [ ] define `AppPreferencesState` (or equivalent) with nullable `appMode` and ordered `activeTabs`;
- [ ] define backend-neutral `AppPreferencesRepository` read/upsert contract;
- [ ] keep existing `AppModePreference` as local cache/staging boundary during migration rather than making Supabase concerns leak into shared domain;
- [ ] validate mode IDs through existing `AppMode` contract;
- [ ] validate stable destination IDs;
- [ ] reject duplicate/unsupported `active_tabs`;
- [ ] preserve array order;
- [ ] represent missing canonical preference explicitly;
- [ ] focused pure-Dart tests.

Exit: domain contract is compile-safe and tested; no onboarding completion/bootstrap behavior changed yet.

### O1B — Supabase adapter

Goal: make `user_app_preferences` usable through the new repository.

- [ ] Supabase repository reads the authenticated user's row;
- [ ] upsert `app_mode` + `active_tabs` as one logical preference write;
- [ ] `app_mode` present + `active_tabs` null remains a valid legacy/recovery state;
- [ ] missing row returns explicit no-preference state;
- [ ] RLS/auth failures are surfaced, never converted into local success;
- [ ] no row is fabricated from `onboarding_drafts.payload.selected_mode`;
- [ ] focused repository tests.

Exit: canonical remote read/write parity is proven independently of app composition.

### O1C — onboarding completion cutover

Goal: publish canonical App Mode before onboarding completion becomes durable.

Required order:

```text
validate onboarding
→ persist canonical owner data
→ optional finalizer
→ persist user_app_preferences(app_mode + derived active_tabs)
→ update local AppMode cache
→ mark remote onboarding completed
→ mark local onboarding status completed
→ best-effort clear draft
```

- [ ] failed canonical preference write keeps onboarding incomplete/retryable;
- [ ] draft-selected mode is not canonical before successful completion;
- [ ] retry is idempotent;
- [ ] existing completion tests extended for preference-write failure/success.

Exit: onboarding completion no longer depends on local-only App Mode persistence.

### O1D — authenticated bootstrap/restore

Goal: remote canonical preference becomes truth for signed-in users.

Precedence:

```text
authenticated account
→ read user_app_preferences
→ valid active_tabs: restore exact order
→ app_mode + null active_tabs: derive guided defaults
→ no canonical preference on completed legacy account: controlled recovery
→ refresh local SharedPreferences cache
```

- [ ] valid remote state wins over stale local cache;
- [ ] cleared local cache recovers from remote;
- [ ] second device recovers from remote;
- [ ] no remote preference never silently becomes Hybrid;
- [ ] pre-auth local staging cannot overwrite another authenticated account.

Exit: routing/shell gets canonical mode after authenticated restore.

### O1E — Settings mode-change parity

Goal: Settings writes the same canonical owner.

- [ ] Settings App Mode change persists remote `app_mode` + derived `active_tabs`;
- [ ] local cache/controller updates with canonical success semantics;
- [ ] failed remote write does not display/save a false mode change;
- [ ] mode changes hide/show eligible surfaces only; they never delete Body/Nutrition/Workout owner data;
- [ ] focused Settings/controller tests.

Exit: Onboarding and Settings share one canonical App Mode owner.

### O1F — integrated acceptance / CI

- [ ] onboarding first-device completion;
- [ ] fresh install / cleared local storage;
- [ ] second-device login;
- [ ] stale local vs valid remote precedence;
- [ ] app_mode-only legacy row derives default tabs;
- [ ] completed legacy account with no row uses controlled recovery;
- [ ] invalid/duplicate tab data is rejected/recovered safely;
- [ ] Settings mode change persists remotely;
- [ ] hidden domain data survives mode change;
- [ ] Flutter analyze;
- [ ] Dart analyze;
- [ ] Flutter tests;
- [ ] Dart tests;
- [ ] record exact commit/CI in #11, #40, #44 and `product-onboarding-canonical-execution.md`.

Only after O1F is green may O2 common Profile owner/section begin.

## Source map for O1

Primary current paths to inspect/change:

```text
apps/shared/lib/src/app_mode/*
apps/app/lib/app/app_mode/app_mode_controller.dart
apps/app/lib/app/app_mode/shared_preferences_app_mode_preference.dart
apps/app/lib/app/app_mode/app_mode_bootstrap.dart
apps/app/lib/main.dart
apps/app/lib/app/router.dart
apps/features/onboarding/lib/src/domain/usecases/complete_onboarding_use_case.dart
app composition/providers for Supabase repositories
Settings App Mode entry/controller path
relevant app/shared/onboarding/settings tests
```

Do not mechanically replace `AppModePreference` everywhere with a Supabase adapter; separate canonical repository from local cache/staging responsibilities.

## Parallel account lane

Account contact verification (#8) is required product work but does not technically block O1. It may run independently when explicitly prioritized.

## Out of scope

- custom 3–6 tab editor;
- activating future/reserved destinations;
- Profile/Body/Nutrition/Workout owner cutovers beyond App Mode wiring;
- account email/mobile verification;
- UI redesign;
- deleting hidden domain data on mode changes.

## Guardrails

- `user_app_preferences` is canonical App Mode/navigation owner;
- `users` remains account root;
- `user_profiles` owns common Profile only;
- SharedPreferences becomes cache/pre-auth staging, not authenticated account authority;
- no permanent local/remote competing authorities;
- no silent semantic mode inference;
- onboarding draft mode is temporary orchestration state only;
- future backend must consume the same backend-neutral preference contract/table.

## Handoff

**Start O1A domain/repository contract.**  
Then O1B → O1C → O1D → O1E → O1F.  
After O1F validation, update trackers and start O2 common Profile owner/section.