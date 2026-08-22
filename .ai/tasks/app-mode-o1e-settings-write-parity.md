# App Mode O1E — Settings Canonical Write Parity

**Status:** In progress  
**Tracker:** GitHub Issue #11  
**Parent task:** `.ai/tasks/app-mode-foundation.md`  
**Canonical onboarding sequence:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**Implementation PR:** #50  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Outcome

Make authenticated Settings App Mode changes persist canonical `user_app_preferences` before publishing the new runtime/local App Mode, while preserving the existing Settings UI and all hidden domain data.

## Verified starting point

O1D is validated at:

```text
d5f03847d8c3e0216aa1acf864b44e31abbc251a
Flutter CI #1210 / run 32550641153
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Before O1E, Settings save remained local-only:

```text
AppModeSettingsPage.onModeChanged
→ AppModeController.select(mode)
→ SharedPreferences AppModePreference
→ navigate Home
```

`AppModeSettingsPage` already catches save failures and renders the existing controlled error state.

## In scope

- make `AppModeController.select` canonical-first only while session bootstrap has published a completed authenticated `Ready` state;
- write `AppPreferencesUpdate.guided(mode)` through backend-neutral `AppPreferencesRepository` first;
- publish the accepted canonical mode + ordered guided destinations only after canonical success;
- keep local SharedPreferences as best-effort cache after canonical success;
- disable canonical writes during pre-auth, Account Setup, Product Onboarding, signed-out, switching-account, bootstrap-failure and disposed states;
- canonical write failure preserves current semantic mode/destinations and surfaces through existing Settings failure UI;
- successful mode change keeps the existing router behavior: navigate Home only after `AppModeController.select` completes;
- focused controller/session/Settings widget regression tests;
- full relevant Flutter/Dart CI and exact checkpoint before O1F.

## Out of scope

- Settings UI redesign or copy/layout changes;
- custom-tab editing;
- schema/RLS/migration changes;
- Product Onboarding O2 Profile work;
- deleting or clearing hidden Body/Nutrition/Workout data;
- Account contact verification (#8).

## Architecture decision

No router/business-logic expansion is required. `AppSessionBootstrapController` already owns authenticated lifecycle and O1D canonical restore, so it gates whether `AppModeController.select` has access to the canonical writer.

```text
pre-auth / Account Setup / Product Onboarding
→ canonical Settings writer disabled
→ AppModeController.select remains local staging/cache behavior

completed authenticated Ready
→ bootstrap enables AppPreferencesRepository on AppModeController
→ Settings selection
→ AppPreferencesRepository.upsert(AppPreferencesUpdate.guided(mode))
→ canonical success
→ best-effort local cache refresh
→ runtime mode + guided destinations publish
→ existing router callback navigates Home

sign-out / account switch / bootstrap failure
→ canonical writer disabled before further selection
```

This preserves O1C completion ordering: onboarding already writes canonical preferences before its local confirmed-mode publication, so its local `select` path must not perform a second remote write before `markReadyAfterOnboardingCompletion` enables Settings parity.

Failure before canonical success must not mutate current runtime/local semantic mode. A local cache failure after canonical success must not roll back or hide valid canonical account truth.

## Acceptance checklist

- [x] backend-neutral repository is used for completed authenticated Settings save;
- [x] canonical write happens before runtime mode publication;
- [x] payload contains semantic `app_mode` + derived ordered `active_tabs`;
- [x] canonical failure leaves current mode/destinations unchanged;
- [x] existing Settings failure UI receives the thrown canonical failure;
- [x] local cache failure after canonical success still publishes canonical runtime truth;
- [x] pre-auth/onboarding/signed-out state cannot write another authenticated account preference;
- [x] successful save continues to update route/shell visibility through `AppModeController.activeDestinations`;
- [x] no hidden owner data repository is involved or deleted;
- [x] existing Settings App Mode production UI/source remains unchanged;
- [x] focused controller/session/Settings widget tests added;
- [ ] full CI green;
- [ ] exact O1E checkpoint recorded in #11, #40/#44, PR #50 and canonical tasks.

## Validation

Implementation source is ready for CI. Do not mark Validated until Flutter/Dart analyze + tests are green on the exact source checkpoint.

## Exit criteria

Settings App Mode is no longer a local-only write path. O1F integrated acceptance is next only after O1E validation is recorded.
