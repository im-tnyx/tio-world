# GitHub #357 — C3e Daily Wellness route owner extraction

**Status:** In progress
**Primary owner:** `apps/app` route and provider composition; `apps/features/settings` route-state presentation
**Affected platforms:** Flutter Android/iOS phone only

## Owner Approval and Scope Boundary
**Trigger:** None — normal bounded internal engineering subtask within approved #357 / TNYX-201 app-shell refactor.
**Approval status:** Approved for this implementation subtask by owner on 2026-10-20: "Go next you are working in tio-world" after the fresh read-only audit recommending C3e as the next slice.
**Approved product/UI/data-shape boundaries:** Behavior- and pixel-preserving route ownership extraction. No product-visible UI change.
**Explicit non-changes:** No new navigation paths, screen layout, copy, design tokens, provider contracts/lifetimes, Auth/Supabase persistence, schema, AI, backend, watch, Account Settings or Nutrition. No merge authority.

## Active Handoff
**Planning owner:** ChatGPT architecture workflow
**Implementation owner:** ChatGPT — sole source implementation owner for C3e
**Review owner:** Codex / GitHub review (plus explicitly labeled manual implementation-owner audit)
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** remote protected `main@3fe7be42c0292f05659cfc2817589c408101df27` on 2026-10-20; zero open GitHub PRs at branch creation.
**Branch:** `tnyx/issue-357-c3e-daily-wellness-route-extract`
**HEAD SHA:** `3fe7be42c0292f05659cfc2817589c408101df27` at branch creation; read live PR HEAD for subsequent changes.
**Observed working-tree state:** Connector-only execution; owner Windows checkout/git status cannot be inspected. Branch created from verified remote SHA; no local working tree was modified.
**Observed uncommitted/dirty files:** Not observable locally; no unrelated GitHub PRs open at branch creation.
**PR / tracker:** GitHub #357 child of #260, Linear TNYX-201 In Progress; TNYX-154 contract-only child #514 completed/archived; TNYX-155 separately Backlog.
**Current implementation state:** Read-only source/ownership audit complete; coding unstarted when brief written.
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/daily_wellness_routes.dart`, `apps/features/settings/lib/src/presentation/pages/daily_wellness_settings_destination.dart`, Settings presentation barrel, focused `apps/app/test/app/daily_wellness_route_test.dart`.
**Validation completed at SHA:** None yet for implementation. Existing source/main contains established focused route and page tests.
**Validation remaining:** Hosted exact-head Flutter/Dart analyze/test shards, attribution, review findings and ancestry/scope; local Flutter/`git diff --check` and visual screenshot test not observed.
**Current blocker:** None identified during source audit; gates pending.
**Open review finding IDs:** None at creation.
**Next exact action:** Preserve exact original loading/error UI while extracting provider wiring and callbacks; run hosted CI, review and gate. Do not merge.

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
**Decision:** Existing owner's "Go next" explicitly advances the audited, independent C3e subtask within approved #260/#357; behavior-preserving internal implementation only. No authorization for merge or product-visible changes.

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
**Validation Run:** Pending.
**Review Findings and Resolution:** Pending.

## 7. Final Handoff
**Changed Files:** Pending.
**Actual Behavior:** Expected behavior preservation; not yet runtime-verified.
**Known Limitations:** Connector-only execution cannot observe local Windows git, Flutter or rendered screenshots.
**Final Status:** IN PROGRESS — not merged.
