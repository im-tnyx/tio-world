# TNYX-201 C3f — Meal Categories route registrations

**Status:** In progress
**Primary owner:** `apps/app` routing composition
**Affected platforms:** Flutter phone

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said “Next go” on 2026-09-28 and authorized work through PR creation, then wait for Codex bot review.
**Approved product/UI/data-shape boundaries:** Behavior-preserving app-shell route-registration extraction only.
**Explicit non-changes:** No visible UI, route path, redirect, provider contract, persistence, API, Supabase, schema, Nutrition business rule, or feature workflow change.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Codex bot after PR creation
**Implementation ownership state:** Review
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub API against `main@336d3b7d012a323e4f6744f6a724ddf2eb0a7e72` after PR #444 merge
**Branch:** `tnyx/tnyx-201-c3f-meal-categories-routes`
**HEAD SHA:** `cab1d19172f31ab7e2ed0adde3df9c7b2f5e84b0` — reconciled head reviewed by Codex; handoff correction follows this head
**Observed working-tree state:** Not available through GitHub API execution
**Observed uncommitted/dirty files:** Not observable; no local dirty-state claim
**PR / tracker:** GitHub PR #442 / issue #441 / #357 / #260; Linear TNYX-201
**Current implementation state:** Bounded implementation complete; Draft PR #442 open
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/nutrition_routes.dart`
**Validation completed at SHA:** `cab1d19172f31ab7e2ed0adde3df9c7b2f5e84b0` — against current `main@336d3b7d...`: 8 ahead / 0 behind, exactly 4 C3f paths; hosted Flutter CI run `36365642286` passed
**Validation remaining:** exact-head CI and Codex re-review after this handoff-only correction
**Current blocker:** Codex P2 `discussion_r4117795252` requires this handoff to reflect the reconciled head
**Open review finding IDs:** Codex P2 `discussion_r4117795252` — reconciled-head handoff anchor
**Next exact action:** Revalidate this handoff-only correction, reply/resolve `discussion_r4117795252` if verified, then request exact-head Codex review and wait for hosted CI.

## 1. Discovery

### User Outcome

Continue #260/#357 router modularization without changing Nutrition behavior.

### Success Criteria

- Existing Nutrition route module owns Meal Categories and Archived Meal Categories registration.
- Repository injection, page destinations, archived navigation and root navigator identity remain equivalent.
- Mixed Nutrition load/save routes stay root-owned.
- One root `GoRouter` authority remains.

### Scope

- `AppRoutes.mealCategoriesSettings`
- `AppRoutes.archivedMealCategoriesSettings`
- required app-composition import for `mealCategoriesRepositoryProvider`

### Non-Goals

Nutrition Profile/Targets/Macros/Additional Goals; `_NutritionLoadFailure`; Wellness/Body/Units/Profile/Account; UI; persistence; Supabase/API/schema.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, workflow, feature-development contract, task rules, PR/push templates, current router and Nutrition route module.
- Applicable nested `apps/AGENTS.md` and `apps/app/AGENTS.md` do not exist.
- Existing pattern to follow: C3e `buildNutritionRoutes(...)` ownership module.
- Current Meal Categories blocks are composition glue: Riverpod `Consumer`, app-owned repository provider injection, feature-owned pages and one navigation callback.
- Remaining Nutrition targets/profile routes contain loading/error/save workflows and are intentionally excluded.
- Canonical architecture keeps route registration/composition in `apps/app` and Nutrition presentation/business behavior in the Nutrition feature.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Reuse existing `nutrition_routes.dart` | Decided | Avoid duplicate route owners/new abstractions | apps/app |
| Move only two Meal Categories routes | Decided | Smallest ownership-clear seam | apps/app |
| Keep repository provider app-owned | Decided | Existing composition contract | apps/app |

## 4. Architecture Design

### Chosen Approach

Extend `buildNutritionRoutes(...)` with the two existing route blocks, adding Riverpod and the existing app composition provider import as required. Remove only those blocks from root router.

### Ownership and Data Flow

`GoRoute -> Consumer -> mealCategoriesRepositoryProvider -> Nutrition-owned page`

### Alternative Rejected

Bundling Nutrition Targets/Profile/Macros/Additional Goals was rejected because those blocks mix async state, loading/error presentation and persistence callbacks.

### Failure and Accessibility States

No state or UI behavior changes; existing feature-owned behavior remains unchanged.

## 5. Implementation Plan

- [x] Add active task index row.
- [x] Move the two route registrations.
- [x] Audit exact parent-to-head paths and route counts.
- [x] Open Draft PR.
- [x] Receive Codex review on `26f812e277b718d7fc04e79e6f279f970b7bbbaa`.
- [x] Address original Codex P2 stale audit-anchor finding.
- [x] Reconcile latest `main@336d3b7d...` into the branch without history rewrite.
- [x] Verify reconciled head `cab1d191...`: 8 ahead / 0 behind, exactly 4 C3f diff paths, Flutter CI pass.
- [x] Address reconciled-head Codex P2 in this handoff.

## 6. Quality Review

### Validation Run

`GitHub API scope audit at reconciled head cab1d19172f31ab7e2ed0adde3df9c7b2f5e84b0 against current main 336d3b7d012a323e4f6744f6a724ddf2eb0a7e72: 8 ahead / 0 behind; exactly 4 C3f paths. The merged #444 test/task files are inherited from main and do not appear in the PR diff. Root route counts for Meal Categories/Archived remain 0/0; Nutrition module owns both registrations; one root GoRouter authority remains. Hosted Flutter CI run 36365642286 passed on cab1d191. Local Flutter/git commands are unavailable through this connector session.`

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| C3F-REV-01 | P2 | Resolved | Completed audit was anchored to an earlier head. | `26f812e277b718d7fc04e79e6f279f970b7bbbaa` | Fixed in `d3644dc...`; thread resolved and later exact-head review was clean. |
| C3F-REV-02 | P2 | Open | After merging latest main, handoff still described the pre-reconciliation head/audit. | `cab1d19172f31ab7e2ed0adde3df9c7b2f5e84b0` | Handoff now records current main, reconciled head, 8/0 scope audit and passing hosted CI; this docs-only correction requires exact-head revalidation. |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-c3f-meal-categories-routes.md`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/routes/nutrition_routes.dart`

### Actual Behavior

Meal Categories and Archived Meal Categories route registration moved to the existing Nutrition route module with the same paths, root navigator, repository provider injection, pages and archived navigation callback.

### Known Limitations

No local working tree or local Flutter tool execution is available through this connector session.

### Final Status

`REVIEW`
