# GitHub #357 — C3d Body & Weight route ownership extraction

**Status:** In progress — implementation committed; hosted CI/Codex review not yet validated
**Primary owner:** `apps/app` router composition and `apps/features/settings` presentation
**Affected platforms:** Flutter Android/iOS phone app only

## Owner Approval and Scope Boundary
**Trigger:** None — bounded internal route-organization subtask within the independently approved #357/TNYX-201 architecture cleanup.
**Approval status:** Approved in owner request on 2026-10-20, “Go next with audit work star kare gate ready for review tak le kar jaye”.
**Explicit non-changes:** No product-visible UI/UX, route names/paths/deep links, app-mode, provider semantics, persistence, Auth/session, Supabase, backends, watch, Nutrition or Daily Wellness changes. No merge authority.

## Active Handoff
**Planning owner:** ChatGPT architecture workflow
**Implementation owner:** ChatGPT (single owner for bounded C3d slice)
**Review owner:** Codex GitHub review after Draft PR
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** remote `main@34eb6b55c097f7dbb66845e90924dfd3b7c8b590` on 2026-10-20
**Branch:** `tnyx/issue-357-c3d-body-weight-route-extract` (created from exact verified main SHA)
**HEAD SHA:** `8e698721b0b04cf2dea089792f5b8bf150488284` after six source/brief commits; branch created at `34eb6b55c097f7dbb66845e90924dfd3b7c8b590`
**Observed working-tree state:** Connector-only remote GitHub execution; operator local Windows `git status`/current checkout not observable. Isolated branch from exact main, no existing open GitHub PRs at branch creation.
**Observed uncommitted/dirty files:** Not observable locally; no operator local files touched.
**PR / tracker:** GitHub #357 child of #260; Linear TNYX-201 In Progress. TNYX-154 option A completed by PR #515/#516; parent TNYX-154 remains In Progress.
**Current implementation state:** Code and new error→Retry test committed. Root router delegates registration to `buildBodyWeightRoutes`; Settings presentation owns its exact pre-existing loading/error UI via `BodyWeightSettingsDestination`; app composes Body/Profile read/write/invalidation. Existing editor unchanged. Fresh compare to unchanged base: six commits ahead, zero behind, six expected files.
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/body_weight_routes.dart`, `apps/features/settings/lib/src/presentation/pages/body_weight_settings_destination.dart`, `apps/features/settings/lib/src/presentation/presentation.dart`, focused `apps/app/test/app/body_weight_route_test.dart`.
**Validation remaining:** Exact-head hosted Flutter/Dart analyze/tests, attribution, Codex; focused Body & Weight route tests and app provider lifetime; `git diff --check` locally unavailable via connector.
**Current blocker:** No identified source blocker; hosted analyze/tests, attribution, exact-head Codex and post-PR scope checks are not yet complete.
**Next exact action:** Implement one bounded extraction, audit exact branch-to-main diff, open Draft PR, validate CI and review, mark Ready only when all gates PASS. Do not merge without distinct owner instruction.

## 1. Discovery
### User Outcome
Remove the Body & Weight multi-owner route block from the root app router, preserving accepted Settings UI and canonical Progress persistence.

### Success Criteria
One GoRouter authority, the unchanged `AppRoutes.bodyWeightSettings` route and root navigator, identical loading/error/retry states, identical provider selection/read/save/invalidation and weight record source; no route/UI change. Existing focused tests + new error/retry coverage must pass.

### Scope
- Extract app-owned `GoRoute` and body/profile repository wiring into `routing/routes/body_weight_routes.dart`.
- Move the existing route-local Body & Weight loading and error presentation *unchanged* to a narrow Settings-owned destination widget, preserving runtime tokens and exact copy.
- Expose only that destination through the established Settings presentation barrel.
- Replace the old root block with `...buildBodyWeightRoutes(rootNavigatorKey: rootNavigatorKey)`; add focused retry regression test.

### Non-Goals
No relocation of `BodyWeightSettingsPage` or Body/Wellness domain owner; no generic loading component/token, broader router reorganization, Daily Wellness or Account extraction, model/API/backend changes.

## 2. Codebase Exploration
### Verified Evidence
- Fresh remote main `34eb6b55c097f7dbb66845e90924dfd3b7c8b590` on 2026-10-20; GitHub open PR list empty.
- Root `router.dart` 862 lines. Direct root routes: Splash, Daily Wellness, Body & Weight and Account Settings. Body & Weight route reads `bodyStateDataProvider`, `profileDataProvider`, `bodyRepositoryProvider`, and invalidates both Body/Profile after write. It uses `BodyWeightSources.bodyWeightSettings`.
- `apps/app/lib/app/routing/routes/settings_routes.dart` already owns related Health & Goals app navigation. Existing `body_weight_route_test.dart` verifies navigation, app-mode parity and Current Weight save/profile invalidation.
- `apps/features/settings` uses `package:tio_feature_progress/progress_contracts.dart` after completed #514; Body & Weight editor and UI state belong to Settings. Progress owns Body domain/persistence, app owns concrete provider composition.
- GitHub #357 / #260 and Linear TNYX-201 are still open/In Progress; older tracker descriptions contain pre-extraction baseline and deferred C3d blocker. Source and merged #515/#516 supersede that blocker.
- Read root `AGENTS.md`, `apps/features/AGENTS.md`, `apps/core/lib/src/theme/README.md`, `.ai/tasks/design-system-token-consolidation.md`, source/ownership docs, `.ai/workflow.md`, `.github/PUSH_TEMPLATE.md` and `.github/PULL_REQUEST_TEMPLATE.md`.

## 3. Clarification
**Decision:** The explicit owner request authorizes this already-audited, behavior-preserving internal route subtask through Ready for Review; it does *not* authorize unrelated refactoring, new product UI, or merge.

## 4. Architecture Design
**Chosen approach:** Settings presentation widget receives plain Body data/load flags and callbacks; app route module watches providers and wires repositories; the root app router composes that route exactly once.
**Ownership and data flow:** `apps/app` (GoRoute, Riverpod, repository injection) → `apps/features/settings` (loading/error and editor UI) → Progress-owned `BodyState/BodyGoalUpdate` domain contracts. Concrete Body repositories remain in the app composition root.
**Alternative rejected:** Blindly moving loading/error `Scaffold` into the app route module would move feature UI into another app glue file; changing UI visuals or creating a shared component would exceed scope.
**Failure and accessibility states:** Preserve existing themed app bars, `SafeArea`, progress indicator, error copy/Retry button and invalidation, cached `valueOrNull` behavior without UI geometry change.

## 5. Implementation Plan
1. Write this brief before source edits; keep one active implementation owner.
2. Extract Settings-owned destination using the existing Body & Weight loading/error code without visual substitutions.
3. Register app-owned Body & Weight route with identical callbacks, provider watches, refresh semantics.
4. Add regression coverage for error/Retry; retain all existing tests.
5. Audit exact changed paths and ancestry; run CI and Codex exact-head review; stop at Ready for Review.

## 6. Quality Review
**Validation Run:** Hosted CI pending. No local Flutter/Dart/`git diff --check` was executed by this connector-only agent. Remote GitHub compare confirmed six owned files, 6 ahead/0 behind at pre-PR code head `8e698721b0b04cf2dea089792f5b8bf150488284`.
**Review Findings and Resolution:** Pending Codex and exact-head checks.

## 7. Final Handoff
**Changed Files:** `.ai/tasks/issue-357-c3d-body-weight-route.md`; `apps/app/lib/app/router.dart`; `apps/app/lib/app/routing/routes/body_weight_routes.dart`; `apps/app/test/app/body_weight_route_test.dart`; `apps/features/settings/lib/src/presentation/pages/body_weight_settings_destination.dart`; `apps/features/settings/lib/src/presentation/presentation.dart`.
**Actual Behavior:** Source inspected as behavior-preserving but awaiting Flutter CI; no runtime execution or visual comparison has been performed.
**Known Limitations:** The remote GitHub connector cannot run local Windows Flutter or `git diff --check`; CI is the hosted code validation source. Owner's local working tree is not visible.
**Final Status:** SOURCE PREPARED — review/CI pending, do not merge.
