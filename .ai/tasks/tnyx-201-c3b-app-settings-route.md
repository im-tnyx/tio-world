# TNYX-201 C3b — App Settings Hub Route Registration Extraction

**Status:** In progress
**Primary owner:** apps/app routing composition
**Affected platforms:** Flutter phone app
**Tracker:** GitHub #392; parent #357 / #260; Linear TNYX-201

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** After C3a merge/archive and the fresh next-slice audit, the owner instructed “Go” on 2026-09-26.
**Approved product/UI/data-shape boundaries:** Move only `AppRoutes.appSettings` registration from root `router.dart` into the existing app-owned `routing/routes/settings_routes.dart`, preserving current state/callback/navigation behavior.
**Explicit non-changes:** No Measurement Units, Profile, Profile Avatar, Profile Settings, Nutrition, Wellness, Body or Account route move; no UI, controller/repository ownership, persistence, API, Supabase, schema or navigation redesign.

## Active Handoff

**Planning owner:** current C3b planning/reconciliation session
**Implementation owner:** current C3b implementation session
**Review owner:** Unassigned until implementation checkpoint
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub/API at `main@ff1a37086cf98d9ce08a14b6e5514e199f91d7e1`
**Branch:** `tnyx/tnyx-201-c3b-app-settings-route`
**HEAD SHA:** `ff1a37086cf98d9ce08a14b6e5514e199f91d7e1` before task-brief commit
**Observed working-tree state:** Connector/API execution only; no local working tree claimed
**Observed uncommitted/dirty files:** Not applicable / not observable from connector execution
**PR / tracker:** GitHub #392 / #357 / #260; Linear TNYX-201
**Current implementation state:** Not started; scope frozen to App Settings hub registration only
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/settings_routes.dart`
**Validation completed at SHA:** None for C3b
**Validation remaining:** exact-head Flutter CI, route/reference audit, one-router audit, review-thread audit
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Add the App Settings route to `buildSettingsRoutes(...)`, remove its duplicate root registration, then validate exact behavior-preserving scope.

## 1. Discovery

### User Outcome

Continue router modularization without moving mixed feature workflow/presentation behavior into routing modules.

### Success Criteria

- `AppRoutes.appSettings` is registered by `settings_routes.dart`.
- Root router no longer directly registers the App Settings hub.
- App Mode, Theme, Calendar and Measurement Units navigation behavior remains identical.
- One root `goRouterProvider` / `GoRouter(...)` remains.
- No visible or persistence behavior changes.

### Scope

Only the App Settings hub route registration.

### Non-Goals

Measurement Units; Profile/Profile Avatar/Profile Settings; Nutrition; Wellness; Body; Account; controller/repository ownership; UI; persistence/API/Supabase/schema.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, #260, #357, TNYX-201, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/README.md`, `docs/ARCHITECTURE.md`, `docs/MODULE_OWNERSHIP.md`, current `router.dart`, current `settings_routes.dart`.
- Current base: `main@ff1a37086cf98d9ce08a14b6e5514e199f91d7e1`.
- `router.dart`: 1252 lines; one root `GoRouter(...)`; one `goRouterProvider`.
- Existing `settings_routes.dart` already owns Settings root, App Mode, Calendar and Theme registration.
- Profile route block is intentionally deferred because it mixes completion reminder, avatar presentation and avatar persistence workflow.
- Measurement Units is intentionally deferred because its route currently includes Profile-backed loading and persistence composition.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Extract whole Profile block next | Rejected | Mixed feature workflow/presentation/persistence; #260/#357 require classification first | C3b audit |
| Move Measurement Units with App Settings | Rejected | It carries load/save composition beyond the stable hub route boundary | C3b audit |
| Move only App Settings hub | Chosen | Stable Settings-owned route composition with existing dependencies already present in `settings_routes.dart` | C3b audit |

## 4. Architecture Design

### Chosen Approach

Extend `buildSettingsRoutes(...)` with the existing App Settings hub `GoRoute`. Keep root `router.dart` as the sole `GoRouter` owner and continue injecting app-owned controllers/state through the builder.

### Ownership and Data Flow

`router.dart` -> `buildSettingsRoutes(...)` -> Settings feature pages/callbacks

### Alternative Rejected

A broad Profile/Settings/Measurement Units extraction was rejected because it would hide unresolved feature ownership and loading/persistence responsibilities inside a route module.

### Failure and Accessibility States

No failure/accessibility behavior changes. Existing App Settings behavior is moved verbatim.

## 5. Implementation Plan

- [ ] add existing App Settings route registration to `settings_routes.dart`
- [ ] remove only the duplicate root App Settings route block
- [ ] audit imports and route references
- [ ] verify one-router authority
- [ ] run exact-head CI
- [ ] independent review and tracker reconciliation

## 6. Quality Review

### Validation Run

`Not run yet.`

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Pending validation.

### Known Limitations

Profile and Measurement Units mixed ownership/composition remain intentionally deferred.

### Final Status

`REVIEW`
