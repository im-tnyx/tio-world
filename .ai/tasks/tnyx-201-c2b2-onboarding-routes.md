# TNYX-201 C2b2 — Product Onboarding Route Registration Extraction

**Status:** In progress
**Primary owner:** apps/app routing composition
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Approval status:** Approved
**Approval evidence:** Owner said “Go next” after C2b1 merge/archive and fresh Product Onboarding route-boundary audit.
**Approved boundary:** Product Onboarding + Congratulations route registration/page mounting only.
**Explicit non-changes:** No Product Onboarding workflow/controller/domain redesign; no `AppOnboardingController` change; no TNYX-202/#261 package cleanup; no TNYX-159/#215 future flow implementation; no UI/persistence/Supabase change.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned
**Implementation ownership state:** Active
**Repository state last verified:** `main@b09e8fbca2295082fdaa68059309ad976d08e9af` after C2b1 archive PR #385.
**Branch:** `tnyx/tnyx-201-c2b2-onboarding-routes`
**HEAD SHA:** source checkpoint `8cccf6ba0fa8c9f876aaf368aebdc2fd0833f1ef`; subsequent handoff update is documentation-only.
**PR / tracker:** Linear TNYX-201; GitHub #260; router parent #357; C2b2 child #386; TNYX-202/#261 and TNYX-159/#215 context-only.
**Current blocker:** None.
**Next exact action:** Open Draft PR, run exact-head CI, then complete scope/whitespace/review audit.

## 1. Discovery

### Scope

- Product Onboarding route registration/page mounting
- Congratulations route registration/page mounting + extras parsing

### Root-owned policy/workflow

- selected App Mode + entry-path → `OnboardingControllerSeed`
- sign-out/session clear + bootstrap refresh
- Auth handoff/signup navigation
- completion use-case resolution/invocation
- `BuildOnboardingFlowUseCase`
- onboarding-status/bootstrap readiness mutation
- navigation side effects

### Non-goals

- `AppOnboardingController`
- TNYX-202/#261 package cleanup
- TNYX-159/#215 future log-first flow
- feature flow/order/UI/domain/persistence changes

## 2. Codebase Exploration

- Root `AGENTS.md`, architecture/ownership docs, workflow, feature-development and push/PR guidance refreshed.
- C2b1 merged as PR #384 (`c0d7c2e2`) and archived by #385 (`b09e8fbc`).
- Fresh audit classifies route mounting as APP COMPOSITION and the embedded callbacks as SPLIT RESPONSIBILITY.
- `OnboardingFlowPage` accepts `OnboardingControllerSeed`, `onExitRequested`, `onAuthRequired`, and `onFinishRequested` callbacks; the route module can wrap context-aware root callbacks without moving policy.
- `CongratulationsScreen` accepts route-derived display data and an `onContinue` callback; Home navigation can remain root-owned.
- `AppOnboardingController` remains app-owned production override with feature workflow/persistence semantics and is explicitly excluded.

## 3. Architecture Design

```text
apps/app/lib/app/routing/routes/
├─ auth_routes.dart
├─ account_setup_routes.dart
└─ onboarding_routes.dart

apps/app/lib/app/router.dart  # single GoRouter owner + Product Onboarding policy/workflow callbacks
```

`onboarding_routes.dart` returns route registrations only and constructs no `GoRouter`.

## 4. Implementation Plan

- [x] create `routing/routes/onboarding_routes.dart`
- [x] move `AppRoutes.onboarding` registration/page mounting
- [x] move `AppRoutes.congratulations` registration/page mounting
- [x] inject already-built seed from root
- [x] inject exit/Auth/completion callbacks with route `BuildContext`
- [x] inject Congratulations continue navigation callback
- [x] keep root workflow/policy block semantically unchanged
- [x] keep `AppOnboardingController` and feature source untouched
- [x] audit route/workflow reference preservation + one-router authority
- [ ] obtain exact-head CI
- [ ] whitespace/conflict audit
- [ ] reconcile review handoff

## 5. Quality Review

Source checkpoint `8cccf6ba`; exact-head GitHub CI pending. Static audit confirms exact four-file scope, preserved Onboarding/Congratulations route references, unchanged root workflow-operation reference counts, zero workflow-policy symbols in the new module, one root `goRouterProvider` / `GoRouter(...)`, and zero `GoRouter(...)` constructions in `onboarding_routes.dart`.

## 6. Final Handoff

### Changed files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-c2b2-onboarding-routes.md`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/routes/onboarding_routes.dart`

### Source checkpoint

- base: `main@b09e8fbca2295082fdaa68059309ad976d08e9af`
- source checkpoint: `8cccf6ba0fa8c9f876aaf368aebdc2fd0833f1ef`
- exact branch scope: four C2b2-owned files
- `router.dart`: 1330 → 1323 lines
- new Onboarding route module: 43 source lines
- Onboarding/Congratulations route reference counts unchanged vs base
- Product Onboarding workflow-operation counts remain unchanged in root
- `AppOnboardingController` and feature source untouched

### Final status

`IMPLEMENTED — VALIDATION PENDING`
