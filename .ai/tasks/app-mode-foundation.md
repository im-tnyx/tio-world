# App Mode Foundation — O1 Durable Account Preference

**Status:** In progress — O1A + O1B + O1C + O1D validated; O1E Settings mode-change parity is NEXT  
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

## Current runtime state

```text
Onboarding completion
→ canonical user_app_preferences ✅
→ local App Mode cache ✅

Returning login / fresh install / second device
→ canonical user_app_preferences wins ✅
→ exact active_tabs order restored ✅
→ local cache refreshed best-effort ✅

Settings mode change
→ still local-only ❌  ← O1E
```

`user_app_preferences` is authenticated account truth. SharedPreferences is cache/pre-auth staging, not authenticated authority.

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
- validated `AppPreferencesUpdate` and `AppPreferencesUpdate.guided(AppMode)`;
- backend-neutral `AppPreferencesRepository.read/upsert`;
- stable `AppDestination.storageValue` + parser;
- duplicate/empty rejection, order preservation and defensive copies.

### O1B — Supabase adapter ✅

```text
641e6eb55dfcbfa43ad1e7e95898c21c0faeb7be
Flutter CI #1187 / run 32547641191
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Implemented:
- `SupabaseAppPreferencesRepository` targets only `user_app_preferences`;
- authenticated-user requirement;
- missing row → explicit missing state;
- app-mode-only row + null `active_tabs` supported;
- strict parsing, supported IDs only, duplicate/empty rejection;
- ordered `active_tabs` preserved;
- one logical `user_id` + `app_mode` + `active_tabs` upsert;
- query/RLS/auth/gateway failures surface rather than becoming local success.

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
- `CompleteOnboardingUseCase` accepts explicit backend-neutral `AppPreferencesRepository`;
- successful completion orders owner data → optional finalizer → canonical App Preferences → local App Mode cache → remote completion → local completion → best-effort draft clear;
- canonical write failure prevents false local mode/completion publication;
- missing canonical preference on completed retry is repaired;
- `OnboardingCompletionRepository` and `AppPreferencesRepository` remain separate contracts.

### O1D — authenticated bootstrap/restore ✅

Focused evidence: `.ai/tasks/app-mode-o1d-authenticated-bootstrap-restore.md`

```text
d5f03847d8c3e0216aa1acf864b44e31abbc251a
Flutter CI #1210 / run 32550641153
Bootstrap workspace        ✅
Analyze Flutter packages   ✅
Analyze Dart packages      ✅
Test Flutter packages      ✅
Test Dart packages         ✅
```

Implemented:
- completed authenticated bootstrap reads `AppPreferencesRepository` before `AppSessionBootstrapReady`;
- valid canonical state overrides stale/missing local state;
- exact ordered `active_tabs` is carried through controller, shell and route allow-list;
- `app_mode` + null tabs derives guided defaults;
- missing completed-legacy row clears stale device semantic mode and keeps compatibility navigation without semantic inference;
- missing semantic mode in a present row, malformed rows and canonical read failures keep bootstrap out of `Ready`;
- local cache write failure cannot override accepted remote truth;
- focused controller/session/route tests cover cleared-local/second-device-equivalent, stale-local, app-mode-only, missing, malformed and exact-order states.

## O1 execution order

```text
O1A domain/repository contract          ✅ #1183
→ O1B Supabase adapter                  ✅ #1187
→ O1C onboarding completion cutover     ✅ #1199
→ O1D authenticated bootstrap/restore   ✅ #1210
→ O1E Settings mode-change parity       NEXT
→ O1F integrated acceptance/full CI
```

Only one O1 sub-slice is active at a time. Do not start O2 common Profile until O1F is validated.

## O1E — Settings mode-change parity — NEXT

Required:
- Settings writes canonical `app_mode` + derived ordered `active_tabs`;
- local controller/cache publishes the new mode only after canonical-success semantics;
- canonical write failure does not display/save a false mode change;
- current effective mode remains intact on failure;
- mode changes never delete Body/Nutrition/Workout owner data;
- preserve current Settings/App Mode UI;
- focused Settings/controller/router tests + full relevant CI before O1F.

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
- SharedPreferences is cache/pre-auth staging, not authenticated account authority;
- no permanent local/remote competing authorities;
- no silent semantic mode inference;
- onboarding draft mode is temporary orchestration state only;
- no custom-tab UI redesign in O1;
- mode changes never delete hidden domain data;
- future backend consumes the same backend-neutral preference contract/table.

## Handoff

**Start O1E Settings App Mode canonical write parity.**  
Do not start O1F until O1E focused tests + CI are green.  
After O1F validation, update trackers and start O2 common Profile owner/section.
