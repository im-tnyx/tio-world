# TNYX-201 C3c — Health & Goals Hub Route Registration Extraction

**Status:** In progress
**Primary owner:** apps/app routing composition
**Affected platforms:** Flutter phone app
**Tracker:** GitHub #395; parent #357 / #260; Linear TNYX-201

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner instructed `Follow agent.md @Linear @GitHub ... Go` on 2026-09-26 after the fresh post-C3b audit identified this bounded route-only seam.
**Approved product/UI/data-shape boundaries:** Move only `AppRoutes.healthGoalsSettings` registration from root `router.dart` into the existing app-owned `routing/routes/settings_routes.dart`, preserving route path, root navigator key and both navigation callbacks exactly.
**Explicit non-changes:** No Daily Wellness, Body & Weight, Measurement Units, Profile/Profile Avatar, Account Settings or Nutrition route move; no loading/error UI move; no repository/provider ownership change; no UI/layout/copy/theme, persistence, API, Supabase or schema change.

## Active Handoff

**Planning owner:** current C3c planning/reconciliation session
**Implementation owner:** current C3c implementation session
**Review owner:** None yet
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub/API at `main@ee649c6d404337a248072e3ab3040e5b84c2dadc`
**Branch:** `tnyx/tnyx-201-c3c-health-goals-hub-route`
**HEAD SHA:** branch created from `ee649c6d404337a248072e3ab3040e5b84c2dadc`; task brief is the first branch mutation
**Observed working-tree state:** Connector/API execution only; no local working tree is available to inspect
**Observed uncommitted/dirty files:** Not applicable / not observable from connector execution
**PR / tracker:** GitHub #395 / #357 / #260; Linear TNYX-201
**Current implementation state:** Planning and tracker activation complete; source not yet mutated
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/settings_routes.dart`, existing `apps/app/test/app/app_mode_router_test.dart`
**Validation completed at SHA:** Fresh current-main read-only route/reference/ownership audit only
**Validation remaining:** parent-to-head scope audit, `git diff --check` equivalent, exact-head Flutter CI/analyze/tests, independent review
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Move the single Health & Goals hub `GoRoute` verbatim into `buildSettingsRoutes(...)`, then validate the exact branch head

## Global UI / Design-System Guardrail

This slice makes no production UI change. Existing `HealthGoalsSettingsPage` rendering, copy, geometry, styling and interaction behavior must remain identical.

## 1. Discovery

### User Outcome

Continue router modularization while keeping Settings navigation composition in the existing Settings route module and leaving mixed feature data/presentation routes visible for later ownership work.

### Success Criteria

- `AppRoutes.healthGoalsSettings` is registered by `buildSettingsRoutes(...)`.
- Root `router.dart` no longer directly registers the Health & Goals hub.
- Daily Wellness and Body & Weight route registrations remain root-owned and unchanged.
- Route path, `rootNavigatorKey`, and both `context.push(...)` callbacks are unchanged.
- Exactly one root `goRouterProvider` / `GoRouter(...)` authority remains.
- No visible UI, persistence, API or Supabase behavior changes.

### Scope

One route registration block only.

### Non-Goals

Daily Wellness; Body & Weight; Measurement Units; Profile/Profile Avatar; Account Settings; Nutrition routes; route-local loading/error presentation; feature/domain ownership changes; UI redesign; persistence/API/Supabase/schema changes.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/README.md`, `docs/ARCHITECTURE.md`, `docs/MODULE_OWNERSHIP.md`, `docs/PUSH_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE.md`, GitHub #260/#357, Linear TNYX-201/TNYX-155/TNYX-154, current `router.dart`, current `settings_routes.dart`, and route tests.
- Current base: `main@ee649c6d404337a248072e3ab3040e5b84c2dadc`.
- Existing pattern: C3a/C3b already place Settings-owned navigation/preferences registrations in `buildSettingsRoutes(...)`.
- Current Health & Goals block is pure route/navigation composition: page mounting plus callbacks to Daily Wellness and Body & Weight.
- `TNYX-155` freezes Settings-owned navigation/category hubs while Body/Wellness domain truth remains with canonical owners.
- `Daily Wellness` and `Body & Weight` blocks contain loading/error UI, repository writes and provider invalidation, so they are explicitly deferred.
- Existing `app_mode_router_test.dart` covers Settings → Health & Goals route navigation and downstream entry behavior.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Move Health & Goals hub only | Chosen | Pure Settings navigation composition and matches existing route-module ownership | Owner + current audit |
| Move Daily Wellness / Body & Weight with it | Rejected | Mixed presentation/data/persistence composition; would hide unresolved ownership | Current audit + #357 |
| Create a new route module | Rejected | Existing `settings_routes.dart` already owns the matching Settings navigation group | Current audit |

## 4. Architecture Design

### Chosen Approach

Append the existing Health & Goals `GoRoute` to `buildSettingsRoutes(...)` and remove the duplicate root block. Preserve its exact route path, navigator key and callbacks.

### Ownership and Data Flow

`router.dart` → `buildSettingsRoutes(...)` → `HealthGoalsSettingsPage` → existing Daily Wellness / Body & Weight paths

### Alternative Rejected

Moving the downstream feature editor routes now. Their mixed responsibilities require separate ownership classification and must not be hidden inside the Settings route module.

### Failure and Accessibility States

No failure, loading, accessibility or visible presentation behavior changes in this slice.

## 5. Implementation Plan

- [ ] add the existing Health & Goals hub registration to `settings_routes.dart`
- [ ] remove only the duplicate root Health & Goals block
- [ ] verify Daily Wellness and Body & Weight blocks are unchanged
- [ ] verify route/reference count and one-router authority
- [ ] audit exact parent-to-head changed files
- [ ] run exact-head CI/analyze/tests and whitespace validation
- [ ] request independent review

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

Downstream Daily Wellness and Body & Weight route composition remains root-owned by design for a later ownership-safe slice.

### Final Status

`PARTIAL` — implementation and exact-head validation pending.
