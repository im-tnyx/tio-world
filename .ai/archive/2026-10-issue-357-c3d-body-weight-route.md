# GitHub #357 — C3d Body & Weight route ownership extraction

**Status:** Validated
**Completed:** 2026-10-20
**Merged implementation:** [PR #622](https://github.com/im-tnyx/tio-world/pull/622), squash `main@56fae633aed26e14e237d7e70f81256fec2ddd64`
**Primary owner:** `apps/app` router composition and `apps/features/settings` presentation
**Affected platforms:** Flutter Android/iOS phone app only

## Owner Approval and Scope Boundary
**Trigger:** None — bounded internal route-organization subtask within the independently approved #357/TNYX-201 architecture cleanup.
**Approval status:** Owner authorized the bounded C3d implementation through Ready for Review on 2026-10-20; separately authorized conditional merge after audit and clean gates. Both phases completed with verified evidence.
**Explicit non-changes:** No product-visible UI/UX, route names/paths/deep links, app-mode, provider semantics, persistence, Auth/session, Supabase, backends, watch, Nutrition or Daily Wellness changes. Separate explicit conditional merge authorization was obtained for PR #622; no authorization extends to a later archive PR or next implementation slice.

## Active Handoff
**Planning owner:** ChatGPT architecture workflow
**Implementation owner:** ChatGPT (single owner for bounded C3d slice)
**Review owner:** Independent read-only review comment on PR #622 (COMMENTED, not APPROVED); Codex automated review attempted but quota-limited before analysis.
**Implementation ownership state:** Closed — C3d implementation merged, validated, and archived; no active source owner for this completed child.
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub remote `main@56fae633aed26e14e237d7e70f81256fec2ddd64` (PR #622 squash commit), exact SHA verified after merge; parent of squash commit was `34eb6b55c097f7dbb66845e90924dfd3b7c8b590`. No local Windows checkout was read.
**Branch:** `tnyx/issue-357-c3d-body-weight-route-extract` (created from exact verified main SHA)
**Final PR HEAD:** `0d7255824c2c3e10e4bd220655d98516ddd45a9e` (full final CI #39315421526 7/7 PASS); source-reviewed code HEAD `f02cf5dd9948afcb59cce5a8bf1430babc0b3cb4` differed by exactly one task-brief documentation file. Squash merge `56fae633aed26e14e237d7e70f81256fec2ddd64` on protected `main`; post-merge push CI #39316212191 5/5 PASS.
**Observed working-tree state:** Connector-only remote GitHub execution; operator local Windows `git status`/current checkout not observable. Isolated branch from exact main, no existing open GitHub PRs at branch creation.
**Observed uncommitted/dirty files:** Not observable locally; no operator local files touched.
**PR / tracker:** GitHub #357 child of #260; Linear TNYX-201 In Progress. TNYX-154 option A completed by PR #515/#516; parent TNYX-154 remains In Progress.
**Current implementation state:** Completed on protected main; root delegates to `buildBodyWeightRoutes`, Settings owns unchanged loading/error presentation via `BodyWeightSettingsDestination`, and app owns Body/Profile providers/writes/invalidation. Existing editor unchanged. Final PR #622 diff had six expected paths, 9 commits ahead/0 behind relative to original `main`; squash merge verified.
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/body_weight_routes.dart`, `apps/features/settings/lib/src/presentation/pages/body_weight_settings_destination.dart`, `apps/features/settings/lib/src/presentation/presentation.dart`, focused `apps/app/test/app/body_weight_route_test.dart`.
**Validation completed:** Final PR #622 HEAD `0d7255824c2c3e10e4bd220655d98516ddd45a9e`: Flutter CI #39315421526 7/7 SUCCESS, including required Commit attribution guard and aggregate Flutter/Dart checks; 0 unresolved review threads and exact six-path scope. After squash, `main@56fae633aed26e14e237d7e70f81256fec2ddd64` push Flutter CI #39316212191 5/5 SUCCESS (Analyze and test, Dart/Flutter analyze/tests and three Flutter test shards). No local Windows Flutter, screenshot parity or `git diff --check` result claimed.
**Current blocker:** None for merged C3d implementation. Independent read-only review found no P1/P2 source defect; its single P3 handoff-accuracy finding #4318185110 was fixed by docs-only PR-head commit `0d7255824c2c3e10e4bd220655d98516ddd45a9e`, replied to and resolved. Codex usage quota prevented automated review before analysis; this is not a code finding and not a clean Codex review. Broader TNYX-201/#260/#357 remains open.
**Next exact action:** None for this validated C3d child. For a new route slice, audit current protected main, canonical ownership, existing task handoffs, GitHub #357/#260 and Linear TNYX-201; do not automatically start Daily Wellness or security-sensitive Account work. Keep TNYX-201 In Progress until remaining parent acceptance is verified.

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
**Decision:** This approved and completed C3d subtask was behavior-preserving. Owner later explicitly authorized a conditional merge after fresh review/CI gates; PR #622 satisfied those gates and was merged. Authorization did not include unrelated work.

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
**Validation Run:** Source-reviewed HEAD `f02cf5dd9948afcb59cce5a8bf1430babc0b3cb4` [Flutter CI #39313401806](https://github.com/im-tnyx/tio-world/actions/runs/39313401806) SUCCESS 7/7. Final PR HEAD `0d7255824c2c3e10e4bd220655d98516ddd45a9e` [Flutter CI #39315421526](https://github.com/im-tnyx/tio-world/actions/runs/39315421526) SUCCESS 7/7, with full aggregate and required attribution. Post-merge `main@56fae633aed26e14e237d7e70f81256fec2ddd64` [Flutter CI #39316212191](https://github.com/im-tnyx/tio-world/actions/runs/39316212191) SUCCESS 5/5. Initial old-head analyzer unused Progress import was fixed before final validation. Local Windows `git status`, Flutter and `git diff --check` were not observed.
**Review Findings and Resolution:** Codex request #6275732619 and Ready-triggered attempt returned usage-limit notices #6275744119/#6275907593 without code analysis; **Codex is neither clean nor a code finding**. Independent read-only source review #5576936667 was `COMMENTED` (not a formal `APPROVED` review); no P1/P2 source defects identified. P3 task-handoff finding #4318185110 corrected by `0d7255824c2c3e10e4bd220655d98516ddd45a9e`, replied and resolved. At final merge gate 0 unresolved review threads, 7/7 exact-head checks PASS and branch mergeability/ancestry verified.

## 7. Final Handoff
**Changed Files:** `.ai/tasks/issue-357-c3d-body-weight-route.md`; `apps/app/lib/app/router.dart`; `apps/app/lib/app/routing/routes/body_weight_routes.dart`; `apps/app/test/app/body_weight_route_test.dart`; `apps/features/settings/lib/src/presentation/pages/body_weight_settings_destination.dart`; `apps/features/settings/lib/src/presentation/presentation.dart`.
**Actual Behavior:** Verified merged source delegates Body & Weight route once from the root router and keeps app-owned provider/repository composition with Settings-owned loading/error/Retry presentation. Full hosted Flutter validation completed before and after merge; no independent rendered screenshot parity or local Windows/device test was observed.
**Known Limitations:** Connector-only GitHub/Linear execution: the operator's current Windows working tree and local `git status`, Flutter, device screenshot parity, `git diff --check`, and local post-merge `git pull --ff-only` were not observed. GitHub-hosted exact-head and post-merge Flutter CI succeeded. Codex quota prevented automated review before analysis; independent read-only review was COMMENTED, not formal APPROVED. Broader TNYX-201/#260/#357 remain In Progress/Open.
**Final Status:** VALIDATED — PR #622 merged into `main@56fae633aed26e14e237d7e70f81256fec2ddd64` with exact PR-head hosted CI 7/7, post-merge Flutter CI 5/5, resolved P3 review thread and no P1/P2 source defects found in independent read-only review. TNYX-201 and GitHub #357/#260 remain open for remaining app-shell/router ownership work.
