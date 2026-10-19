# GitHub #357 — C3d Body & Weight route ownership extraction

**Status:** In Review — implementation and exact source-head Flutter CI validated; Codex review quota-limited (no clean Codex review). An independent read-only source review identified one P3 task-handoff wording issue, corrected in this update. PR merge remains separately gated.
**Primary owner:** `apps/app` router composition and `apps/features/settings` presentation
**Affected platforms:** Flutter Android/iOS phone app only

## Owner Approval and Scope Boundary
**Trigger:** None — bounded internal route-organization subtask within the independently approved #357/TNYX-201 architecture cleanup.
**Approval status:** Approved in owner request on 2026-10-20, “Go next with audit work star kare gate ready for review tak le kar jaye”.
**Explicit non-changes:** No product-visible UI/UX, route names/paths/deep links, app-mode, provider semantics, persistence, Auth/session, Supabase, backends, watch, Nutrition or Daily Wellness changes. No merge authority.

## Active Handoff
**Planning owner:** ChatGPT architecture workflow
**Implementation owner:** ChatGPT (single owner for bounded C3d slice)
**Review owner:** Independent read-only review comment on PR #622 (COMMENTED, not APPROVED); Codex automated review attempted but quota-limited before analysis.
**Implementation ownership state:** Handoff pending — source implementation complete, PR Ready for Review.
**Ownership transition:** Not applicable
**Repository state last verified:** remote `main@34eb6b55c097f7dbb66845e90924dfd3b7c8b590` on 2026-10-20
**Branch:** `tnyx/issue-357-c3d-body-weight-route-extract` (created from exact verified main SHA)
**HEAD SHA:** Source implementation validated at `f02cf5dd9948afcb59cce5a8bf1430babc0b3cb4`. This documentation-only reconciliation creates a later branch commit; read exact latest HEAD and checks from [PR #622](https://github.com/im-tnyx/tio-world/pull/622), not from this fixed historical implementation SHA. Branch originally created from `main@34eb6b55c097f7dbb66845e90924dfd3b7c8b590`.
**Observed working-tree state:** Connector-only remote GitHub execution; operator local Windows `git status`/current checkout not observable. Isolated branch from exact main, no existing open GitHub PRs at branch creation.
**Observed uncommitted/dirty files:** Not observable locally; no operator local files touched.
**PR / tracker:** GitHub #357 child of #260; Linear TNYX-201 In Progress. TNYX-154 option A completed by PR #515/#516; parent TNYX-154 remains In Progress.
**Current implementation state:** Source implementation complete; root delegates to `buildBodyWeightRoutes`, Settings owns the unchanged loading/error presentation via `BodyWeightSettingsDestination`, and app owns Body/Profile providers/writes/invalidation. Existing editor unchanged. Exact source-head PR compare: 8 commits ahead, 0 behind, six owned changed paths. This later documentation-only review-finding correction changes commit count but not changed-file scope.
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/body_weight_routes.dart`, `apps/features/settings/lib/src/presentation/pages/body_weight_settings_destination.dart`, `apps/features/settings/lib/src/presentation/presentation.dart`, focused `apps/app/test/app/body_weight_route_test.dart`.
**Validation remaining:** Before merge, recheck the latest PR HEAD, CI and required attribution on that HEAD and verify 0 unresolved review threads. The source implementation head `f02cf5dd9948afcb59cce5a8bf1430babc0b3cb4` already passed full hosted Flutter CI #39313401806 (all 7 checks). No local Flutter, screenshot parity or `git diff --check` run is claimed. Codex independent automated review remains unavailable due to quota, not a code finding or clean review.
**Current blocker:** One independent review P3 handoff-accuracy finding is being corrected in this documentation-only update. No P1/P2 source defect identified in the independent read-only review. Merge remains blocked until the finding is resolved and the updated PR HEAD passes its required gate.
**Next exact action:** Recheck final HEAD after this P3 correction; respond to and resolve the finding with evidence; verify exact-head CI/required checks and branch scope/ancestry. Owner separately authorized a conditional merge on 2026-10-20: merge only if all gates are clean, and document post-merge state. Parent TNYX-201 remains In Progress.

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
**Validation Run:** [Flutter CI run 39313401806](https://github.com/im-tnyx/tio-world/actions/runs/39313401806) SUCCESS at source head `f02cf5dd9948afcb59cce5a8bf1430babc0b3cb4`: Flutter/Dart analysis, Dart tests, App/Workout, Nutrition/Onboarding, Core/Wear, aggregate Analyze and test, and two attribution checks PASS (7/7). Earlier initial-head analyze failed on a now-removed unused Progress import; subsequent exact source-head run passed. A docs-only commit to fix this P3 makes a new HEAD whose checks must be read live before merge. No local Flutter/Dart/`git diff --check` was run by this connector-only agent. GitHub compare at source head: six exact owned files, 8 ahead, 0 behind.
**Review Findings and Resolution:** Codex request #6275732619 and Ready-triggered attempt returned usage-limit notices #6275744119/#6275907593 without code analysis; **Codex is neither clean nor a code finding**. Independent read-only source review #5576936667, GitHub review `COMMENTED` not APPROVED, found no P1/P2 source defects at exact source head and raised P3 inline comment #4318185110 (stale active handoff). This documentation-only correction addresses that P3; thread disposition and latest-head checks are separate live PR gates.

## 7. Final Handoff
**Changed Files:** `.ai/tasks/issue-357-c3d-body-weight-route.md`; `apps/app/lib/app/router.dart`; `apps/app/lib/app/routing/routes/body_weight_routes.dart`; `apps/app/test/app/body_weight_route_test.dart`; `apps/features/settings/lib/src/presentation/pages/body_weight_settings_destination.dart`; `apps/features/settings/lib/src/presentation/presentation.dart`.
**Actual Behavior:** Route composition remains behavior-preserving per source review and full hosted Flutter CI including focused Body route tests. Settings-owned presentation preserves old loading/error visual code; no independent screenshot parity or local Windows execution was observed.
**Known Limitations:** The remote GitHub connector cannot inspect the operator's Windows working tree or run local Flutter and `git diff --check`; hosted CI is the execution evidence. No independent screenshot parity. Codex usage quota blocked automated review before analysis, and the separate independent human-style GitHub comment is COMMENTED, not formal APPROVED. Parent TNYX-201/#260/#357 remain open.
**Final Status:** IN REVIEW — implementation source and CI validated at source HEAD; P3 documentation consistency corrected; merge conditional on clean *updated* exact-head checks and resolved review thread.
