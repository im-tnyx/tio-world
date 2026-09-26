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
**HEAD SHA:** `a0ddad620a70938956996893f0a5cfc64c76730f` source implementation checkpoint before this task update
**Observed working-tree state:** Connector/API execution only; no local working tree claimed
**Observed uncommitted/dirty files:** Not applicable / not observable from connector execution
**PR / tracker:** GitHub #392 / #357 / #260; Linear TNYX-201
**Current implementation state:** App Settings hub registration moved verbatim into existing `settings_routes.dart`; root duplicate removed
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/settings_routes.dart`
**Validation completed at SHA:** None for C3b
**Validation remaining:** exact-head Flutter CI, independent review, review-thread audit
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Open focused PR, run exact-head CI, then independently review diff/threads before merge.

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

- [x] add existing App Settings route registration to `settings_routes.dart`
- [x] remove only the duplicate root App Settings route block
- [x] audit imports and route references
- [x] verify one-router authority
- [ ] run exact-head CI
- [ ] independent review and tracker reconciliation

## 6. Quality Review

### Validation Run

Implementation checkpoint before CI:

- base: `main@ff1a37086cf98d9ce08a14b6e5514e199f91d7e1`
- source checkpoint: `a0ddad620a70938956996893f0a5cfc64c76730f`
- compare: 4 commits ahead / 0 behind
- exactly 4 owned paths: task brief, task index, `router.dart`, `settings_routes.dart`
- source delta: 28 lines removed from root + same 28 lines added to Settings route builder
- root `AppRoutes.appSettings` references: 1 (chrome-policy list only)
- `settings_routes.dart` `AppRoutes.appSettings` references: 2 (Settings navigation callback + route registration)
- root `GoRouter(...)`: 1
- route-module `GoRouter(...)`: 0
- root `goRouterProvider`: 1
- `buildSettingsRoutes(...)` root assembly calls: 1

Exact-head Flutter CI has not run yet.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-c3b-app-settings-route.md`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/routes/settings_routes.dart`

### Actual Behavior

Expected behavior is unchanged: App Settings still reads current App Mode, Theme and Calendar preference state and navigates to the same App Mode, Measurement Units and Calendar destinations. Only registration ownership moved to the existing Settings route module; exact-head CI/review remains required.

### Known Limitations

Profile and Measurement Units mixed ownership/composition remain intentionally deferred.

### Final Status

`REVIEW`
