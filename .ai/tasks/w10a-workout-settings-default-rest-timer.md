# W10-A — Workout Settings Default Rest Timer

**Status:** In progress
**Primary owner:** Workout feature
**Affected platforms:** Android and iOS phone

## Owner Approval and Scope Boundary

**Trigger:** New product slice and product-visible navigation/settings UI
**Approval status:** Approved
**Approval evidence:** Owner-provided W10-A prompt and same-task behavior correction (2026-11-12).
**Approved boundaries:** One Workout Settings row and screen; Default Rest Timer is device-local. A newly added Exercise snapshots the current default in Create Routine, Edit Routine, and the existing Log Workout Save-only draft. The user can change or turn off that value at any time. Routine values use the existing SetPrescription.restSeconds composition contract; Active Workout uses its existing account-bound encrypted draft/recovery contract.
**Explicit non-changes:** No other Workout Settings options, contextual More menu, Supabase preference, table/column/RPC/migration, hosted write, cross-device preference sync, or new countdown engine. Do not mutate existing Routines, draft Exercises, or Active Workout Exercises when the global default changes. The legacy online W7B session controller is outside this Save-only draft slice.

## Active Handoff

**Planning owner:** Owner / TNYX-87
**Implementation owner:** Codex
**Previous agent:** Not applicable
**Last commit agent:** Codex — W10-A implementation commit
**Last commit SHA:** `ea4f44b4ac6826ad46407934326bbcdead99aab3` (`feat(flutter): add local default rest timer`)
**Review owner:** Pending PR review
**Implementation ownership state:** Handoff pending
**Ownership transition:** Not applicable
**Repository state last verified:** Git root G:/projects/Tio-World; W10-A implementation committed on `tnyx/w10a-default-rest-timer` at `ea4f44b4ac6826ad46407934326bbcdead99aab3`; main base was `080562208cf431bf34154478d4729d586d5ac679` before branch creation
**Branch:** tnyx/w10a-default-rest-timer
**HEAD SHA:** `ea4f44b4ac6826ad46407934326bbcdead99aab3` (implementation commit; task handoff update follows)
**Observed working-tree state:** Implementation commit clean; handoff metadata update in progress
**Observed uncommitted/dirty files:** This task brief only
**PR / tracker:** Linear TNYX-87 (Backlog, still blocked by TNYX-78 for broad W10); GitHub #48 (open, latest owner comment approves the first UI slice). No open PR existed at preflight; PR creation is pending. PR #740, which contains the current Save-only draft foundation, is merged.
**Current implementation state:** The approved setting screen and all three Exercise-add integrations are committed in `ea4f44b4ac6826ad46407934326bbcdead99aab3`. Routine OFF and Active Workout draft recovery contracts are wired; source review is complete, while executable Flutter validation and PR CI remain pending.
**Relevant execution surface:** Settings root and /settings/workout; Routine Create/Edit Add Exercise; Active Workout Log Workout Save-only draft Add Exercise and recovery.
**Validation completed at SHA:** `git diff --cached --check` passed on the reviewed staged diff. `melos bootstrap` was attempted and could not start because `melos` is not installed/on PATH.
**Validation remaining:** Flutter analyze/tests (Flutter/Dart toolchain unavailable locally); exact-head PR CI. Theme and compact-width widget coverage was added but cannot be executed locally.
**Current blocker:** Broad Linear W10 remains blocked by TNYX-78; this owner-approved W10-A child uses existing contracts and does not resolve that dependency. No source-level blocker found in the bounded audit.
**Open review finding IDs:** None yet.
**Next exact action:** Refresh `origin/main`, audit the exact branch delta, push the dedicated branch and create the authorized PR without merging.

## 1. Discovery

### User Outcome

The user can choose a device-local Default Rest Timer in Workout Settings. Each newly added Exercise receives that value once; subsequent changes to the global setting do not change already-added Exercises.

### Success Criteria

- Settings entry appears only when canonical AppMode includes Workout; Nutrition mode hides it and cannot open its route directly.
- Workout Settings uses the existing Routine Rest Timer wheel with Normal rest only, 5-second increments, OFF and a 600-second maximum.
- Unset local preference remains distinct from explicit OFF in storage; both initialize new Exercises to OFF.
- Create Routine and Edit Routine persist the initialized or user-modified value through existing Routine composition. Explicit OFF remains null/off after Save and reopen.
- The existing Log Workout Save-only draft snapshots the default on Exercise addition, permits manual override/OFF, retains the value through recovery, and uses the existing countdown behavior.
- Local preferences are keyed to the authenticated account on this device and never use a network write.

### Scope

- Add the one Settings navigation row, protected route, and feature-owned Workout Settings screen.
- Add one Workout-owned local settings repository/controller using SharedPreferencesAsync and an account-scoped key.
- Snapshot the current preference only when a new Exercise is added in the three approved paths.
- Preserve existing Exercise values and all unrelated Workout behavior.

### Non-Goals

- Any additional Workout setting, Active Workout execution backend, W7B persisted-session mutation, calendar/global preference, Nutrition setting, sensor, or new storage framework.
- Any Supabase schema or production change.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: SettingsPage, settings route composition, AppMode.guidedDestinations, AppRoutes, Workout public exports, RoutineRestTimerSheet, RoutineRestTimerPreset, RoutineCreateController, RoutineEditorController, ActiveWorkoutDraftController, ActiveWorkoutDraftExercise, ActiveWorkoutPage, workout/settings providers, SharedPreferencesAsync repository patterns, SecureActiveWorkoutDraftStore, and relevant tests/docs.
- Existing pattern to follow: feature packages own repository contracts/controllers/data/presentation; apps/app wires routes and auth-scoped providers. TioSettingsNavigationRow, TioSettingsValueRow and TioAppBar are available in the public Core boundary.
- Tests or validation already present: the shared sheet already tests OFF, five-second wheel selection, 600-second cap, and Normal-only configuration. Routine controllers store rest in SetPrescription.restSeconds. ActiveWorkoutDraftExercise already persists restPreset and hasRestOverride; ActiveWorkoutDraftController already resolves countdowns from that draft state.
- Tracker reconciliation: TNYX-87 is Backlog and blocked by TNYX-78. GitHub #48 remains open; its latest owner comment approves the W10-A UI/reuse scope but predates this task’s local-only and three-flow clarification. The current owner instruction supplies that clarification. TNYX-84 remains In Progress and blocked for broader W7; this slice uses its already-merged Save-only draft contract from PR #740, not the legacy online session controller.
- Canonical docs require Workout to own workout-specific settings, app composition to own routes, and all feature preferences to remain separate from Workout Profile/Targets. The current Workout Settings doc is planned-only and Settings doc says the entry is hidden; both need reconciliation after implementation.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Preference persistence | Approved: device-local per authenticated account | Explicit current-task owner decision; prevents another account from reading the value without introducing sync | Owner |
| Unset vs OFF | Unset is absent/null; explicit OFF is stored as 0; positive choices are 5–600 seconds in 5-second steps | OFF and no saved preference both initialize to OFF, but remain distinct in local storage | Codex within approved boundary |
| Routine persistence | Positive duration is copied into new Exercise SetPrescription values; OFF uses existing null semantics | The value is a one-time initialization and the Routine owns its saved value after insertion | Owner-approved contract |
| Active Workout path | Use the existing account-bound Save-only local draft and countdown | This is the existing Log Workout draft/recovery path; do not extend the legacy W7B session engine | Owner-approved contract |
| App Mode eligibility | Use AppMode.guidedDestinations containing AppDestination.workout | Keeps visibility and direct-route protection tied to canonical mode eligibility | Codex |

## 4. Architecture Design

### Chosen Approach

Workout owns one Default Rest Timer preference repository/controller. Its local SharedPreferences key includes the authenticated user ID; its provider lifetime is bound to the existing owner/login-cycle session identity. App composition injects the same controller into Settings and each approved Add Exercise path. New Exercise creation copies the current value into that Exercise’s existing Routine or Active Workout state; it does not subscribe to future preference changes.

### Ownership and Data Flow

Settings route → WorkoutRuntimeSettingsController → WorkoutRuntimeSettingsRepository → SharedPreferencesAsync
Routine Create/Edit Add Exercise → controller receives one-time RestTimerPreset → SetPrescription.restSeconds → existing Routine composition save
Log Workout Add Exercise → ActiveWorkoutDraftController.addExercises → ActiveWorkoutDraftExercise.restPreset/hasRestOverride → existing encrypted draft/recovery and countdown

### Alternative Rejected

Supabase/account sync is rejected because the owner classified this setting as device-local and no new schema is approved. A second wheel or countdown engine is rejected because the existing wheel and draft countdown already cover the behavior.

### Failure and Accessibility States

Show loading/error/save failure truthfully. A local preference read failure must not silently add an Exercise with an incorrect OFF value. Preserve Core row semantics, wheel accessibility, light/dark contrast, narrow width and large-text behavior.

## 5. Implementation Plan

- [x] Add Workout-owned settings domain, SharedPreferences repository and controller with validation, explicit OFF and owner-scoped storage.
- [x] Add Workout Settings page using TioAppBar, TioSettingsValueRow and showRoutineRestTimerSheet(hasWarmUpSets: false).
- [x] Add the mode-gated Settings entry and direct-route protection through the canonical AppMode capability.
- [x] Pass the current default into new Exercise initialization in Routine Create, Routine Edit and the Active Workout Save-only draft; preserve editable overrides.
- [x] Fix Routine explicit OFF application so SetPrescription values are cleared and remain OFF after Save/reopen, while untouched mixed legacy values stay intact.
- [x] Add focused repository/controller, Settings route/UI, Routine composition and Active Workout recovery/countdown tests.
- [x] Reconcile Settings, Workout Settings and Active Workout canonical screen docs.

## 6. Quality Review

### Validation Run

`git diff --cached --check` passed. `melos bootstrap` was attempted and failed before execution because `melos` is unavailable on PATH. Flutter/Dart analysis and tests could not run for the same missing toolchain. No device or visual QA is claimed.

### Acceptance Evidence (substantive scope)

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| App Mode visibility and Nutrition route protection | `settings_routes.dart`, `settings_page.dart` | New route and capability-gate widget tests added; not executed locally | Current branch head | Exact-head CI pending |
| Local-only persistence, unset/OFF and account isolation | Workout settings repository/controller | Owner-scoped SharedPreferences repository/controller tests added; not executed locally | Current branch head | Exact-head CI pending |
| Wheel reuse, cancel, OFF, duration, increments and maximum | Workout Settings page | Reuses existing wheel; save/cancel/OFF and compact/light/dark tests added; not executed locally | Current branch head | Exact-head CI pending |
| Routine Create/Edit Add Exercise and Save/reopen | Routine pages/controllers | Create and Edit snapshot/override/OFF tests added; Edit save/reopen covered; not executed locally | Current branch head | Exact-head CI pending |
| Active Workout Add Exercise, manual override, recovery and countdown | Active Workout page/draft controller | UI and draft recovery/countdown tests added; not executed locally | Current branch head | Exact-head CI pending |
| Existing Exercises and untouched mixed Routine values remain unchanged | Routine controllers and draft controller | Snapshot/update tests added; not executed locally | Current branch head | Exact-head CI pending |
| Theme, narrow layout and accessibility | Workout Settings page | Light/dark, compact width and text-scale test added; not executed locally | Current branch head | Device QA not run |

### Review Provenance

**Review source / link:** Local source/diff review; GitHub PR pending
**Reviewer / relation to implementer:** Codex implementer; self-review
**Diff or commit SHA actually reviewed:** `ea4f44b4ac6826ad46407934326bbcdead99aab3`
**Review result and finding IDs/dispositions:** Found and corrected Edit Routine handling that could overwrite untouched mixed legacy `restSeconds` on Save; added a regression test. No other source review findings identified.
**Independent review?** Unknown / unavailable
**Limitations and unmet required gates:** Flutter/Dart toolchain unavailable locally; exact-head CI and PR review pending; no device testing claimed.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | | | | |

## 7. Final Handoff

### Changed Files

See the branch diff. Runtime changes are in `apps/app`, `apps/core`, `apps/features/settings` and `apps/features/workout`; tests cover routing, Settings, Routine composition and Active Workout draft; canonical screen docs were updated.

### Actual Behavior

Default Rest Timer is an owner-scoped device-local preference. New Routine Create/Edit and Save-only Log Workout draft Exercises snapshot the current value once and remain editable. Explicit OFF stays OFF; changed defaults do not rewrite existing entries. No Supabase schema or network sync changed.

### Known Limitations

Broad W10 remains blocked by TNYX-78. Device behavior is not claimed unless physically tested. No schema or hosted Supabase change is in scope.

### Final Status

REVIEW — implementation and tests are present; local Flutter validation and exact-head PR CI remain outstanding.
