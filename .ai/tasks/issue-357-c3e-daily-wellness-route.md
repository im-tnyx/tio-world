# GitHub #357 — C3e Daily Wellness route owner extraction

**Status:** In Review — PR #624 Ready for Review at reviewed head `e5b57fc5777cb3c9e3234075d3573236dc8e5c18`, full hosted CI and attribution PASS. One independent-review P3 handoff-accuracy finding is being corrected in this docs-only follow-up; check *new* exact-head gates before conditional owner-authorized merge.
**Primary owner:** `apps/app` route and provider composition; `apps/features/settings` route-state presentation
**Affected platforms:** Flutter Android/iOS phone only

## Owner Approval and Scope Boundary
**Trigger:** None — normal bounded internal engineering subtask within approved #357 / TNYX-201 app-shell refactor.
**Approval status:** Approved for this implementation subtask by owner on 2026-10-20: "Go next you are working in tio-world" after the fresh read-only audit recommending C3e as the next slice.
**Approved product/UI/data-shape boundaries:** Behavior- and pixel-preserving route ownership extraction. No product-visible UI change.
**Explicit non-changes:** No new navigation paths, screen layout, copy, design tokens, provider contracts/lifetimes, Auth/Supabase persistence, schema, AI, backend, watch, Account Settings or Nutrition. Owner subsequently authorized **conditional PR #624 merge on 2026-10-20** only after fresh audit, review-finding resolution and clean required/exact-head checks; this does not authorize broader changes.

## Active Handoff
**Planning owner:** ChatGPT architecture workflow
**Implementation owner:** ChatGPT — sole source implementation owner for C3e
**Review owner:** Independent read-only GitHub reviewer submitted `COMMENTED` review (not formal `APPROVED`): P1/P2 source findings = 0; one P3 handoff drift comment #4321508362 is being fixed. Codex automated review failed due to usage quota *before meaningful analysis*, neither a clean review nor a code finding. Implementation-owner source self-review is separately labeled.
**Implementation ownership state:** Handoff pending — source complete and PR Ready for Review; one P3 docs-only reconciliation and latest-head checks remain before authorized conditional merge.
**Ownership transition:** Not applicable
**Repository state last verified:** remote protected `main@3fe7be42c0292f05659cfc2817589c408101df27` on 2026-10-20; zero open GitHub PRs at branch creation.
**Branch:** `tnyx/issue-357-c3e-daily-wellness-route-extract`
**HEAD SHA:** Original reviewed source `b747d87ae9806f7316993ceaf1b154fb1dfbcf93`. Reviewed Ready-for-Review checkpoint `e5b57fc5777cb3c9e3234075d3573236dc8e5c18` (CI 7/7 SUCCESS). This P3-only documentation correction advances PR HEAD once more; read [live PR #624](https://github.com/im-tnyx/tio-world/pull/624) for that latest SHA and **its own** validation. Base `main@3fe7be42c0292f05659cfc2817589c408101df27`.
**Observed working-tree state:** Connector-only execution; owner Windows checkout/git status cannot be inspected. Branch created from verified remote SHA; no local working tree was modified.
**Observed uncommitted/dirty files:** Not observable locally; no unrelated GitHub PRs open at branch creation.
**PR / tracker:** GitHub #357 child of #260, Linear TNYX-201 In Progress; TNYX-154 contract-only child #514 completed/archived; TNYX-155 separately Backlog.
**Current implementation state:** Source extraction + focused destination/identity regression test complete. Root `router.dart` delegates Daily Wellness at original position to `buildDailyWellnessRoutes`; app continues watching Wellness/Hydration/Profile/Auth and wiring independent callbacks; Settings owns unchanged loading/error Scaffolds and editor. No editor code changed. Exact reviewed checkpoint `e5b57fc` was 8 commits ahead/0 behind with only six intended paths; this review-finding reconciliation is one *additional documentation-only* commit, not a production edit. Root router 612 lines (740 prior).
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/daily_wellness_routes.dart`, `apps/features/settings/lib/src/presentation/pages/daily_wellness_settings_destination.dart`, Settings presentation barrel, focused `apps/app/test/app/daily_wellness_route_test.dart`.
**Validation completed at SHA:** Source HEAD `b747d87ae9806f7316993ceaf1b154fb1dfbcf93`: [Flutter CI #39368940553](https://github.com/im-tnyx/tio-world/actions/runs/39368940553) SUCCESS (five workflow jobs and two separately verified attribution checks, 7/7). Ready checkpoint `e5b57fc5777cb3c9e3234075d3573236dc8e5c18`: [Flutter CI #39369346147](https://github.com/im-tnyx/tio-world/actions/runs/39369346147) **SUCCESS 5/5 workflow jobs**, plus **2/2 separate GitHub Commit attribution/runner checks SUCCESS** at that exact SHA. The fresh docs-only P3 correction creates a *new* PR HEAD requiring a distinct final gate. Single GoRouter, route identity/order, session key, separate Wellness/Hydration retries and old UI copy checked by source comparison.
**Validation remaining:** Confirm **new current PR HEAD** after this P3-only docs correction, all required attribution checks, applicable hosted Flutter/Dart CI, 0 unresolved review threads, main ancestry/six-path scope, mergeability and changed-file diff. Record P3 reply/resolution. Codex quota prevents an independent automated clean review; independent GitHub reviewer gave COMMENTED (not formal APPROVED). Local Flutter/`git diff --check` and device screenshot parity not observed.
**Current blocker:** Independent P3 task-handoff staleness comment #4321508362, being fixed by this documentation-only change. Zero independently demonstrated P1/P2 code defects; Codex quota hit before code analysis. Conditional merge **must wait** for reviewer-thread resolution, latest exact-head checks and fresh merge gate.
**Open review finding IDs:** One P3 #4321508362 (thread `PRRT_kwDOTOXwB86uM0Lw`), corrected in this commit; confirm reply and resolved state before merge. Independent reviewer submission is COMMENTED, not APPROVED.
**Next exact action:** Verify this docs-only correction at latest PR #624 HEAD, reply to and resolve P3 thread with evidence, check actual required/non-required CI, main ancestry, six-path diff and no new findings. Owner now authorizes conditional squash merge **only after clean gates**; do not start another source slice or archive automatically.

## Global UI / Design-System Guardrail
Read root `AGENTS.md`, `apps/features/AGENTS.md`, `apps/core/lib/src/theme/README.md`, and `.ai/tasks/design-system-token-consolidation.md`; preserve exact original Daily Wellness Scaffold, TioAppBar, BackButton, typography, spacing, retry copy, and user-scoped editor key. No new token/component or visual normalization.

## 1. Discovery
### User Outcome
Keep a single app `GoRouter` while removing Daily Wellness' mixed feature-state UI and provider logic from root `router.dart`.
### Success Criteria
Same `AppRoutes.dailyWellnessSettings` path, root navigator, route order, theme, on-screen UI, async loading/error/retry precedence, canonical Wellness and Hydration state, `ValueKey(hydrationUserId)`, null-session behavior, profile volume-unit fallback, read/write invalidation and page draft lifetime.
### Scope
- App-owned `GoRoute`, provider reads, repositories, Auth user identity and callbacks in `routing/routes/daily_wellness_routes.dart`.
- Settings-owned destination renders exact original loading/error Scaffolds and existing editor with all props, including independent hydration lifecycle, while never consuming app Riverpod providers.
- Barrel export and focused route regression coverage.
### Non-Goals
No Daily Wellness editor rewrite, Hydration storage migration, Auth session redesign, generic core components, Account route extraction or broader controller cleanup.

## 2. Codebase Exploration
### Verified Evidence
- Root `apps/app/lib/app/router.dart` 740 lines, direct Daily Wellness `GoRoute` ~130 lines (between Nutrition and Body Weight); app-owned providers come from `network_providers.dart`; `hydrationPreferencesDataProvider` is `FutureProvider.autoDispose`.
- Source baseline watches Wellness, Hydration and Profile state; extracts authenticated session user ID for editor `ValueKey`; Wellness loading/error UI shown only if null cached value; hydration loading/error visible independently in editor.
- Wellness save writes Progress-owned repository and invalidates Wellness provider. Hydration save writes Settings-owned repository and invalidates Hydration provider. Wellness retry invalidates only Wellness; hydration retry only Hydration.
- Feature `DailyWellnessSettingsPage` already consumes narrow `progress_contracts.dart` (approved TNYX-154 option A) and Settings-owned Hydration Preferences.
- Existing `daily_wellness_route_test.dart` covers loading, errors, independent hydration read/retry, save, canonical refresh, including retry invalidation; `daily_wellness_settings_page_test.dart` covers feature draft/visual interactions.
- Reference pattern: merged/archived C3d `body_weight_routes.dart` + `BodyWeightSettingsDestination`, but preserve Daily Wellness's own state/identity rules.
- Reviewed relevant `AGENTS.md`, `docs/architecture/MODULE_OWNERSHIP.md`, #260/#357, Linear TNYX-201, UI token and workflow docs, and active task index.

## 3. Clarification
**Decision:** Owner's earlier "Go next" approved bounded internal C3e implementation; the separate 2026-10-20 "Merge with gate" instruction authorizes **conditional merge** of PR #624 after a fresh successful review/CI gate, not product-visible changes or any other PR.

## 4. Architecture Design
**Route authority:** `apps/app/lib/app/router.dart` composes a single `GoRouter`; C3e route module registers exactly one route.
**Dependency/data owner:** app watches Riverpod concrete repositories/providers, retains session-scoped `hydrationUserId`, passes plain data and callbacks to Settings. Settings renders existing load/error UI and `DailyWellnessSettingsPage`; Progress owns Wellness targets.
**Alternative rejected:** moving the feature-specific loading/error Scaffolds into app route module; creates another wrong presentation owner. Also rejected generic shared loader redesign.
**Visual/behavior risks:** do not deduplicate style values in loading vs error states; avoid key replacement by wrapping the original child differently during hydration refresh; keep distinct Wellness and Hydration retries and cached-AsyncValue policy.

## 5. Implementation Plan
1. Create branch and brief from exact verified main.
2. Extract unchanged UI into Settings destination; isolate app provider/repository composition into route module.
3. Register `...buildDailyWellnessRoutes(rootNavigatorKey: rootNavigatorKey)` at existing list position.
4. Preserve existing route tests and add a narrow regression test for route-level user identity/loading precedence if needed.
5. Audit exact files, GitHub API whitespace and branch ancestry, hosted Flutter/Dart CI, attribution and review.
6. Stop at Ready for Review only after applicable gates are clean; merge needs a separate owner instruction.

## 6. Quality Review
**Validation Run:** [CI #39368940553](https://github.com/im-tnyx/tio-world/actions/runs/39368940553) at source HEAD `b747d87ae9806f7316993ceaf1b154fb1dfbcf93` SUCCESS **5/5 workflow jobs**, plus **2/2 independently inspected attribution checks**. [CI #39369346147](https://github.com/im-tnyx/tio-world/actions/runs/39369346147) at reviewed Ready HEAD `e5b57fc5777cb3c9e3234075d3573236dc8e5c18` SUCCESS **5/5 workflow jobs**, plus **2/2 separate attribution checks**, all verified. Flutter/Dart analyze and route-focused app-workout test included. New docs-only P3-fix HEAD checks must be read live before merge. This connector has not run local Windows Flutter or `git diff --check`.
**Review Findings and Resolution:** Codex attempts were quota-limited before meaningful code review—neither a clean pass nor a source defect. Implementation-owner manual source parity check found no application blocker, but is not independent APPROVED. Independent read-only GitHub review (state **COMMENTED**, not APPROVED) found P1=0/P2=0 and raised a single P3 #4321508362 about stale active task status; this documentation-only correction addresses it. Final review-thread disposition and new-HEAD checks must be inspected separately.

## 7. Final Handoff
**Changed Files:** `.ai/tasks/issue-357-c3e-daily-wellness-route.md`; `apps/app/lib/app/router.dart`; `apps/app/lib/app/routing/routes/daily_wellness_routes.dart`; `apps/app/test/app/daily_wellness_route_test.dart`; `apps/features/settings/lib/src/presentation/pages/daily_wellness_settings_destination.dart`; `apps/features/settings/lib/src/presentation/presentation.dart`.
**Actual Behavior:** Static comparison supports route/UI parity; hosted Flutter CI 7/7 passed at reviewed source HEAD, including focused route regression coverage. No independent screenshot parity or local device execution was performed.
**Known Limitations:** Connector-only execution cannot observe local Windows git, Flutter or rendered screenshots.
**Final Status:** READY FOR REVIEW (before this P3 correction), SOURCE CI VALIDATED; conditional merge authorized **only after** post-correction exact-head CI and resolved thread, not yet merged.
