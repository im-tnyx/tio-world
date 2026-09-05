# TNYX-72 — Global Calendar Preferences: First day of week

**Status:** In progress
**Primary owner:** Settings / app composition
**Affected platforms:** Flutter phone app (`apps/app`, `apps/core`, `apps/features/settings`, `apps/features/nutrition`)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** TNYX-72 implementation prompt; tracker state verified as `Todo` before implementation.
**Approved product/UI/data-shape boundaries:** `Settings → App Preferences → Calendar → First day of week`; V1 values `monday` and `sunday`; Monday default; device-local persistence; app-global consumption; immediate apply; no Supabase sync.
**Explicit non-changes:** No Supabase mutation, migration, schema/RLS/grant/storage change, remote sync, TNYX-155 start, feature-specific week-start preferences, Workout/Meal Plan/Progress calendar work, merge, or Done status.

## Active Handoff

**Planning owner:** Claude / prior implementation session
**Implementation owner:** Codex
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Ownership transition:** Claude → Codex
**Repository state last verified:** 2026-09-05; `HEAD` and `origin/main` at `ce5f29e2e00fb92c266c52b05c55fb676e244406`; working tree already contained TNYX-72 changes.
**Branch:** `tnyx/tnyx-72-global-calendar-preferences-first-day-of-week`
**HEAD SHA:** `ce5f29e2e00fb92c266c52b05c55fb676e244406`
**Observed working-tree state:** Dirty, in-progress implementation; no task commit or PR commit on this branch.
**Observed uncommitted/dirty files:** Existing app routing/composition, Settings UI/tests, Nutrition constructor wiring, and new Calendar Preferences app/settings files.
**PR / tracker:** Commit/PR publication pending; tracker is currently `In Progress`.
**Current implementation state:** Settings domain/data/controller seam, app startup/provider routing, Calendar Settings UI, Meal Diary injection, Core visible-anchor reframe, focused tests, canonical docs and ADR are present and locally validated.
**Relevant execution surface:** `apps/features/settings`, `apps/app`, `apps/features/nutrition`, `apps/core`, `docs`, `.ai/tasks`.
**Validation completed at SHA:** Working tree based on `ce5f29e2e00fb92c266c52b05c55fb676e244406`; `git diff --check` passed; `main` and `origin/main` match; preserved `docs/supabase-android-studio-qa-run` resolves to `7fe896820c8f176b5049df4fe84fc9acea5933b1`; no Supabase TNYX-72 match found.
**Validation remaining:** No local validation remains; exact-head GitHub Actions and review are pending after PR publication.
**Current blocker:** None locally.
**Open review finding IDs:** None recorded.
**Next exact action:** Commit the reviewed TNYX-72 slice, push the feature branch, and open a non-draft PR for review.

## Global UI / Design-System Guardrail

This task follows `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md`. The Calendar Settings page uses the public `package:tio_core/core.dart` components; no new local token catalog or custom radio component is introduced.

## 1. Discovery

### User Outcome

Users can choose one app-wide first day of week from Settings and see every current calendar consumer use it immediately.

### Success Criteria

- Monday is the default and Sunday is the only alternative.
- The value is stored locally with a stable machine key and safe Monday fallback.
- Settings owns one preference; Nutrition only receives the resolved value.
- Meal Diary preserves selected date, range limits, visible-range reporting, and Today behavior when the value changes.
- Core locale fallback remains available when no resolved value is supplied.
- Tests and canonical docs describe the same local-only contract.

### Scope

Settings domain/data/presentation slice, app composition/provider/controller, `/settings/calendar` route and policy, Meal Diary injection, focused tests, task brief, Settings/Meal Diary/module ownership docs, and a Settings-local ADR if the existing ADR convention requires it.

### Non-Goals

Supabase, remote/account sync, database schema, backend APIs, feature-specific preferences, TNYX-155 cleanup, and future calendar consumers beyond the current Meal Diary seam.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: existing `SharedPreferencesAsync` Hydration Preferences repository, `AppThemeController`, `TioDateCalendar`, app route/policy/composition, App Preferences and Meal Diary.
- Existing pattern to follow: Settings-owned local repository; app-level controller/provider override; Core `TioDateCalendar.resolvedFirstDayOfWeek` nullable locale fallback; `TioSelectableCard` for selection UI.
- Tests or validation already present: Core has baseline first-day and runtime selection coverage; Settings and app tests were updated in the dirty worktree and freshly executed below.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| V1 values are Monday/Sunday only | Made | Locked product contract | TNYX-72 owner |
| Persistence is device-local | Made | Explicit implementation boundary; no Supabase work | TNYX-72 owner |
| Settings is the sole preference owner | Made | Prevents feature-specific calendar state | TNYX-72 owner |
| Core nullable locale fallback remains | Made | Reusable calendar API compatibility | Existing TNYX-55 contract |

## 4. Architecture Design

### Chosen Approach

Feature-first Settings slice under `apps/features/settings/lib/src/calendar_preferences/`, with app composition owning the reactive controller/provider and resolving the saved enum to `DateTime.monday` or `DateTime.sunday` before passing it to calendar consumers.

### Ownership and Data Flow

```text
Calendar Settings UI -> app CalendarPreferencesController -> Settings repository -> SharedPreferencesAsync
                                                        -> resolvedFirstDayOfWeek -> app composition -> MealDiaryPage -> TioDateCalendar
```

### Alternative Rejected

Per-feature week-start values, locale-only Settings behavior, a new storage service, and Supabase `user_app_preferences` persistence are outside the approved V1 contract.

### Failure and Accessibility States

Missing/unknown/corrupt storage falls back to Monday. Writes apply through the existing queued controller pattern; a write error remains visible through the Settings page's existing error presentation style. Options use the shared selectable-card semantics and adequate tappable surface.

## 5. Implementation Plan

- [x] Reconstruct current dirty implementation and record Claude → Codex takeover.
- [x] Verify and complete Settings domain/data/controller/provider and app startup wiring.
- [x] Verify and complete Calendar route, App Preferences entry, and Meal Diary injection.
- [x] Add focused repository, controller, Calendar Settings UI, app composition, and Core regression coverage.
- [x] Update canonical Settings/Meal Diary/module ownership documentation and add the local-preference ADR.
- [x] Run focused and full applicable validation; refresh this brief with exact evidence.

## 6. Quality Review

### Validation Run

```text
Static checks:
- `git diff --check` — PASS.
- `main` == `origin/main` at `ce5f29e2e00fb92c266c52b05c55fb676e244406` — PASS using existing local refs.
- Preserved `docs/supabase-android-studio-qa-run` remains at `7fe896820c8f176b5049df4fe84fc9acea5933b1` — PASS.
- Flutter `3.44.6` / Dart `3.12.2` from `G:\dev\flutter-sdk` — PASS.
- Melos `2.9.0` from task-local `PUB_CACHE` — PASS; shared `G:\dev\pub-cache` was not overwritten.
- `melos bootstrap` — PASS; 16 packages bootstrapped.
- `melos exec -c 1 --flutter --fail-fast -- "flutter analyze --no-pub"` — PASS; package analyses reported no issues.
- `melos exec -c 1 --no-flutter --fail-fast -- "dart analyze ."` — PASS; `tio_shared` reported no issues.
- `melos exec -c 1 --flutter --dir-exists=test --fail-fast -- "flutter pub get && flutter test --no-pub"` — PASS; final exit code `0`.
- `melos exec -c 1 --no-flutter --dir-exists=test --fail-fast -- "dart test"` — PASS; 38 tests passed.
- Focused Settings suite — PASS; 32 tests passed.
- Focused app suite — PASS; 29 tests passed.
- Focused Core calendar suite — PASS; 45 tests passed.
- Focused Nutrition Meal Diary suite — PASS; 22 tests passed.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-72-global-calendar-preferences.md`
- `apps/app` calendar controller/provider, startup hydration, routing/policy and app integration tests
- `apps/core` calendar visible-anchor behavior and regression tests
- `apps/features/settings` Calendar Preferences domain/data/presentation and Settings entry/tests
- `apps/features/nutrition` Meal Diary resolved week-start forwarding
- `docs/screens/settings.md`, `docs/screens/meal-diary.md`, `docs/MODULE_OWNERSHIP.md`, `docs/adr/README.md`, `docs/adr/0010-settings-local-calendar-first-day-of-week.md`
- `.ai/tasks/tnyx-55-core-date-calendar-meal-diary.md` stale decision reconciliation

### Actual Behavior

V1 exposes Monday (default) and Sunday at `Settings → App Preferences → Calendar → First day of week`. The saved value is device-local, resolved app-wide to `DateTime.monday` or `DateTime.sunday`, and forwarded to Meal Diary/Core without Nutrition-owned persistence. Core preserves the visible anchor when week-start changes, recalculates the visible range, retains selected-date/range ownership, and keeps its nullable locale fallback.

### Known Limitations

Flutter/Dart/Melos validation passed on the locally available SDK/toolchain. Remote fetch was not required for this implementation pass; no Supabase or remote state was changed. No commit, push, PR, Linear status update, merge, or Done transition was performed.

### Final Status

`PASS`
