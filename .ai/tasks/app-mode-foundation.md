# App Mode Foundation — O1 Durable Account Preference

**Status:** In progress — O1A + O1B + O1C validated; O1D authenticated bootstrap/restore is NEXT  
**Primary owners:** `apps/shared`, `apps/app`, onboarding, Settings, `user_app_preferences`  
**Tracker:** #11  
**Product Onboarding tracker:** #40  
**Canonical sequence:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**PR:** #50 remains Draft/unmerged

## Outcome

Make App Mode a durable authenticated-account preference that survives restart, cleared local storage, fresh install and second-device login.

Canonical owner is live:

```text
user_app_preferences
├─ user_id PK/FK → public.users(id) ON DELETE CASCADE
├─ app_mode       → workout | nutrition | hybrid | null
├─ active_tabs    → ordered stable destination IDs | null
├─ created_at
└─ updated_at
```

Applied schema foundation:

```text
20260821180908_split_account_profile_app_preferences
20260821181005_harden_profile_app_preference_grants
```

RLS is enabled. Authenticated users have SELECT/INSERT/UPDATE on their own row; anon has no table privileges.

## Current runtime gap

Onboarding completion now writes canonical App Mode/navigation before completion, but authenticated bootstrap still does not restore `user_app_preferences` and Settings still writes through the local controller path.

```text
O1C completion
→ canonical user_app_preferences ✅
→ local AppMode cache ✅

returning login/bootstrap
→ still local-first ❌

Settings mode change
→ still local-only ❌
```

## Canonical semantics

```text
app_mode
→ semantic product experience
→ workout | nutrition | hybrid

active_tabs
→ effective ordered navigation
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

## Validated checkpoints

### O1A — backend-neutral domain/repository contract ✅

```text
3889e7f0aae597d98908735c8f1b7fea6a6aebf0
Flutter CI #1183 / run 32547109579
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Implemented:
- `AppPreferencesState` with explicit missing-vs-present state;
- nullable read-side `appMode` / `activeTabs` for recovery;
- validated `AppPreferencesUpdate`;
- `AppPreferencesUpdate.guided(AppMode)`;
- backend-neutral `AppPreferencesRepository.read/upsert`;
- stable `AppDestination.storageValue` + parser;
- duplicate/empty rejection, order preservation, defensive copies.

### O1B — Supabase adapter ✅

```text
641e6eb55dfcbfa43ad1e7e95898c21c0faeb7be
Flutter CI #1187 / run 32547641191
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Implemented in `apps/app`:
- `SupabaseAppPreferencesRepository` implements shared `AppPreferencesRepository`;
- `SupabaseAppPreferencesTableGateway` targets only `user_app_preferences`;
- authenticated-user requirement;
- missing row → explicit missing state;
- app-mode-only row + null `active_tabs` supported for legacy recovery;
- strict parsing of canonical `app_mode` / `active_tabs`;
- unsupported mode/tab IDs and duplicate/empty tab arrays rejected;
- ordered `active_tabs` preserved;
- upsert sends `user_id`, `app_mode`, `active_tabs` as one logical preference payload;
- query/RLS/auth/gateway failures surface rather than becoming local success;
- no onboarding-draft inference;
- focused repository tests.

### O1C — onboarding completion cutover ✅

```text
74e45c9186aed8a6505ca8eef9cd5333de366308
Flutter CI #1199 / run 32549215504
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Implemented:
- `CompleteOnboardingUseCase` accepts an explicit backend-neutral `AppPreferencesRepository` dependency;
- app composition exposes the Supabase-backed `appPreferencesRepositoryProvider` and injects it explicitly into onboarding completion;
- unrelated `OnboardingCompletionRepository` and `AppPreferencesRepository` remain separate contracts—no runtime-type fallback/coupling;
- successful completion order is owner data → optional finalizer → canonical App Preferences → local App Mode cache → remote completion → local completion → best-effort draft clear;
- canonical write uses `AppPreferencesUpdate.guided(selectedMode)`;
- canonical preference failure prevents local mode/completion publication and keeps retry possible;
- backend completion failure still prevents local completed cache;
- completed retry only short-circuits when local selected mode matches and canonical preference is present/usable; a missing canonical row is repaired;
- bootstrap and Settings behavior intentionally unchanged;
- focused tests lock success/failure/order + missing-canonical repair + fully canonical idempotent retry;
- final router diff for production composition is only the canonical repository read + explicit use-case injection.

## O1 execution order

```text
O1A domain/repository contract          ✅ #1183
→ O1B Supabase adapter                  ✅ #1187
→ O1C onboarding completion cutover     ✅ #1199
→ O1D authenticated bootstrap/restore   NEXT
→ O1E Settings mode-change parity
→ O1F integrated acceptance/full CI
```

Only one O1 sub-slice is active at a time. Do not start O2 common Profile until O1F is validated.

## O1D — Authenticated bootstrap/restore — NEXT

Goal: make canonical remote App Mode/navigation truth available before final signed-in shell/navigation resolution.

Precedence:

```text
authenticated account
→ read user_app_preferences
→ valid active_tabs: restore exact order
→ app_mode + null active_tabs: derive guided defaults
→ no canonical preference on completed legacy account: controlled recovery
→ refresh local SharedPreferences cache
```

Required:
- [ ] wire `AppPreferencesRepository` into authenticated app/session bootstrap;
- [ ] valid remote state wins over stale local cache;
- [ ] cleared local cache recovers from remote;
- [ ] second device recovers from remote;
- [ ] app_mode-only canonical row derives current guided defaults without silently changing semantic mode;
- [ ] missing remote preference never silently becomes Hybrid;
- [ ] malformed canonical row surfaces controlled bootstrap failure/recovery rather than local success;
- [ ] pre-auth local staging cannot overwrite another authenticated account;
- [ ] no Settings write cutover yet;
- [ ] focused bootstrap/controller/router tests + full relevant CI before O1E.

Exit: authenticated navigation no longer depends on a stale/missing device-local App Mode value.

## O1E — Settings mode-change parity

Required:
- Settings writes canonical `app_mode` + derived `active_tabs`;
- local controller/cache updates only with canonical-success semantics;
- remote failure does not display/save a false mode change;
- mode changes never delete Body/Nutrition/Workout owner data.

## O1F — Integrated acceptance

Required:
- first-device onboarding completion;
- fresh install / cleared local storage;
- second-device login;
- stale local vs valid remote precedence;
- app-mode-only legacy row derives defaults;
- completed legacy account with no row uses controlled recovery;
- invalid/duplicate canonical tab state fails safely;
- Settings mode change persists remotely;
- hidden owner data survives mode changes;
- Flutter analyze + Dart analyze + Flutter tests + Dart tests;
- exact final O1 checkpoint recorded in #11, #40, #44 and canonical onboarding task.

## Guardrails

- `user_app_preferences` is canonical App Mode/navigation owner;
- `users` remains account root;
- `user_profiles` owns common Profile only;
- SharedPreferences becomes cache/pre-auth staging, not authenticated account authority;
- no permanent local/remote competing authorities;
- no silent semantic mode inference;
- onboarding draft mode is temporary orchestration state only;
- no custom-tab UI redesign in O1;
- mode changes never delete hidden domain data;
- future backend consumes the same backend-neutral preference contract/table.

## Handoff

**Start O1D authenticated bootstrap/restore.**  
Do not start O1E until O1D focused tests + CI are green.  
After O1F validation, update trackers and start O2 common Profile owner/section.
