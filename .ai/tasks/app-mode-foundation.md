# App Mode Foundation — O1 Durable Account Preference

**Status:** In progress — O1A + O1B + O1C + O1D + O1E validated; O1F integrated acceptance is NEXT  
**Primary owners:** `apps/shared`, `apps/app`, onboarding, Settings, `user_app_preferences`  
**Tracker:** #11  
**Product Onboarding tracker:** #40  
**Canonical sequence:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**PR:** #50 remains Draft/unmerged

## Outcome

Make App Mode a durable authenticated-account preference that survives restart, cleared local storage, fresh install and second-device login, with onboarding, bootstrap and Settings using one canonical account owner.

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

Settings mode change while authenticated Ready
→ canonical user_app_preferences first ✅
→ runtime/local publish only after canonical success ✅
→ canonical failure preserves current mode ✅
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

Implemented `AppPreferencesState`, validated `AppPreferencesUpdate`, backend-neutral `AppPreferencesRepository`, stable `AppDestination` storage IDs, order preservation and duplicate/empty validation.

### O1B — Supabase adapter ✅

```text
641e6eb55dfcbfa43ad1e7e95898c21c0faeb7be
Flutter CI #1187 / run 32547641191
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Implemented authenticated `SupabaseAppPreferencesRepository` against only `user_app_preferences`, strict canonical parsing, explicit missing state, app-mode-only recovery support, ordered tabs and one logical canonical upsert.

### O1C — onboarding completion cutover ✅

```text
74e45c9186aed8a6505ca8eef9cd5333de366308
Flutter CI #1199 / run 32549215504
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Onboarding successful completion now persists canonical App preferences before local mode/completion publication; failure remains retryable and missing canonical preference on completed retry is repaired.

### O1D — authenticated bootstrap/restore ✅

Focused evidence: `.ai/tasks/app-mode-o1d-authenticated-bootstrap-restore.md`

```text
d5f03847d8c3e0216aa1acf864b44e31abbc251a
Flutter CI #1210 / run 32550641153
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Completed authenticated bootstrap reads canonical preferences before `Ready`, restores exact tab order, lets remote truth beat stale/missing local state, derives guided defaults for app-mode-only rows, and keeps malformed/unusable canonical state out of `Ready`.

### O1E — Settings canonical write parity ✅

Focused evidence: `.ai/tasks/app-mode-o1e-settings-write-parity.md`

```text
7210fe7409af9f41f7478096e19d56853e8060d4
Flutter CI #1231 / run 32551614514
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Implemented:
- completed authenticated `Ready` sessions require `AppPreferencesRepository` for App Mode selection;
- Settings `AppModeController.select` writes `AppPreferencesUpdate.guided(mode)` before runtime publication;
- canonical failure leaves semantic mode, active destinations and local cache unchanged;
- missing canonical writer in `Ready` fails closed instead of falling back local-only;
- local cache failure after canonical success cannot roll back remote truth;
- pre-auth, Account Setup, Product Onboarding, signed-out, account-switch, bootstrap-failure and dispose states disable canonical Settings writes;
- O1C onboarding does not double-write because canonical Settings gating starts only after `Ready`;
- existing Settings production UI and router production source remain unchanged;
- focused controller/session/real Settings widget tests lock success and failure semantics.

## O1 execution order

```text
O1A domain/repository contract          ✅ #1183
→ O1B Supabase adapter                  ✅ #1187
→ O1C onboarding completion cutover     ✅ #1199
→ O1D authenticated bootstrap/restore   ✅ #1210
→ O1E Settings mode-change parity       ✅ #1231
→ O1F integrated acceptance/full CI     NEXT
```

Only one O1 sub-slice is active at a time. Do not start O2 common Profile until O1F is validated.

## O1F — Integrated acceptance — NEXT

Required:
- first-device onboarding completion writes canonical preference;
- fresh install / cleared local storage restores canonical state;
- second-device-equivalent login restores canonical state;
- stale local vs valid remote precedence;
- exact canonical `active_tabs` order reaches shell + route allow-list;
- app-mode-only legacy row derives guided defaults;
- completed legacy account with no row uses controlled compatibility recovery;
- invalid/duplicate/malformed canonical state fails safely;
- Settings mode change persists remotely and survives subsequent bootstrap/restore;
- canonical Settings failure never becomes false local success/navigation;
- authenticated Ready with missing canonical writer fails closed;
- hidden Body/Nutrition/Workout owner data is untouched by mode changes;
- full Flutter analyze + Dart analyze + Flutter tests + Dart tests;
- exact final O1 checkpoint recorded in #11, #40, #44, PR #50 and canonical onboarding task.

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

**Start O1F integrated App Mode acceptance/full CI.**  
Do not start O2 until O1F final validation evidence is recorded.  
After O1F validation, update trackers and start O2 common Profile owner/section activation.
