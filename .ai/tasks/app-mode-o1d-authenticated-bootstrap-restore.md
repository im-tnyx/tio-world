# App Mode O1D — Authenticated Bootstrap / Restore

**Status:** Validated  
**Tracker:** GitHub Issue #11  
**Parent task:** `.ai/tasks/app-mode-foundation.md`  
**Canonical onboarding sequence:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**Implementation PR:** #50  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Outcome

Authenticated session bootstrap now resolves canonical `user_app_preferences` before publishing a completed signed-in account as ready. Valid remote App Mode/navigation wins over stale or missing device-local state.

## Validated checkpoint

```text
Source: d5f03847d8c3e0216aa1acf864b44e31abbc251a
Flutter CI #1210 / run 32550641153
Bootstrap workspace        ✅
Analyze Flutter packages   ✅
Analyze Dart packages      ✅
Test Flutter packages      ✅
Test Dart packages         ✅
```

## Implemented contract

```text
authenticated session
→ read onboarding completion
→ completed: read canonical user_app_preferences before Ready
→ valid active_tabs: restore exact order
→ app_mode + null active_tabs: derive current guided defaults
→ best-effort refresh local App Mode cache
→ publish final Ready/navigation
```

Behavior:
- valid canonical remote state overrides stale local mode;
- cleared local storage / second-device-equivalent state restores from remote;
- exact ordered `active_tabs` is carried through `AppModeController`, shell visibility and route allow-list;
- app-mode-only canonical rows derive guided destinations without changing semantic mode;
- a missing completed-legacy preference clears stale device semantic mode and keeps the existing compatibility navigation path without inventing Hybrid;
- present canonical state without `app_mode`, malformed canonical rows and canonical read failures keep bootstrap out of `Ready`;
- local cache write failure does not override accepted valid remote truth;
- non-Supabase/test compositions may omit the remote capability without fabricating canonical semantics;
- Settings mode writes remain unchanged for O1E.

## Scope proof

O1D diff from prior checkpoint `ad07ac018d2ed61e71d2f82bb9479bd3a4adb45a` is limited to:

```text
.ai/tasks/app-mode-o1d-authenticated-bootstrap-restore.md
apps/app/lib/app/app_mode/app_mode_controller.dart
apps/app/lib/app/app_mode/app_mode_route_policy.dart
apps/app/lib/app/router.dart
apps/app/lib/app/session/app_session_bootstrap_controller.dart
apps/app/lib/app/session/app_session_bootstrap_providers.dart
apps/app/test/app/app_mode_active_destinations_route_policy_test.dart
apps/app/test/app/app_mode_controller_test.dart
apps/app/test/app/session/app_session_app_preferences_restore_test.dart
```

No schema/RLS migration, Settings write cutover, Profile/Body work, hidden-domain deletion or UI redesign is included.

## Implementation checklist

- [x] extend runtime App Mode state to carry effective ordered destinations;
- [x] add canonical restore behavior with local cache demoted to best-effort cache;
- [x] inject `AppPreferencesRepository` + `AppModeController` into authenticated bootstrap;
- [x] resolve canonical preferences before completed-account `Ready`;
- [x] route/shell consumes effective canonical destinations;
- [x] retain missing-row compatibility without silent Hybrid;
- [x] cover stale local, cleared-local/second-device-equivalent, app-mode-only, missing, malformed and exact-order states;
- [x] full Flutter/Dart CI green;
- [x] exact source/checkpoint recorded.

## Out of scope / next

O1E is next and owns Settings App Mode canonical write parity. Do not fold custom-tab UI, Product Onboarding O2 Profile work or schema changes into O1E.
