# TNYX-201 C3d — Profile Settings Route Registration Extraction

**Status:** In progress
**Primary owner:** apps/app routing composition
**Affected platforms:** Flutter phone app
**Tracker:** GitHub #398; parent #357 / #260; Linear TNYX-201

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner instructed `Follow agent.md @Linear @GitHub ... Go` on 2026-09-26 after the fresh post-C3c audit identified this bounded route-only seam.
**Approved product/UI/data-shape boundaries:** Move only `AppRoutes.profileSettings` registration from root `router.dart` into a new app-owned `routing/routes/profile_routes.dart`, preserving path, root navigator key, and destination widget exactly.
**Explicit non-changes:** No `AppRoutes.profile` or `AppRoutes.profileAvatar` move; no `ProfileSettingsRoute` internals; no profile completion/reminder or avatar workflow changes; no cropper work; no Measurement Units, Account, Nutrition, Wellness or Body route changes; no UI/layout/copy/theme, persistence, API, Supabase or schema changes.

## Active Handoff

**Planning owner:** current C3d planning/reconciliation session
**Implementation owner:** current C3d implementation session
**Review owner:** None yet
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub/API at `main@a23bb6bbbd0ca9043dc626b12b9af4f3b9fb88de`
**Branch:** `tnyx/tnyx-201-c3d-profile-settings-route`
**HEAD SHA:** `744891a8f6d51a777c9782cd89863521b9aad1b4` source-implementation checkpoint before this handoff update
**Observed working-tree state:** Connector/API execution only; no local working tree is available to inspect
**Observed uncommitted/dirty files:** Not applicable / not observable from connector execution
**PR / tracker:** GitHub #398 / #357 / #260; Linear TNYX-201
**Current implementation state:** Profile Settings registration moved into new `profile_routes.dart`; root duplicate/direct import removed; Profile/Profile Avatar routes untouched
**Relevant execution surface:** `apps/app/lib/app/router.dart`, new `apps/app/lib/app/routing/routes/profile_routes.dart`, existing `apps/app/lib/app/profile/profile_settings_route.dart`, route/profile tests
**Validation completed at SHA:** `744891a8f6d51a777c9782cd89863521b9aad1b4` API scope/invariant audit: 4 ahead / 0 behind, exactly 4 owned paths; root Profile Settings registration 0, profile module registration 1, root Profile 1, root Profile Avatar 1, root `GoRouter(...)` 1, route-module `GoRouter(...)` 0, no trailing-whitespace/conflict findings; moved `GoRoute` equivalent ignoring indentation
**Validation remaining:** exact PR diff audit, exact-head Flutter CI/analyze/tests, independent review
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Open focused Draft PR, validate exact-head CI/diff/review, then reconcile review state

## Global UI / Design-System Guardrail

This slice changes no production UI. Existing `ProfileSettingsRoute` rendering, loading/error states, Profile Settings presentation, copy, geometry, theme and interactions must remain identical.

## 1. Discovery

### User Outcome

Continue router modularization by giving the already-encapsulated Profile Settings route an ownership-based route module without touching Profile/avatar workflows.

### Success Criteria

- `AppRoutes.profileSettings` is registered by `buildProfileRoutes(...)`.
- Root `router.dart` no longer directly registers Profile Settings.
- Destination remains `const ProfileSettingsRoute()`.
- `AppRoutes.profile` and `AppRoutes.profileAvatar` remain root-owned and unchanged.
- Route path and `rootNavigatorKey` semantics are unchanged.
- Exactly one root `goRouterProvider` / `GoRouter(...)` authority remains.
- Existing Profile Settings navigation and wrapper tests remain green.
- No visible UI, persistence, API or Supabase behavior changes.

### Scope

One route registration block plus the minimum route-module/import plumbing.

### Non-Goals

Profile page; Profile Avatar page; Profile Settings internals; profile completion/reminder; avatar upload/delete/crop; GitHub #201/TNYX-150; Measurement Units; Account; Nutrition; Wellness; Body; UI redesign; persistence/API/Supabase/schema changes.

## 2. Codebase Exploration

### Verified Evidence

- Read root `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/TEMPLATE.md`, `docs/PUSH_TEMPLATE.md`, PR template, GitHub #260/#357/#398, Linear TNYX-201, current source and focused tests.
- Current base: `main@a23bb6bbbd0ca9043dc626b12b9af4f3b9fb88de`.
- No open PR overlaps this route slice.
- No nested `apps/app/AGENTS.md` exists.
- `router.dart` currently registers `AppRoutes.profileSettings` only as `const ProfileSettingsRoute()`.
- `ProfileSettingsRoute` already owns app-side hydration/composition and its own focused tests.
- Historical validated Profile Settings handoff explicitly records that `router.dart` only registers this route component.
- `AppRoutes.profile` and `AppRoutes.profileAvatar` remain mixed with completion/avatar workflow and are deliberately deferred.
- Open GitHub #201 / Linear TNYX-150 overlaps avatar/cropper behavior, so avatar routes/workflow must not be pulled into C3d.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Move Profile Settings registration only | Chosen | Pure route registration; destination composition already encapsulated | Owner + current audit |
| Move Profile + Profile Avatar too | Rejected | Mixed completion/avatar workflow and open cropper overlap | Current audit + #201 |
| Move Profile Settings internals into routing module | Rejected | Would make routing own Profile workflow/presentation composition | #357 ownership rule |

## 4. Architecture Design

### Chosen Approach

Add `routing/routes/profile_routes.dart` with `buildProfileRoutes({required rootNavigatorKey})`, containing only the existing Profile Settings `GoRoute`. Root `router.dart` assembles the route group.

### Ownership and Data Flow

`router.dart` → `buildProfileRoutes(...)` → `const ProfileSettingsRoute()` → existing Profile app composition + feature presentation/domain owners

### Alternative Rejected

Broad Profile extraction. It would combine pure registration cleanup with unresolved avatar/completion workflow ownership.

### Failure and Accessibility States

No failure/loading/accessibility/UI behavior changes. Existing `ProfileSettingsRoute` owns those states unchanged.

## 5. Implementation Plan

- [x] add `profile_routes.dart` with the existing registration
- [x] assemble `buildProfileRoutes(...)` in root router
- [x] remove only root Profile Settings block and obsolete direct import
- [x] verify Profile/Profile Avatar registrations remain root-owned
- [x] verify one-router authority and route reference count
- [x] audit exact parent-to-head changed files
- [ ] run exact-head CI/analyze/tests and diff validation
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

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-c3d-profile-settings-route.md`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/routes/profile_routes.dart`

### Actual Behavior

`AppRoutes.profileSettings` still resolves through the same `rootNavigatorKey` to the same `const ProfileSettingsRoute()`. Only route-registration ownership moved; Profile and Profile Avatar composition remain unchanged.

### Known Limitations

Profile and Profile Avatar route composition stays root-owned by design for later ownership-safe work.

### Final Status

`REVIEW` — bounded implementation is complete; exact-head CI/review remain.
