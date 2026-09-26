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
**HEAD SHA:** branch created from `b09e8fbca2295082fdaa68059309ad976d08e9af`; source mutation not yet applied.
**PR / tracker:** Linear TNYX-201; GitHub #260; router parent #357; C2b2 child #386; TNYX-202/#261 and TNYX-159/#215 context-only.
**Current blocker:** None.
**Next exact action:** Extract only `AppRoutes.onboarding` + `AppRoutes.congratulations` registration/page mounting into `app/routing/routes/onboarding_routes.dart`, injecting seed/workflow/navigation callbacks from root.

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

- [ ] create `routing/routes/onboarding_routes.dart`
- [ ] move `AppRoutes.onboarding` registration/page mounting
- [ ] move `AppRoutes.congratulations` registration/page mounting
- [ ] inject already-built seed from root
- [ ] inject exit/Auth/completion callbacks with route `BuildContext`
- [ ] inject Congratulations continue navigation callback
- [ ] keep root workflow/policy block semantically unchanged
- [ ] keep `AppOnboardingController` and feature source untouched
- [ ] audit route/workflow reference preservation + one-router authority
- [ ] obtain exact-head CI
- [ ] whitespace/conflict audit
- [ ] reconcile review handoff

## 5. Quality Review

Pending.

## 6. Final Handoff

Pending implementation and validation.
