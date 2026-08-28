# App Mode O1E — Settings Canonical Write Parity

**Status:** Validated  
**Tracker:** GitHub Issue #11  
**Parent task:** `.ai/tasks/app-mode-foundation.md`  
**Canonical onboarding sequence:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**Implementation PR:** #50  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Outcome

Authenticated Settings App Mode changes now persist canonical `user_app_preferences` before publishing the new runtime/local App Mode, while preserving the existing Settings UI and all hidden domain data.

## Validated checkpoint

```text
Source: 7210fe7409af9f41f7478096e19d56853e8060d4
Flutter CI #1231 / run 32551614514
Bootstrap workspace        ✅
Analyze Flutter packages   ✅
Analyze Dart packages      ✅
Test Flutter packages      ✅
Test Dart packages         ✅
```

An earlier run (#1230) exposed only a widget-test geometry issue: the new test attempted to tap an off-screen Settings card behind the fixed bottom action bar. Production logic and all controller/session O1E tests passed. The test was corrected to scroll the real Settings `ListView` before interaction; #1231 is the authoritative O1E validation.

## Implemented contract

`AppSessionBootstrapController` owns whether `AppModeController.select` is allowed to use the authenticated canonical writer:

```text
pre-auth / Account Setup / Product Onboarding
→ canonical writer disabled
→ local staging remains available

completed authenticated Ready
→ canonical writer required
→ Settings selection
→ AppPreferencesRepository.upsert(AppPreferencesUpdate.guided(mode))
→ canonical success
→ best-effort SharedPreferences cache refresh
→ runtime mode + guided destinations publish
→ existing router callback may navigate Home

sign-out / account switch / bootstrap failure / dispose
→ canonical writer disabled before further local staging
```

Validated semantics:
- `AppPreferencesUpdate.guided(mode)` writes semantic `app_mode` plus ordered guided `active_tabs`;
- canonical write completes before runtime/local publication;
- canonical write failure leaves current mode, active destinations and local cache unchanged;
- completed authenticated state fails closed if its canonical repository is unexpectedly unavailable;
- local cache failure after canonical success cannot roll back accepted canonical truth;
- pre-auth/onboarding/signed-out selection cannot write another authenticated account's canonical preference;
- O1C onboarding completion does not double-write App preferences because Settings canonical write gating is enabled only after `Ready` publication;
- existing Settings error rendering and router success-navigation behavior are reused unchanged;
- no Settings production UI source, router production source, schema/RLS, Profile/Body owner or hidden Nutrition/Workout/Body data path was changed.

## Acceptance checklist

- [x] backend-neutral repository is used for completed authenticated Settings save;
- [x] canonical write happens before runtime mode publication;
- [x] payload contains semantic `app_mode` + derived ordered `active_tabs`;
- [x] canonical failure leaves current mode/destinations unchanged;
- [x] canonical failure does not reach the existing post-save Home navigation;
- [x] existing Settings failure UI receives the thrown canonical failure;
- [x] local cache failure after canonical success still publishes canonical runtime truth;
- [x] completed authenticated updates fail closed without a canonical repository;
- [x] pre-auth/onboarding/signed-out state cannot write another authenticated account preference;
- [x] successful save updates route/shell visibility through `AppModeController.activeDestinations`;
- [x] no hidden owner data repository is involved or deleted;
- [x] existing Settings App Mode production UI/source remains unchanged;
- [x] focused controller/session/Settings widget tests added;
- [x] full Flutter/Dart CI green;
- [x] exact O1E source checkpoint recorded here.

## Scope proof

O1E production changes are limited to:

```text
apps/app/lib/app/app_mode/app_mode_controller.dart
apps/app/lib/app/session/app_session_bootstrap_controller.dart
```

Focused tests/task evidence:

```text
.ai/tasks/app-mode-o1e-settings-write-parity.md
apps/app/test/app/app_mode_controller_test.dart
apps/app/test/app/app_mode_authenticated_write_requirement_test.dart
apps/app/test/app/app_mode_settings_write_parity_test.dart
apps/app/test/app/session/app_session_app_preferences_restore_test.dart
```

## Exit / next

O1E is validated. O1F integrated App Mode acceptance/full CI is next. Do not start Product Onboarding O2 common Profile until O1F is validated and the final O1 checkpoint is recorded.
