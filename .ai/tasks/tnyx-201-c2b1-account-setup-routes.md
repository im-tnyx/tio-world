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
**Implementation ownership state:** Complete
**Repository state last verified:** `main@edc86745aa28ce631ad11be0399bc87ee3fbc127` after C2a archive PR #382.
**Branch:** `tnyx/tnyx-201-c2b1-account-setup-routes`
**HEAD SHA:** validated source/review checkpoint `b587a5994c7d13935a7185a2958ad947e3141068`; this handoff reconciliation is documentation-only.
**PR / tracker:** Linear TNYX-201; GitHub #260; router parent #357; C2b1 child #383; TNYX-202/#261 explicitly separate.
**Current blocker:** None.
**Next exact action:** Revalidate this documentation-only final head; if green, mark PR #384 ready for review and reconcile TNYX-201 to In Review.

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
- [x] obtain exact-head CI
- [x] whitespace/conflict audit
- [ ] reconcile review handoff

## 5. Quality Review

```text
Initial CI #2793 / run 36233670653 @ a1750f18077fec6bca454cdc89c261ea9ffb05f5
- Bootstrap workspace: PASS
- Flutter analyze: FAIL
- finding: root callback still referenced `accountSetupRepositoryProvider` after its import was removed
- fix: commit `b587a5994c7d13935a7185a2958ad947e3141068` restores the narrow direct `account_setup/account_setup_providers.dart` import

Validated source head CI #2794 / run 36233752458 @ b587a5994c7d13935a7185a2958ad947e3141068
- Bootstrap workspace: PASS
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS
- Commit attribution guard: PASS
- Attribution guard runner: PASS

API-mode scope / behavior-preservation audit
- base ancestor: PASS
- ahead / behind: 6 / 0
- changed files: exactly 4 C2b1-owned paths
- trailing whitespace / conflict markers: 0 findings
- Account Setup / username route reference counts: unchanged vs base
- Product Onboarding + congratulations block: byte-for-byte unchanged
- root lifecycle operation reference counts: unchanged vs base
- root goRouterProvider definitions: 1
- root GoRouter(...) constructions: 1
- Account Setup route module GoRouter(...) constructions: 0
- review threads: 0 at validated source checkpoint

Non-required GHAS failed before code analysis because its configured Copilot model returned `400 The requested model is not supported`; no code-scanning finding was produced.
```

This handoff update is documentation-only and requires one final exact-head CI recheck.

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

`REVIEW HANDOFF — FINAL HEAD REVALIDATION PENDING`
