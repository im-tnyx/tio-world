# App Mode Foundation

**Status:** In progress
**Primary owners:** `apps/shared`, onboarding, Settings, `apps/app`, `apps/core`

## Outcome

Give each user one selected phone mode: `workout`, `nutrition`, or `hybrid`. The selected mode determines the guided default tabs and can be chosen in onboarding then changed from Settings.

## Verified Starting Point Before This Slice

- `apps/app/lib/app/router.dart` had a fixed five-branch `StatefulShellRoute.indexedStack`: Home, Nutrition, Tio/AI, Workout, and Progress.
- `apps/shared` had no `AppMode` enum.
- Onboarding and Settings routes rendered placeholders.
- The documented target is Home/Workout/Progress for workout, Home/Nutrition/Progress for nutrition, and Home/Workout/Nutrition/Progress for hybrid. Coach is deferred to Phase 7.

## Approved Persistence Decision

- Persist the confirmed selection device-locally for the first slice.
- Keep the pure-Dart mode preference contract in `apps/shared`; wire the platform storage adapter from the `apps/app` composition boundary.
- If the stored value is missing or invalid, route to mode selection rather than silently choosing a mode.
- Defer Supabase/account sync until an approved profile contract exists.
- Do not add a Supabase schema, Storage bucket, backend endpoint, or cross-device merge behavior in this slice.

## In Scope

1. Add the pure-Dart `AppMode` contract in `apps/shared`.
2. Add a mode preference boundary and state owner without placing business logic in widgets.
3. Make onboarding's first real step select the mode; condition later onboarding steps from that value.
4. Make Settings read and change the selected mode.
5. Compose the guided `StatefulShellRoute` layout from the active mode and map the visible destination order safely.
6. Keep Workout Library and Meal Plan outside the guided default list; future custom promotion belongs to the separate adaptive-navigation task.
7. Add focused tests for enum/state mapping and navigation branch selection.

## Out of Scope

- Coach tab before Phase 7.
- Meal Plan, nutrition diary, workout execution, health data, or watch synchronization.
- Supabase profile storage, account sync, migrations, Storage buckets, or protected backend changes unless separately approved.
- Avatar extraction; track it as its own UI component slice.
- Three-to-six custom destination selection, promoted shortcuts, adaptive Home sections, and action-entry placement; track them in [adaptive-navigation-and-actions.md](adaptive-navigation-and-actions.md).

## Acceptance Criteria

- Each mode produces exactly the documented guided default tabs with Home as the first tab.
- Changing the mode updates the primary-tab configuration without leaving an invalid selected tab.
- Onboarding and Settings use the same mode contract and preference boundary.
- The confirmed selection survives an app restart, and missing/invalid local data returns safely to mode selection.
- No feature package imports another feature's private UI/state implementation.
- Relevant Dart tests and static analysis pass, and documentation status is updated from the observed source.

## Implementation Evidence

- [x] `apps/shared` owns `AppMode`, `AppDestination`, guided destination mappings, and the pure-Dart `AppModePreference` boundary.
- [x] `apps/app` wires `SharedPreferencesAsync`, loads the stored mode before router composition, and owns one `AppModeController` through Riverpod.
- [x] Onboarding's first real screen selects and persists the mode; missing or invalid local data returns there.
- [x] Settings reads and changes the same mode from a Home app-bar entry.
- [x] Visible shell tabs and route eligibility are derived from stable destination identity. Static registered branch indexes are not treated as visible-tab indexes.
- [x] Unavailable mode routes and deferred Coach routes reconcile to Home.
- [x] Focused controller, route-policy, and bottom-navigation tests cover all three modes and persistence failure behavior.
- [ ] Build the later common-profile, Workout, Nutrition, review, and finish onboarding steps and condition them by mode.
- [ ] Manually verify persistence across a real device/emulator process restart.

## Validation Run

```text
apps/app: flutter analyze -> PASS, no issues
apps/app: flutter test -> PASS, 13 tests
apps/app: flutter build apk --debug -> NOT VERIFIED; Gradle distribution download timed out before compilation
repository: git diff --check -> PASS
```

## Known Limitations

- Home, Workout, Nutrition, and Progress still use placeholder content; this slice changes reachability, not feature implementation.
- The current onboarding route completes only App Mode selection. It previews the next relevant setup but does not yet collect profile or feature configuration.
- Account sync, Supabase schema, backend behavior, and watch synchronization remain out of scope.

## Final Status

`PARTIAL` — the mode contract, local preference, guided shell, first onboarding step, and Settings editor are implemented and automatically validated. Full mode-conditional onboarding and manual restart verification remain.

## Canonical Links

- [Architecture](../../docs/ARCHITECTURE.md)
- [Roadmap](../../docs/ROADMAP.md)
- [Module ownership](../../docs/MODULE_OWNERSHIP.md)
- [Current state](../CURRENT.md)
