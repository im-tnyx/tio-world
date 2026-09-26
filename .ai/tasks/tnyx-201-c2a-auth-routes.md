# TNYX-201 C2a — Auth Route Group Extraction

**Status:** In progress
**Primary owner:** apps/app routing composition
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Approval status:** Approved
**Approval evidence:** Owner said “Go next” after C1 merge/archive and fresh C2 ownership audit.
**Approved boundary:** Auth/pre-auth route composition extraction only.
**Explicit non-changes:** No auth/session behavior redesign; no Account Setup or Product Onboarding extraction; no redirect/bootstrap change; no route/path/UI/provider/persistence/Supabase change.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned
**Implementation ownership state:** Active
**Repository state last verified:** `main@cb9c3845be0889ca3f56894123286834a1219d1f` after C1 archive PR #379.
**Branch:** `tnyx/tnyx-201-c2a-auth-routes`
**HEAD SHA:** source checkpoint `49e86352d2dcec5d7420b084e80c40aebbccf6f8`; subsequent handoff update is documentation-only.
**PR / tracker:** Linear TNYX-201; GitHub #260; router parent #357; C2a child #380.
**Current blocker:** None.
**Next exact action:** Open Draft PR, run exact-head CI, then complete scope/whitespace/review audit.

## 1. Discovery

### Scope

Move route composition for:

- `AppRoutes.auth`
- `AppRoutes.appModeSetup`
- `AppRoutes.login`
- `AppRoutes.emailLogin`
- `AppRoutes.emailSignup`
- `AppRoutes.forgotPassword`

### Non-goals

- Splash remains root-owned.
- Account Setup / username setup remain root-owned for C2b classification.
- Product Onboarding / congratulations remain root-owned for C2b classification.
- No feature or domain behavior change.

## 2. Codebase Exploration

- C1 is merged/archived; root router is 1461 lines at current main.
- #357 recommends Auth/Account/Onboarding for C2, but Account Setup and Onboarding contain larger completion/session workflows, so C2 is split into reviewable C2a/C2b.
- Auth/pre-auth routes are composition glue: page selection, provider injection, navigation callbacks and backend-user-state handoff.
- `clearGlassSizeForNewExplicitLogin` remains root/session composition and is injected as a callback.
- `PendingAppModePreference` remains root-lifecycle state shared with later Account Setup and is injected into the route module.

## 3. Architecture Design

```text
apps/app/lib/app/routing/
├─ shell/shell_route.dart
└─ routes/auth_routes.dart

apps/app/lib/app/router.dart  # single GoRouter owner/assembly
```

`auth_routes.dart` returns route registrations only and constructs no `GoRouter`.

## 4. Implementation Plan

- [x] create `routing/routes/auth_routes.dart`
- [x] move exactly six Auth/pre-auth GoRoutes
- [x] inject root navigator key, pending mode preference and explicit-login callback
- [x] preserve backend-user-state assignment and auth providers
- [x] replace inline block with spread route-group factory
- [x] keep Account Setup/Onboarding untouched
- [x] audit route/reference preservation
- [ ] obtain exact-head CI
- [ ] whitespace/conflict audit
- [ ] reconcile review handoff

## 5. Quality Review

Source checkpoint `49e86352`; exact-head GitHub CI pending. Static audit: exact four-file scope, base ancestor, all six Auth route reference counts preserved, one root `goRouterProvider` / `GoRouter(...)`, zero `GoRouter(...)` constructions in `auth_routes.dart`.

## 6. Final Handoff

### Changed files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-c2a-auth-routes.md`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/routes/auth_routes.dart`

### Source checkpoint

- base: `main@cb9c3845be0889ca3f56894123286834a1219d1f`
- source checkpoint: `49e86352d2dcec5d7420b084e80c40aebbccf6f8`
- exact branch scope: four C2a-owned files
- `router.dart`: 1461 → 1351 lines
- new Auth route module: 135 source lines
- six Auth/pre-auth route reference counts unchanged vs base
- Account Setup / Onboarding route source unchanged

### Final status

`IMPLEMENTED — VALIDATION PENDING`
