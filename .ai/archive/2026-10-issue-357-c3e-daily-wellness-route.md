# GitHub #357 — C3e Daily Wellness route owner extraction

**Status:** Validated
**Completed:** 2026-10-20
**Merged implementation:** [PR #624](https://github.com/im-tnyx/tio-world/pull/624), squash-merged to protected `main@0e09959c33a8d3ae6a0a749fe6bf3d2533b83e1f`.
**Primary owner:** `apps/app` route and provider composition; `apps/features/settings` route-state presentation
**Affected platforms:** Flutter Android/iOS phone only

## Owner Approval and Scope Boundary
**Trigger:** None — normal bounded internal engineering subtask within approved #357 / TNYX-201 app-shell refactor.
**Approval status:** Owner approved bounded C3e implementation following read-only audit, then separately instructed "Merge with gate" on 2026-10-20. Conditional squash merge was completed after exact-head review, resolved P3 and passing required/hosted checks. This does not authorize other product changes or a future archive PR merge.
**Approved product/UI/data-shape boundaries:** Behavior- and pixel-preserving route ownership extraction. No product-visible UI change.
**Explicit non-changes:** No new navigation paths, screen layout, copy, design tokens, provider contracts/lifetimes, Auth/Supabase persistence, schema, AI, backend, watch, Account Settings or Nutrition. Owner's conditional authorization applied only to completed source PR #624; this later docs-only archive PR must not be merged without distinct instruction.

## Active Handoff
**Planning owner:** ChatGPT architecture workflow
**Implementation owner:** ChatGPT — sole source implementation owner for C3e
**Review owner:** Independent read-only GitHub reviewer submitted `COMMENTED` (not formal `APPROVED`) review, P1/P2 source findings 0. Sole P3 handoff-accuracy comment #4321508362 corrected by final PR-head docs-only commit `9aac1f5440ac3fb43cb51582584b91a350a18849`, replied to in #4321528015 and thread `PRRT_kwDOTOXwB86uM0Lw` resolved before merge. Codex automated code review was quota-limited *before analysis*: neither a clean Codex pass nor code finding.
**Implementation ownership state:** Closed for the bounded C3e source child — source merged and validated. The archived and indexed historical handoff is carried by docs-only PR #625; its merge/review gate is separate. Broader TNYX-201/#260/#357 work remains active.
**Ownership transition:** Not applicable
**Repository state last verified:** remote protected `main@0e09959c33a8d3ae6a0a749fe6bf3d2533b83e1f` on 2026-10-20. PR #624 merge status and parent `3fe7be42c0292f05659cfc2817589c408101df27` verified; zero open PRs at archive-branch creation. Operator's local Windows checkout was not inspected.
**Branch:** `tnyx/issue-357-c3e-daily-wellness-route-extract`
**Final implementation PR HEAD:** `9aac1f5440ac3fb43cb51582584b91a350a18849` ([Flutter CI #39370878523](https://github.com/im-tnyx/tio-world/actions/runs/39370878523) SUCCESS 5/5 workflow jobs plus 2/2 attribution checks). Earlier source-reviewed `b747d87ae9806f7316993ceaf1b154fb1dfbcf93` and independent-review checkpoint `e5b57fc5777cb3c9e3234075d3573236dc8e5c18` both had their own passing CI. Squash merge `0e09959c33a8d3ae6a0a749fe6bf3d2533b83e1f` on main; post-merge push [Flutter CI #39371310345](https://github.com/im-tnyx/tio-world/actions/runs/39371310345) SUCCESS 5/5.
**Observed working-tree state:** Connector-only execution; owner Windows checkout/git status cannot be inspected. Branch created from verified remote SHA; no local working tree was modified.
**Observed uncommitted/dirty files:** Not observable locally; no unrelated GitHub PRs open at branch creation.
**PR / tracker:** GitHub #357 child of #260, Linear TNYX-201 In Progress; TNYX-154 contract-only child #514 completed/archived; TNYX-155 separately Backlog.
**Current implementation state:** Completed and verified on main. Root `router.dart` registers `buildDailyWellnessRoutes` once at original route position; app wires independent Wellness/Hydration/Profile/Auth state and callbacks; Settings owns unchanged route-specific loading/error Scaffolds and original editor with `ValueKey(hydrationUserId)`. No editor UI changed. Final PR #624 reviewed 9 commits ahead/0 behind with only six intended paths; last commit changed only this task brief. Root router 612 lines (740 prior).
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/daily_wellness_routes.dart`, `apps/features/settings/lib/src/presentation/pages/daily_wellness_settings_destination.dart`, Settings presentation barrel, focused `apps/app/test/app/daily_wellness_route_test.dart`.
**Validation completed at SHA:** Source `b747d87ae9806f7316993ceaf1b154fb1dfbcf93`: Flutter CI #39368940553 SUCCESS 5/5 workflow jobs plus two separate attribution checks. Ready checkpoint `e5b57fc5777cb3c9e3234075d3573236dc8e5c18`: CI #39369346147 SUCCESS 5/5 jobs plus two separate attribution checks. Final PR HEAD `9aac1f5440ac3fb43cb51582584b91a350a18849`: CI #39370878523 SUCCESS 5/5 jobs plus two separate attribution checks, required `Commit attribution guard` SUCCESS; 0 unresolved threads and six exact owned paths. Post-merge protected `main@0e09959c33a8d3ae6a0a749fe6bf3d2533b83e1f`: push Flutter CI #39371310345 SUCCESS 5/5 jobs (Analyze and test aggregate, Dart/Flutter analyze+tests, core-wear, app-workout and nutrition-onboarding). No new device screenshot comparison was run.
**Validation remaining:** None for completed C3e source implementation: PR #624 exact-head checks, reviewer P3 resolution, and post-merge CI verified. **Current archive PR #625**, not a future duplicate PR, must satisfy fresh exact-head required attribution, reviewed three-file docs-only scope, resolved P3 archive handoff finding #4321598699, and owner-authorized merge gate. Independent device screenshot parity and operator Windows git/Flutter/`git diff --check`/sync were not observed and are not claimed.
**Current blocker:** None for merged C3e source (PR #624 P3 #4321508362 resolved, no P1/P2 source defect). This archived brief's docs-only PR #625 received one independent P3 #4321598699 about self-referential future archive work; this amendment corrects the text, with thread resolution and new-head checks gated separately. Codex review was quota-limited before analysis, not a clean automated pass. GitHub #260/#357 and Linear TNYX-201 remain open.
**Open review finding IDs:** Historical implementation P3 #4321508362 (thread `PRRT_kwDOTOXwB86uM0Lw`) resolved in PR #624. Current archive PR #625 P3 #4321598699 (thread `PRRT_kwDOTOXwB86uNBnv`) addressed by this wording correction; verify posted reply/resolved state before merge. Independent reviews are COMMENTED, not formal APPROVED.
**Next exact action:** No further C3e implementation or archive/index creation: this handoff is **already in `.ai/archive/` and indexed by the current docs-only PR #625**. For this PR, resolve P3 #4321598699 and verify latest HEAD attribution, diff and merge gate; the owner separately requested conditional archive merge on 2026-10-20, and merge must occur only if gates are clean. Any genuinely new work must start with fresh GitHub #357/#260 and Linear TNYX-201 acceptance/security ownership audit; Account Settings is a separate security-sensitive slice.

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
**Decision:** Owner's earlier "Go next" approved bounded C3e implementation and separate "Merge with gate" authorized conditional source PR #624 merge; exact-head 7/7 GitHub checks passed, the sole review P3 was resolved and PR #624 was successfully squash-merged. Authorization does not extend to an archive PR or product-visible changes.

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
**Validation Run:** [Final PR-head Flutter CI #39370878523](https://github.com/im-tnyx/tio-world/actions/runs/39370878523) SUCCESS **5/5 workflow jobs** plus **2/2 GitHub attribution checks** at `9aac1f5440ac3fb43cb51582584b91a350a18849`; required attribution PASS, 0 unresolved threads. Earlier source CI #39368940553 and reviewed Ready CI #39369346147 independently passed. [Post-merge main push Flutter CI #39371310345](https://github.com/im-tnyx/tio-world/actions/runs/39371310345) SUCCESS **5/5 jobs** on merge SHA `0e09959c33a8d3ae6a0a749fe6bf3d2533b83e1f`. Connector-only execution cannot validate operator's local Windows Flutter/`git diff --check` or device screenshot parity.
**Review Findings and Resolution:** Codex automated review attempts quota-limited before meaningful analysis; neither a clean pass nor code finding. Implementation-owner manual source parity audit found no application blocker; not independent APPROVED. Independent read-only GitHub review was **COMMENTED**, not formal APPROVED, with P1=0/P2=0 and one P3 stale handoff #4321508362; docs-only final PR commit `9aac1f5` fixed it, reply #4321528015 posted and thread resolved. 0 unresolved threads at exact-head merge gate.

## 7. Final Handoff
**Changed Files:** `.ai/tasks/issue-357-c3e-daily-wellness-route.md`; `apps/app/lib/app/router.dart`; `apps/app/lib/app/routing/routes/daily_wellness_routes.dart`; `apps/app/test/app/daily_wellness_route_test.dart`; `apps/features/settings/lib/src/presentation/pages/daily_wellness_settings_destination.dart`; `apps/features/settings/lib/src/presentation/presentation.dart`.
**Actual Behavior:** Protected main verified to delegate the single Daily Wellness route via app-owned builder, retain Settings-owned loading/error/Retry destination and session-scoped `ValueKey(hydrationUserId)`. Full Flutter hosted tests passed at final PR HEAD and post-merge main, including focused app route tests; no independently rendered screenshot parity or local device execution observed.
**Known Limitations:** Connector-only GitHub/Linear execution; operator's Windows checkout state, `git status`/`git pull --ff-only`, local Flutter, `git diff --check`, and independent device screenshot parity were not observed. Codex quota was an external review failure before analysis, not a completed clean code review; independent source review was COMMENTED, not APPROVED.
**Final Status:** VALIDATED — PR #624 squash merged into protected `main@0e09959c33a8d3ae6a0a749fe6bf3d2533b83e1f` after final exact-HEAD Flutter CI 5/5 jobs plus 2/2 attribution checks and resolved P3; post-merge push Flutter CI 5/5 SUCCESS. Broader #260/#357 and TNYX-201 remain Open/In Progress.
