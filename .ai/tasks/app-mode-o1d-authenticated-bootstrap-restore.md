# App Mode O1D — Authenticated Bootstrap / Restore

**Status:** In progress  
**Tracker:** GitHub Issue #11  
**Parent task:** `.ai/tasks/app-mode-foundation.md`  
**Canonical onboarding sequence:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**Implementation PR:** #50  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Outcome

Make authenticated session bootstrap resolve canonical `user_app_preferences` before publishing the signed-in app as ready, so remote App Mode/navigation wins over stale or missing device-local state.

## Verified starting point

O1A/O1B/O1C are validated. O1C authoritative source is `74e45c9186aed8a6505ca8eef9cd5333de366308` with Flutter CI #1199 green.

Current gap:

```text
onboarding completion → user_app_preferences ✅
returning authenticated bootstrap → local AppMode cache can still win ❌
```

`AppSessionBootstrapController` currently reconciles durable onboarding completion but does not read `AppPreferencesRepository` before `AppSessionBootstrapReady`.

## In scope

- wire backend-neutral `AppPreferencesRepository` into authenticated session bootstrap;
- make valid canonical remote App Mode/navigation win over stale local state;
- restore exact ordered `active_tabs` when present;
- derive guided destinations when canonical `app_mode` exists but `active_tabs` is null;
- refresh the existing local App Mode cache only after canonical remote state is accepted;
- preserve a controlled completed-legacy path when no canonical preference exists without inventing Hybrid;
- fail bootstrap safely for malformed/unusable canonical state;
- keep pre-auth pending App Mode separate from authenticated restore;
- focused controller/router tests for remote precedence, cleared-local/second-device equivalence, app-mode-only rows, missing rows, malformed state, and exact tab ordering;
- relevant Flutter/Dart CI before O1E begins.

## Out of scope

- Settings App Mode canonical write cutover (O1E);
- custom-tab UI or navigation redesign;
- Product Onboarding O2 Profile work;
- schema/RLS/migration changes;
- hidden Body/Nutrition/Workout data deletion;
- account email/mobile verification (#8).

## Architecture decision

`user_app_preferences` is authenticated account truth. `SharedPreferencesAppModePreference` remains cache/pre-auth staging only.

Bootstrap ordering:

```text
authenticated session
→ read onboarding completion
→ read canonical user_app_preferences before Ready
→ valid active_tabs: restore exact order
→ app_mode + null active_tabs: derive current guided defaults
→ refresh local App Mode cache
→ publish final Ready/navigation
```

A missing completed-legacy preference may use the existing compatibility navigation path, but must not fabricate a semantic App Mode. A malformed canonical row is a controlled bootstrap failure, not local success.

## Implementation checklist

- [ ] extend runtime App Mode state to carry effective ordered destinations;
- [ ] add canonical restore API that persists accepted semantic mode to local cache before publishing it;
- [ ] inject `AppPreferencesRepository` + `AppModeController` into `AppSessionBootstrapController`;
- [ ] resolve canonical preferences before completed-account `Ready`;
- [ ] route/shell consumes effective canonical destinations instead of always deriving from mode;
- [ ] retain missing-row compatibility without silent Hybrid;
- [ ] add focused controller tests;
- [ ] add route-policy/exact-order regression coverage;
- [ ] run relevant CI and record exact source/checkpoint;
- [ ] update #11, #40/#44 and parent/canonical tasks before O1E.

## Validation

Not run yet. Do not mark Validated until CI completes on the implementation source.

## Exit criteria

Authenticated navigation no longer depends on stale/missing local App Mode when valid canonical preferences exist, and O1D focused/full relevant CI is green. Only then may O1E Settings parity start.
