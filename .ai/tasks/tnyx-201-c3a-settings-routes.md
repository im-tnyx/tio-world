# TNYX-201 C3a — Settings Route Registration Extraction

**Status:** In progress
**Primary owner:** apps/app routing composition
**Tracker:** GitHub #389; parent #357 / #260; Linear TNYX-201
**Approval:** Owner authorized planning/preparation via chat on 2026-09-26. Source implementation remains bounded to this recorded slice.

## Outcome

Extract only Settings root, App Mode, Calendar and Theme route registration from `apps/app/lib/app/router.dart` into `apps/app/lib/app/routing/routes/settings_routes.dart`, preserving one root GoRouter authority and all behavior.

## Current-head audit

- base: `main` after C2b2 archive PR #388
- router blob before branch: `8e596dd7908647a41e20fd636a285f55e4f11e1d`
- root `AGENTS.md` applies; no `apps/app/AGENTS.md` exists
- feature `AGENTS.md` reviewed for ownership/visual safety context
- #389 freezes the bounded C3a scope

## In scope

- `AppRoutes.settings`
- `AppRoutes.appModeSettings`
- `AppRoutes.calendarSettings`
- `AppRoutes.themeSettings`
- root-injected callbacks/controllers needed to preserve those registrations

## Out of scope

Profile/Profile Avatar/Profile completion; Measurement Units; Nutrition Settings/loading/error UI; Daily Wellness; Body & Weight; Account Settings; AppOnboardingController; CalendarPreferencesController redesign/move; provider ownership migration; UI; persistence/API/Supabase/schema changes.

## Ownership classification

- Settings route registration: APP COMPOSITION
- App Mode route registration: APP COMPOSITION; AppMode contract remains shared
- Calendar route registration: APP COMPOSITION; Calendar Preferences domain/repository remains Settings-owned and controller construction/resolution remains app-owned
- Theme route registration: APP COMPOSITION
- SettingsPage and preference pages: FEATURE PRESENTATION, unchanged
- logout/session clear, App Mode mutation, Calendar save state and Theme mutation: existing owners preserved; route module only receives/composes required callbacks/state

## Behavior invariants

Same paths/deep links, root navigator, Settings callbacks, Nutrition visibility by AppMode, logout/Auth navigation, AppMode/Home navigation, Calendar state/error behavior, Theme pop behavior, and single `goRouterProvider` / `GoRouter(...)`.

## Implementation checklist

- [x] verify branch/worktree state before source mutation (GitHub/API equivalent: base/merge-base `main@42d4435e`, 6 ahead / 0 behind, exactly 4 owned paths before fix)
- [x] create `routing/routes/settings_routes.dart`
- [x] replace only four recorded root route registrations with builder assembly
- [x] audit references/imports and one-router authority
- [ ] run focused app validation
- [ ] run required broader validation
- [ ] review exact head and reconcile trackers

## Exit criteria

No unrelated route block moves, no UI/business/persistence change, validation passes, review findings resolved, and post-merge archive completed before the next source slice.

## Implementation checkpoint

- branch compare: 5 commits ahead / 0 behind from `main@42d4435e`
- effective paths: 4
- one `GoRouter(...)` remains in root router
- one `buildSettingsRoutes(...)` assembly point
- extracted module contains exactly the four frozen route paths
- `AppRoutes.appSettings` and `AppRoutes.measurementUnitsSettings` remain in root router
- next gate: PR exact-head Flutter CI and review; local CLI validation is not claimed from connector-only execution

## CI correction checkpoint

- Flutter CI #2800 / run `36238809064` failed in `Analyze Flutter packages` only.
- Exact finding: unused `package:tio_shared/shared.dart` import in `apps/app/lib/app/router.dart` after Settings routes moved to their owned module.
- Narrow fix commit: `90e95db2ed946aa98e343ae79d90744531ef34bd`; removed only that stale import, with no behavior or scope change.
- Bootstrap had passed before the analyzer finding; later analyze/test steps were skipped by fail-fast.
- next gate: fresh exact-head CI on the corrected branch, then independent review/thread audit.
