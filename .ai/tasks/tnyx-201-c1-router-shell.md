# TNYX-201 C1 — Router Shell Extraction

**Status:** In progress
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
**Implementation ownership state:** Active
**Repository state last verified:** `main@3dbd2ecf208267346676f43d81d6d53a1112a8af` after B6 archive PR #376.
**Branch:** `tnyx/tnyx-201-c1-router-shell`
**HEAD SHA:** source checkpoint `850c0d65b041cfba272444f331facb21fd10ef0d`; subsequent handoff update is documentation-only.
**PR / tracker:** Linear TNYX-201; GitHub #260; router parent #357; C1 child #377.
**Current blocker:** None.
**Next exact action:** Open Draft PR, run exact-head CI, then complete shell behavior/scope/review audit.

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
- [ ] obtain exact-head CI
- [ ] record whitespace/conflict audit
- [ ] reconcile review handoff

## 6. Quality Review

Source checkpoint `850c0d65`; exact-head CI pending. Static ownership audit confirms one root `goRouterProvider`/`GoRouter(...)`, one root `shellChromePolicyForPath`, and one extracted `StatefulShellRoute.indexedStack`.

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

`IMPLEMENTED — VALIDATION PENDING`
