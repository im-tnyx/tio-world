# TNYX-201 C3a — Settings Route Registration Extraction

**Status:** In progress
**Primary owner:** apps/app routing composition
**Tracker:** GitHub #389; parent #357 / #260; Linear TNYX-201

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner instructed “Go next” for the current #260/router continuation in project chat on 2026-09-26 and has now explicitly instructed continuation of the latest PR under `AGENTS.md`. The pre-implementation task brief did not record source-implementation approval clearly enough; that governance gap is recorded here rather than backdated.
**Approved product/UI/data-shape boundaries:** C3a is limited to extracting Settings root, App Mode, Calendar and Theme route registration into `app/routing/routes/settings_routes.dart` with behavior preserved.
**Explicit non-changes:** No Profile, Measurement Units, Nutrition, Wellness, Body, Account, `AppOnboardingController`, `CalendarPreferencesController` ownership, UI, persistence, API, Supabase or schema change.

## Active Handoff

**Planning owner:** TNYX-201 / GitHub #260 + #357 planning lane
**Implementation owner:** None active; bounded source implementation is complete on the PR branch
**Review owner:** Current PR review/reconciliation session
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub PR #390 exact branch/head review
**Branch:** `tnyx/tnyx-201-c3a-settings-routes`
**HEAD SHA:** `b5e7bea3db4b9505432f212f02e7f95e06b2483c` before this governance-only correction
**Observed working-tree state:** Connector/API review only; no local working tree claimed
**Observed uncommitted/dirty files:** Not applicable / not observable from connector execution
**PR / tracker:** PR #390; GitHub #389 / #357 / #260; Linear TNYX-201
**Current implementation state:** Four frozen Settings routes extracted; source diff independently reviewed as behavior-preserving
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/settings_routes.dart`
**Validation completed at SHA:** `9ac87c3086b40d3b098ee926417b763528282aa5` — Flutter CI #2801 full PASS
**Validation remaining:** Fresh exact-head Flutter CI after governance-only correction; fresh review-thread audit
**Current blocker:** None; prior Codex governance findings are resolved. Exact-head CI and fresh thread audit remain gates, not blockers.
**Open review finding IDs:** None
**Next exact action:** Complete exact-head CI, then re-audit review threads/checks before any merge decision.

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
- [x] run focused app validation (Flutter CI #2801 source/review head)
- [x] run required broader validation (full monorepo Flutter/Dart analyze + tests in CI #2801)
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

## Review handoff checkpoint

- validated head before this documentation-only handoff: `9ac87c3086b40d3b098ee926417b763528282aa5`
- Flutter CI #2801 / run `36239669793`: PASS (bootstrap, Flutter analyze, Dart analyze, Flutter tests, Dart tests)
- Commit attribution guard: PASS
- Attribution guard runner: PASS
- route/reference preservation audit: PASS for Settings, App Mode, Calendar, Theme, App Settings and Measurement Units references
- router authority audit: one root `goRouterProvider` / one root `GoRouter(...)`; extracted module constructs no `GoRouter`
- review-thread audit at validated head: 0 unresolved threads; 0 submitted reviews
- non-required GHAS: failed before analysis with `400 The requested model is not supported`; no code-scanning finding was produced
- this handoff commit is documentation-only; next gate is exact-final-head CI plus fresh review/thread audit before any merge decision


## Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| C3A-R1 | P2 | Resolved | Task brief used unsupported `In review` status while task index used `In progress`. | `b5e7bea3` | Status normalized to allowed `In progress`. |
| C3A-R2 | P1 | Resolved | Source-implementation approval evidence was not explicit enough in the pre-implementation brief. | `b5e7bea3` | Current owner approval is explicit; the earlier recording gap is documented and not backdated. No new source implementation is performed by this correction. |
| C3A-R3 | P2 | Resolved | Active ownership/handoff state was missing. | `b5e7bea3` | Added compact `Active Handoff` with implementation complete and review ownership active. |

| C3A-R4 | P1 | Resolved | Active Handoff still listed R1–R3 as blockers/open after their resolution. | `3ddc8727` | Blocker/open-ID fields now reflect the resolved state; remaining CI/thread audit is recorded as the next gate. |
| C3A-R5 | P1 | Resolved | Finding rows used non-contract status phrases instead of exact `Open` / `Resolved` / `Deferred`. | `3ddc8727` | Status cells normalized to exact `Resolved`; qualifiers remain in evidence text. |
