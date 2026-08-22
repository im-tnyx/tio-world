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

Current Settings save path is still local-only:

```text
AppModeSettingsPage.onModeChanged
→ AppModeController.select(mode)
→ SharedPreferences AppModePreference
→ navigate Home
```

`AppModeSettingsPage` already catches save failures and renders the existing controlled error state.

## In scope

- add a bounded app-level Settings App Mode update orchestration boundary;
- write `AppPreferencesUpdate.guided(mode)` through backend-neutral `AppPreferencesRepository` first;
- publish the accepted canonical mode + ordered guided destinations through `AppModeController` only after canonical success;
- keep local SharedPreferences as best-effort cache after canonical success;
- canonical write failure preserves current semantic mode/destinations and surfaces through existing Settings failure UI;
- successful mode change navigates Home only after canonical/local runtime publication;
- focused coordinator/controller/router/widget regression tests;
- full relevant Flutter/Dart CI and exact checkpoint before O1F.

## Out of scope

- Settings UI redesign or copy/layout changes;
- custom-tab editing;
- schema/RLS/migration changes;
- Product Onboarding O2 Profile work;
- deleting or clearing hidden Body/Nutrition/Workout data;
- Account contact verification (#8).

## Architecture decision

Authenticated Settings uses one write authority:

```text
Settings selection
→ AppPreferencesRepository.upsert(AppPreferencesUpdate.guided(mode))
→ canonical success
→ AppModeController publishes same canonical state
→ best-effort local cache refresh
→ navigation Home
```

Failure before canonical success must not mutate current runtime/local semantic mode. A local cache failure after canonical success must not roll back or hide valid canonical account truth.

## Acceptance checklist

- [ ] backend-neutral repository is required for authenticated Settings save;
- [ ] canonical write happens before runtime mode publication;
- [ ] payload contains semantic `app_mode` + derived ordered `active_tabs`;
- [ ] canonical failure leaves current mode/destinations unchanged;
- [ ] canonical failure does not navigate Home;
- [ ] local cache failure after canonical success still publishes canonical runtime truth;
- [ ] successful save updates route/shell visibility from canonical guided destinations;
- [ ] no hidden owner data deletion/calls;
- [ ] existing Settings App Mode UI remains pixel/behavior compatible;
- [ ] focused tests + full CI green;
- [ ] exact O1E checkpoint recorded in #11, #40/#44, PR #50 and canonical tasks.

## Validation

Not run yet. Do not mark Validated until implementation-source CI is green.

## Exit criteria

Settings App Mode is no longer a local-only write path. O1F integrated acceptance is next only after O1E validation is recorded.
