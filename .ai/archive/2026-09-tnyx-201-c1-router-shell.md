# TNYX-201 C1 — Router Shell Extraction

**Status:** Validated
**Completion date:** 2026-09-26
**Primary owner:** apps/app routing composition
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Approval status:** Approved
**Approval evidence:** Owner said “Go next” after B6 post-merge audit identified #357 C1 as the next bounded slice.
**Approved boundary:** Internal router shell-composition refactor only.
**Explicit non-changes:** No route/path/deep-link redesign; no redirect/bootstrap change; no Auth/Account/Onboarding/Profile/Settings/Nutrition route-group extraction; no route-local feature presentation migration; no UI/persistence/Supabase change.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Unassigned
**Implementation ownership state:** Complete
**Repository state last verified:** 2026-09-26 after PR #378 squash merge; GitHub `main` is `85a14875ddfe9948c7308c10791612b33e70ad8c`.
**Branch:** `tnyx/tnyx-201-c1-router-shell` (merged via PR #378; branch cleanup remains optional and was not performed without a separate request).
**HEAD SHA:** final reviewed PR head `9e889e9debeeebecf661d850026a4c31201166ef`; squash-merged to `main` as `85a14875ddfe9948c7308c10791612b33e70ad8c`.
**PR / tracker:** PR #378 merged; GitHub #377 closed by merge; #357 / #260 / Linear TNYX-201 remain parent planning/acceptance trackers.
**Current blocker:** None.
**Next exact action:** None for C1. Fresh post-merge audit decides the next bounded router slice under #357.

## 1. Discovery

### User outcome

Start Slice C by making shell composition independently owned without changing navigation behavior.

### Scope

Move only:

- shell branch page composition;
- Workout Library / Exercises branch-child route registration;
- child path helper;
- shell calendar month/Today top-bar helpers;
- shell action handling;
- `StatefulShellRoute.indexedStack` assembly.

### Keep in `router.dart`

- `rootNavigatorKey`;
- `shellChromePolicyForPath`;
- `goRouterProvider`;
- redirect/bootstrap/session wiring;
- every non-shell feature route group.

## 2. Codebase Exploration

### Verified evidence

- Root `AGENTS.md`, #260, #357, TNYX-201, canonical architecture/ownership docs and current runtime were reconciled.
- Slice B is complete: `network_providers.dart` is now 88 lines and single-responsibility Profile composition + compatibility exports, so no cosmetic B7 extraction is needed.
- #357 current plan explicitly recommends C1 shell extraction before route groups.
- `shellChromePolicyForPath` is directly referenced by app route tests and remains a public compatibility seam.
- `goRouterProvider` is consumed by `app.dart` and route tests; it remains in `router.dart`.
- Shell behavior is covered by `app_mode_router_test.dart`, `workout_exercises_route_test.dart`, nutrition route tests and shell top-bar tests.
- Shell calendar helpers are APP-SHELL UI because they render shared shell chrome for both Workout and Meal Diary; they are not feature-domain logic.

## 3. Clarification

| Decision | Status | Rationale |
| --- | --- | --- |
| Keep root router public entry in current file for C1 | Made | Avoid import migration and preserve one authority |
| Keep `shellChromePolicyForPath` in root router | Made | It is a public/tested whole-app chrome policy, not shell-internal-only |
| Pass root navigator key + chrome policy into shell factory | Made | Avoid second router authority and circular ownership |
| Move shared calendar shell UI helpers with shell assembly | Made | They are APP-SHELL UI used by shell chrome |
| Do not touch route-local feature presentation blocks | Made | Deferred to later classified slices |

## 4. Architecture Design

```text
apps/app/lib/app/
├─ router.dart                       # one public GoRouter owner
└─ routing/
   └─ shell/
      └─ shell_route.dart            # shell-only composition
```

`shell_route.dart` receives composition inputs from root router and does not construct a competing `GoRouter`.

## 5. Implementation Plan

- [x] create `routing/shell/shell_route.dart`
- [x] move shell branch/page/child-route helpers unchanged
- [x] move shell top-bar calendar helpers unchanged
- [x] move shell action handler unchanged
- [x] replace inline `StatefulShellRoute.indexedStack` with shell factory call
- [x] keep `rootNavigatorKey`, chrome policy and `goRouterProvider` in root
- [x] preserve existing test imports
- [x] audit parent-to-head scope
- [x] obtain exact-head CI
- [x] record whitespace/conflict audit
- [x] reconcile review handoff

## 6. Quality Review

```text
Flutter CI #2786 / run 36228547519 @ f5df76e375254d9d4a802e70fd068b7afd2a1882
- Bootstrap workspace: PASS
- Analyze Flutter packages: PASS
- Analyze Dart packages: PASS
- Test Flutter packages: PASS
- Test Dart packages: PASS

API-mode scope / behavior-preservation audit
- base ancestor: PASS
- ahead / behind: 6 / 0
- changed files: exactly 4 C1-owned paths
- trailing whitespace / conflict markers: 0 findings after cleanup commit f5df76e3
- root goRouterProvider definitions: 1
- root GoRouter(...) constructions: 1
- root shellChromePolicyForPath definitions: 1
- shell GoRouter(...) constructions: 0
- extracted StatefulShellRoute.indexedStack definitions: 1
- baseline vs current combined source AppRoutes.* references: 0 count differences
- baseline vs current combined source FeatureRoutes.* references: 0 count differences
- baseline vs current combined source shell ValueKey(...) references: 0 count differences
- baseline vs current combined source ShellTab.* references: 0 count differences
- review threads: 0 at validated source checkpoint

Non-required GHAS failed before code analysis because the configured Copilot model returned `400 The requested model is not supported`; no code-scanning finding was produced.
```

Final reviewed head `9e889e9debeeebecf661d850026a4c31201166ef` was revalidated by Flutter CI #2787 / run `36229082683`: bootstrap, Flutter analyze, Dart analyze, Flutter tests and Dart tests all passed. Attribution guards passed. Non-required GHAS failed before code analysis because the configured Copilot model was unsupported; no code-scanning finding was produced.

## 7. Final Handoff

### Changed files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-c1-router-shell.md`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/shell/shell_route.dart`

### Source checkpoint

- base: `main@3dbd2ecf208267346676f43d81d6d53a1112a8af`
- source checkpoint: `850c0d65b041cfba272444f331facb21fd10ef0d`
- exact branch scope: four C1-owned files
- `router.dart`: 1738 → 1461 lines
- new shell module: 304 source lines
- root `goRouterProvider`, root navigator key and chrome policy preserved
- no non-shell route group, feature source, UI contract, backend or schema path changed

### Final status

`PASS`: merged via PR #378 as `85a14875ddfe9948c7308c10791612b33e70ad8c` on 2026-09-26T08:37:50Z (UTC). Exact final head `9e889e9debeeebecf661d850026a4c31201166ef` passed Flutter CI #2787 and attribution guards; whitespace/conflict audit was clean; one root router authority remained; 0 unresolved review threads remained.
