# W10-A — Workout Settings Default Rest Timer

**Status:** In review
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
**Last commit SHA:** `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3` (`fix(flutter): inject workout settings storage`)
**Review owner:** Pending PR review
**Implementation ownership state:** Handoff pending
**Ownership transition:** Not applicable
**Repository state last verified:** Git root G:/projects/Tio-World; W10-A branch `tnyx/w10a-default-rest-timer` at `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`; `origin/main` is an ancestor, 0 behind / 6 ahead, and working tree clean at validation.
**Branch:** tnyx/w10a-default-rest-timer
**HEAD SHA:** `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3` (code and exact-head CI verified; task handoff update follows)
**Observed working-tree state:** Code branch clean at verified SHA; this handoff edit is in progress.
**Observed uncommitted/dirty files:** This task brief and `.ai/tasks/README.md` handoff index.
**PR / tracker:** [PR #753](https://github.com/im-tnyx/tio-world/pull/753) is open and unmerged at `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`. Linear TNYX-87 remains Backlog and blocked by TNYX-78 for broad W10; this is the owner-approved W10-A child slice. GitHub #48 remains open. Its 2026-10-29 note that Active Workout Add Exercise is unbuilt is superseded for this bounded slice by the 2026-11-12 owner clarification and existing Save-only draft contract from PR #740.
**Current implementation state:** Workout Settings and all three Add Exercise integrations are committed and exact-head CI passed. Routine OFF and Active Workout draft recovery contracts are wired. Independent review and device QA remain pending; PR is not merged.
**Relevant execution surface:** Settings root and /settings/workout; Routine Create/Edit Add Exercise; Active Workout Log Workout Save-only draft Add Exercise and recovery.
**Validation completed at SHA:** `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`: `git diff --check origin/main...HEAD` passed; Docs Hygiene CI run `43248535780`, Flutter CI run `43248535748`, and Android Native CI run `43248535717` all passed. Flutter CI passed `app-workout`, `nutrition-onboarding`, `core-wear`, and Analyze/Dart-test jobs; Android CI passed phone and Wear debug APK builds.
**Validation remaining:** Independent PR review and device QA. Local Flutter/Dart commands are unavailable; `melos bootstrap` was attempted and failed because `melos` is not on PATH.
**Current blocker:** Broad Linear W10 remains blocked by TNYX-78; this owner-approved W10-A child uses existing contracts and does not resolve that dependency. No source-level blocker found in the bounded audit.
**Open review finding IDs:** None yet.
**Next exact action:** Keep PR #753 open for independent review and device acceptance; do not merge without the owner's explicit direction.

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

- `git diff --check origin/main...HEAD` — PASS at `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`.
- Docs Hygiene CI run `43248535780` — PASS.
- Flutter CI run `43248535748` — PASS: `app-workout`, `nutrition-onboarding`, `core-wear`, Flutter/Dart analysis and Dart tests.
- Android Native CI run `43248535717` — PASS: phone and Wear debug APK builds.
- Local `melos bootstrap` — not run successfully; `melos` is unavailable on PATH, and Flutter/Dart are unavailable locally.
- Device QA — not run; no physical-device behavior is claimed.

### Acceptance Evidence (substantive scope)

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| App Mode visibility and Nutrition route protection | `settings_routes.dart`, `settings_page.dart` | Route and capability-gate widget tests passed in Flutter CI | `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`; hosted CI | Physical-device check not run |
| Local-only persistence, unset/OFF and account isolation | Workout settings repository/controller | Owner-scoped SharedPreferences repository/controller tests passed in Flutter CI | `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`; hosted CI | Local toolchain unavailable |
| Wheel reuse, cancel, OFF, duration, increments and maximum | Workout Settings page | Reuses existing wheel; save/cancel/OFF and compact/light/dark tests passed in Flutter CI | `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`; hosted CI | Device QA not run |
| Routine Create/Edit Add Exercise and Save/reopen | Routine pages/controllers | Create and Edit snapshot/override/OFF tests and Save/reopen passed in Flutter CI | `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`; hosted CI | None identified in tested scope |
| Active Workout Add Exercise, manual override, recovery and countdown | Active Workout page/draft controller | UI and draft recovery/countdown tests passed in Flutter CI | `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`; hosted CI | Physical-device countdown not checked |
| Existing Exercises and untouched mixed Routine values remain unchanged | Routine controllers and draft controller | Snapshot/update and mixed legacy-value regression tests passed in Flutter CI | `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`; hosted CI | None identified in tested scope |
| Theme, narrow layout and accessibility | Workout Settings page | Light/dark, compact width and text-scale tests passed in Flutter CI | `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`; hosted CI | Device QA not run |

### Review Provenance

**Review source / link:** Local source/diff review; GitHub PR pending
**Reviewer / relation to implementer:** Codex implementer; self-review
**Diff or commit SHA actually reviewed:** `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`
**Review result and finding IDs/dispositions:** Found and corrected Edit Routine handling that could overwrite untouched mixed legacy `restSeconds` on Save; added a regression test. No other source review findings identified.
**Independent review?** Unknown / unavailable
**Limitations and unmet required gates:** Independent PR review and device QA remain pending. CI passed for the verified source head; no device behavior is claimed.

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

REVIEW — implementation, tests and exact-head CI passed at `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`; PR #753 remains open and unmerged pending independent review and device QA.
