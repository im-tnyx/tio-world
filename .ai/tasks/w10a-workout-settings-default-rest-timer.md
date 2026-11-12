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
**Implementation owner:** ChatGPT — owner-directed P2 remediation on existing PR #753
**Previous agent:** Codex (initial W10-A implementation)
**Last commit agent:** Codex — W10-A implementation commit
**Last commit SHA:** `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3` (`fix(flutter): inject workout settings storage`)
**Review owner:** i-the — CHANGES_REQUESTED on PR #753 at `f9824d855e1a88ae9031a675d02c3ce081094f2d`; re-review pending
**Implementation ownership state:** Owner-directed handoff to ChatGPT for reviewer P2 only; no parallel implementation owner
**Ownership transition:** Codex → ChatGPT for exact existing-review fix requested 2026-11-12
**Repository state last verified:** Git root G:/projects/Tio-World; code branch `tnyx/w10a-default-rest-timer` passed exact-head CI at `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`. Its task-handoff follow-up at `fd07da4d6c6f17e885fdb2bb555720a2d59a7dec` also passed all workflow checks; `origin/main` was an ancestor and the tree was clean at both checkpoints.
**Branch:** tnyx/w10a-default-rest-timer
**Latest fully validated PR checkpoint:** `fd07da4d6c6f17e885fdb2bb555720a2d59a7dec` (seven commits ahead of `origin/main`; Flutter, Android and Docs Hygiene CI passed). This follow-up modifies only the task handoff record.
**Observed working-tree state:** Clean on the verified checkpoint; this final task-file metadata correction is docs-only.
**Observed uncommitted/dirty files:** This task brief only, while preparing the final handoff record.
**PR / tracker:** [PR #753](https://github.com/im-tnyx/tio-world/pull/753) is open and unmerged; the most recent fully validated PR checkpoint is `fd07da4d6c6f17e885fdb2bb555720a2d59a7dec`. Linear TNYX-87 remains Backlog and blocked by TNYX-78 for broad W10; this is the owner-approved W10-A child slice. GitHub #48 remains open. Its 2026-10-29 note that Active Workout Add Exercise is unbuilt is superseded for this bounded slice by the 2026-11-12 owner clarification and existing Save-only draft contract from PR #740.
**Current implementation state:** Workout Settings and all three Add Exercise integrations are committed and exact-head CI passed. Routine OFF and Active Workout draft recovery contracts are wired. Independent review and device QA remain pending; PR is not merged.
**Relevant execution surface:** Settings root and /settings/workout; Routine Create/Edit Add Exercise; Active Workout Log Workout Save-only draft Add Exercise and recovery.
**Validation completed at SHA:** `fd07da4d6c6f17e885fdb2bb555720a2d59a7dec`: `git diff --check origin/main...HEAD` passed; Docs Hygiene CI run `43250182500`, Flutter CI run `43250182673`, and Android Native CI run `43250182890` all passed. Flutter CI passed `app-workout`, `nutrition-onboarding`, `core-wear`, and Analyze/Dart-test jobs; Android CI passed phone and Wear debug APK builds. The source implementation was already green at `cffd120fe2f88ab945c8c332f29b5f1a86dfc8f3`.
**Validation remaining:** Independent PR review and device QA. Local Flutter/Dart commands are unavailable; `melos bootstrap` was attempted and failed because `melos` is not on PATH.
**Current blocker:** Broad Linear W10 remains blocked by TNYX-78; this owner-approved W10-A child uses existing contracts and does not resolve that dependency. No source-level blocker found in the bounded audit.
**Open review finding IDs:** `#discussion_r4552874935` / `4552874935` (P2 failed-read retry and Settings error UI; resolution pending independent re-review).
**Next exact action:** Commit the bounded read-failure retry and UI/test remediation on the existing PR branch, then obtain exact-head CI and independent re-review. Do not merge.

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

REVIEW — implementation, tests and exact-head CI passed through `fd07da4d6c6f17e885fdb2bb555720a2d59a7dec`; PR #753 remains open and unmerged pending independent review and device QA.

## 2026-11-12 Reviewer P2 remediation (owner-directed)

- **Prior PR head:** `f9824d855e1a88ae9031a675d02c3ce081094f2d`.
- **Review evidence:** [P2 discussion](https://github.com/im-tnyx/tio-world/pull/753#discussion_r4552874935), independent `i-the` review `CHANGES_REQUESTED`.
- **Root cause:** a failed device-local read left `_loadFuture` cached; subsequent `load()` calls could not retry, and the Settings screen rendered an indefinite spinner because `!isLoaded` was checked before error.
- **Remediation:** clear completed load future on completion; preserve error state for truthful display; show an accessible Retry action with existing `TioButton.secondary`; add controller/widget failure-then-success tests.
- **Regression boundary:** existing Create/Edit Routine and Log Workout Add Exercise behavior must remain unchanged except that another attempt after a transient storage read failure can now recover. Existing OFF/value tests and all three flow suites must pass on the new PR head.
- **Current validation:** Source-only code/test edits prepared; no local Flutter/Dart toolchain available in this environment. Exact new-head CI is required and not yet claimed. Device QA and independent reviewer acceptance remain outstanding.
- **No scope expansion:** no Supabase/schema, new branch/PR, unrelated Workout Settings option, UI redesign, release, or merge.
