# TNYX-201 C2b2 — Product Onboarding Route Registration Extraction

**Status:** Validated
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
**Implementation ownership state:** Complete
**Repository state last verified:** `main@b09e8fbca2295082fdaa68059309ad976d08e9af` after C2b1 archive PR #385.
**Branch:** `tnyx/tnyx-201-c2b2-onboarding-routes`
**HEAD SHA:** validated source/review checkpoint `5045ef5b60748da60068cb751f1bf4dbdf86b651`; this handoff reconciliation is documentation-only.
**PR / tracker:** Linear TNYX-201; GitHub #260; router parent #357; C2b2 child #386; TNYX-202/#261 and TNYX-159/#215 context-only.
**Current blocker:** None.
**Next exact action:** None. Source PR #387 merged and this brief is archived.

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
- [x] obtain exact-head CI
- [x] whitespace/conflict audit
- [x] reconcile review handoff

## 5. Quality Review

```text
Validated source/review head CI #2797 / run 36237157142 @ 5045ef5b60748da60068cb751f1bf4dbdf86b651
- Bootstrap workspace: PASS
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS
- Commit attribution guard: PASS
- Attribution guard runner: PASS

API-mode scope / behavior-preservation audit
- base ancestor: PASS
- ahead / behind: 5 / 0
- changed files: exactly 4 C2b2-owned paths
- trailing whitespace / conflict markers: 0 findings
- Onboarding / Congratulations route reference counts: unchanged vs base
- root Product Onboarding workflow-operation reference counts: unchanged vs base
- workflow-policy symbols in `onboarding_routes.dart`: 0
- root goRouterProvider definitions: 1
- root GoRouter(...) constructions: 1
- Onboarding route module GoRouter(...) constructions: 0
- AppOnboardingController / feature source: untouched
- review threads: 0 at validated source checkpoint

Non-required GHAS failed before code analysis because its configured Copilot model returned `400 The requested model is not supported`; no code-scanning finding was produced.
```

Final exact-head Flutter CI #2798 / run 36237539943 passed at `ff72da0d46e8e8e3af9adaea238a2e521627f5a9`. Codex reviewed that exact head with no major issues and 0 unresolved review threads. PR #387 was squash-merged as `e458eda5bd22683ddb22ebd019afde37873b9249` on 2026-09-26.

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

`VALIDATED — MERGED VIA PR #387 (e458eda5)`
