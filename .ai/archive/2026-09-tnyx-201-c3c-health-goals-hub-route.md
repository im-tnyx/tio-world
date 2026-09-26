# TNYX-201 C3c — Health & Goals Hub Route Registration Extraction

**Status:** Validated
**Primary owner:** apps/app routing composition
**Affected platforms:** Flutter phone app
**Completed:** 2026-09-26
**Tracker:** GitHub #395; parent #357 / #260; Linear TNYX-201

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner instructed `Follow agent.md @Linear @GitHub ... Go` on 2026-09-26 after the fresh post-C3b audit identified this bounded route-only seam.
**Approved product/UI/data-shape boundaries:** Move only `AppRoutes.healthGoalsSettings` registration from root `router.dart` into the existing app-owned `routing/routes/settings_routes.dart`, preserving route path, root navigator key and both navigation callbacks exactly.
**Explicit non-changes:** No Daily Wellness, Body & Weight, Measurement Units, Profile/Profile Avatar, Account Settings or Nutrition route move; no loading/error UI move; no repository/provider ownership change; no UI/layout/copy/theme, persistence, API, Supabase or schema change.

## Active Handoff

**Planning owner:** current C3c planning/reconciliation session
**Implementation owner:** None active; bounded source implementation is complete
**Review owner:** None active; exact-head review completed before merge
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** `main@8232a01db6109102c333e9c4022adf95479e958a` after PR #396 squash merge
**Branch:** source `tnyx/tnyx-201-c3c-health-goals-hub-route`; archive `tnyx/tnyx-201-c3c-archive`
**HEAD SHA:** exact reviewed final head `d5798a0801817c614828916371f376cdd2b8ea5d`; merged as `8232a01db6109102c333e9c4022adf95479e958a`
**Observed working-tree state:** Connector/API execution only; no local working tree is available to inspect
**Observed uncommitted/dirty files:** Not applicable / not observable from connector execution
**PR / tracker:** GitHub #395 / #357 / #260; Linear TNYX-201
**Current implementation state:** Health & Goals hub route registration moved into existing `settings_routes.dart`; root duplicate removed; downstream Daily Wellness and Body & Weight blocks untouched
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/settings_routes.dart`, existing `apps/app/test/app/app_mode_router_test.dart`
**Validation completed at SHA:** `d5798a0801817c614828916371f376cdd2b8ea5d` — Flutter CI #2811 full PASS; Commit attribution guard PASS; Attribution guard runner PASS; exact-head Codex review found no major issues; 0 unresolved review threads; exact PR diff trailing whitespace 0 and conflict markers 0; root Health & Goals registration 0, Settings module registration 1, root Daily Wellness 1, root Body & Weight 1, root `GoRouter(...)` 1, route-module `GoRouter(...)` 0
**Validation remaining:** None for C3c. Archive reconciliation is docs-only.
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** None for C3c. PR #396 is merged and this brief is archived; no next source slice is authorized by this archive.

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

- [x] add the existing Health & Goals hub registration to `settings_routes.dart`
- [x] remove only the duplicate root Health & Goals block
- [x] verify Daily Wellness and Body & Weight registrations remain root-owned
- [x] verify route/reference count and one-router authority
- [x] audit exact parent-to-head changed files
- [x] run exact-head CI/analyze/tests and whitespace validation
- [x] request independent review

## 6. Quality Review

### Validation Run

```text
Validated final reviewed head: d5798a0801817c614828916371f376cdd2b8ea5d
Flutter CI #2811: PASS
- Bootstrap workspace: PASS
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS
API ancestry/scope before merge: 7 ahead / 0 behind; exactly 4 owned paths
PR diff: trailing whitespace 0; conflict markers 0
Codex exact-head review: no major issues
Unresolved review threads: 0
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-c3c-health-goals-hub-route.md`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/routes/settings_routes.dart`

### Actual Behavior

Health & Goals opens the same `HealthGoalsSettingsPage` and navigates to the same Daily Wellness and Body & Weight destinations. Only route-registration ownership moved from root `router.dart` to the existing Settings route module.

### Known Limitations

Downstream Daily Wellness and Body & Weight route composition remains root-owned by design for a later ownership-safe slice.

### Final Status

`VALIDATED — MERGED VIA PR #396 (8232a01d)`


## Final Merge Validation

- exact final reviewed head: `d5798a0801817c614828916371f376cdd2b8ea5d`
- Flutter CI #2811 / run `36246855751`: full PASS
- Commit attribution guard: PASS
- Attribution guard runner: PASS
- final Codex review: no major issues
- unresolved review threads: 0
- exact PR diff: trailing whitespace 0; conflict markers 0
- non-required GHAS: failed before analysis because configured Copilot model returned `400 The requested model is not supported`; known TNYX-256 external outage, no code-scanning finding produced
- PR #396 squash-merged on 2026-09-26 as `8232a01db6109102c333e9c4022adf95479e958a`
- GitHub #395 closed as completed

## Archive Handoff

C3c is complete. Health & Goals navigation-hub route registration is now owned by the existing Settings route module. Daily Wellness and Body & Weight mixed route blocks remain intentionally root-owned for later ownership-safe work. A future source slice requires a fresh current-main audit and explicit owner authorization.
