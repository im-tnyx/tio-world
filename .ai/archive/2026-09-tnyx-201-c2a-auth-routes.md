# TNYX-201 C2a — Auth Route Group Extraction

**Status:** Validated
**Completion date:** 2026-09-26
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
**Implementation ownership state:** Complete
**Repository state last verified:** 2026-09-26 after PR #381 squash merge; GitHub `main` is `646d3e9ae87cd466ce265e9b2b306ff5ec449d22`.
**Branch:** `tnyx/tnyx-201-c2a-auth-routes` (merged via PR #381; branch cleanup remains optional and was not performed without a separate request).
**HEAD SHA:** final reviewed PR head `7e057cc0c02fae58c2e66ffda4f0bca0d7f8ca4b`; squash-merged to `main` as `646d3e9ae87cd466ce265e9b2b306ff5ec449d22`.
**PR / tracker:** PR #381 merged; GitHub #380 closed by merge; #357 / #260 / Linear TNYX-201 remain parent planning/acceptance trackers.
**Current blocker:** None.
**Next exact action:** None for C2a. Fresh post-merge audit classifies Account Setup + Product Onboarding for the next bounded router slice.

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
- [x] obtain exact-head CI
- [x] whitespace/conflict audit
- [x] reconcile review handoff

## 5. Quality Review

```text
Initial CI #2789 / run 36230634296 @ c73314bb9b3f4719463927368e41956f01c4cd6b
- Bootstrap workspace: PASS
- Flutter analyze: FAIL
- finding: `PreAuthAppModeRoute` direct defining-file import missing after extraction
- fix: commit `44ae55a0bf0b7ebab9902d7ee0487df4a7f3f52f` imports `account_setup/pre_auth_app_mode_route.dart`

Validated source head CI #2790 / run 36230720003 @ 44ae55a0bf0b7ebab9902d7ee0487df4a7f3f52f
- Bootstrap workspace: PASS
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS

API-mode scope / behavior-preservation audit
- base ancestor: PASS
- ahead / behind: 7 / 0
- changed files: exactly 4 C2a-owned paths
- trailing whitespace / conflict markers: 0 findings
- all six Auth/pre-auth route reference counts: unchanged vs base
- root goRouterProvider definitions: 1
- root GoRouter(...) constructions: 1
- auth module GoRouter(...) constructions: 0
- Account Setup / Onboarding route source: untouched
- review threads: 0 at validated source checkpoint

Non-required GHAS failed before code analysis because its configured Copilot model returned `400 The requested model is not supported`; no code-scanning finding was produced.
```

Final reviewed head `7e057cc0c02fae58c2e66ffda4f0bca0d7f8ca4b` was revalidated by Flutter CI #2791 / run `36231554984`: bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests all passed. Attribution guards passed. Non-required GHAS failed before code analysis because the configured Copilot model was unsupported; no code-scanning finding was produced.

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

`PASS`: merged via PR #381 as `646d3e9ae87cd466ce265e9b2b306ff5ec449d22` on 2026-09-26T09:18:35Z (UTC). Exact final head `7e057cc0c02fae58c2e66ffda4f0bca0d7f8ca4b` passed Flutter CI #2791 and attribution guards; whitespace/conflict audit was clean; six Auth/pre-auth route contracts and single router authority were preserved; 0 unresolved review threads remained.
