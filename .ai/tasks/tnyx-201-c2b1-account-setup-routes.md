# TNYX-201 C2b1 — Account Setup Route Extraction

**Status:** In progress
**Primary owner:** apps/app routing composition
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Approval status:** Approved
**Approval evidence:** Owner said “Go next” after C2a merge/archive and fresh C2b ownership audit.
**Approved boundary:** Account Setup route composition only.
**Explicit non-changes:** No Product Onboarding route/workflow extraction; no `AppOnboardingController` change; no TNYX-202/#261 package cleanup; no Auth/session redesign; no Account Setup UI/domain/provider/persistence/Supabase change.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned
**Implementation ownership state:** Active
**Repository state last verified:** `main@edc86745aa28ce631ad11be0399bc87ee3fbc127` after C2a archive PR #382.
**Branch:** `tnyx/tnyx-201-c2b1-account-setup-routes`
**HEAD SHA:** source checkpoint `764e182586072fc5ee18e2d460c6198aa7eeee4b`; subsequent handoff update is documentation-only.
**PR / tracker:** Linear TNYX-201; GitHub #260; router parent #357; C2b1 child #383; TNYX-202/#261 explicitly separate.
**Current blocker:** None.
**Next exact action:** Open Draft PR, run exact-head CI, then complete scope/whitespace/review audit.

## 1. Discovery

### Scope

- `AppRoutes.accountSetup` route registration/page composition
- `AppRoutes.usernameSetup` compatibility redirect

### Root-owned lifecycle callbacks

Keep implementation in `router.dart` and inject:

- Account Setup exit → sign out/session clear + bootstrap refresh
- Account Setup completion → apply/clear pending App Mode + Profile invalidation + bootstrap refresh

### Non-goals

- Product Onboarding route / congratulations route
- `AppOnboardingController`
- TNYX-202 / GitHub #261
- account setup feature behavior/UI
- root redirects/bootstrap ownership

## 2. Codebase Exploration

- Root `AGENTS.md`, canonical architecture/ownership docs, workflow, feature-development and push/PR guidance refreshed.
- C2a merged as PR #381 (`646d3e9a`) and archived by #382 (`edc86745`).
- Fresh current-main audit classifies Account Setup route composition as APP COMPOSITION.
- Current Product Onboarding route is SPLIT RESPONSIBILITY and is explicitly excluded.
- `AccountSetupFlowPage`, `accountSetupRepositoryProvider` and Account Setup feature imports are used by the scoped route block only.
- Existing `profileAccountRepositoryProvider`, Auth/session providers and lifecycle controllers remain available from root/app composition.

## 3. Architecture Design

```text
apps/app/lib/app/routing/routes/
├─ auth_routes.dart
└─ account_setup_routes.dart

apps/app/lib/app/router.dart  # single GoRouter owner + lifecycle callbacks
```

`account_setup_routes.dart` constructs no `GoRouter`; it returns route registrations only.

## 4. Implementation Plan

- [x] create `routing/routes/account_setup_routes.dart`
- [x] move canonical Account Setup GoRoute
- [x] move username compatibility redirect
- [x] keep provider availability/trusted-phone derivation unchanged
- [x] inject root `onExitRequested` callback
- [x] inject root `onCompleted` callback
- [x] remove now-unused Account Setup imports from root router
- [x] keep Product Onboarding block untouched
- [x] audit route/reference preservation + one-router authority
- [ ] obtain exact-head CI
- [ ] whitespace/conflict audit
- [ ] reconcile review handoff

## 5. Quality Review

Source checkpoint `764e1825`; exact-head GitHub CI pending. Static audit confirms exact four-file scope, preserved Account Setup/username route references, one root `goRouterProvider` / `GoRouter(...)`, zero `GoRouter(...)` constructions in the new module, and byte-for-byte unchanged Product Onboarding + congratulations block.

## 6. Final Handoff

### Changed files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-c2b1-account-setup-routes.md`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/routes/account_setup_routes.dart`

### Source checkpoint

- base: `main@edc86745aa28ce631ad11be0399bc87ee3fbc127`
- source checkpoint: `764e182586072fc5ee18e2d460c6198aa7eeee4b`
- exact branch scope: four C2b1-owned files
- `router.dart`: 1351 → 1329 lines
- new Account Setup route module: 49 source lines
- Account Setup + username route reference counts unchanged vs base
- Product Onboarding + congratulations source block unchanged
- root lifecycle logic remains in `router.dart` and is injected

### Final status

`IMPLEMENTED — VALIDATION PENDING`
