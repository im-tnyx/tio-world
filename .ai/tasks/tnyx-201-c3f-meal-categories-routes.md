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
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub API against `main@4db03ef82f7330dabfc11a11cf5439c5dc8dce81`
**Branch:** `tnyx/tnyx-201-c3f-meal-categories-routes`
**HEAD SHA:** `4db03ef82f7330dabfc11a11cf5439c5dc8dce81` at branch creation
**Observed working-tree state:** Not available through GitHub API execution
**Observed uncommitted/dirty files:** Not observable; no local dirty-state claim
**PR / tracker:** GitHub #441 / #357 / #260; Linear TNYX-201
**Current implementation state:** Brief activation before source mutation
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/nutrition_routes.dart`
**Validation completed at SHA:** Read-only source/tracker/ownership audit at base SHA
**Validation remaining:** exact diff/scope audit; hosted Flutter CI; Codex review
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Move only Meal Categories + Archived Meal Categories registrations into existing Nutrition route module.

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

- [ ] Add active task index row.
- [ ] Move the two route registrations.
- [ ] Audit exact parent-to-head paths and route counts.
- [ ] Open Draft PR and request/wait for Codex review.

## 6. Quality Review

### Validation Run

`Not run yet. GitHub API execution cannot claim local Flutter/git commands; hosted checks will be used.`

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Expected behavior-preserving route ownership move only.

### Known Limitations

No local working tree or local Flutter tool execution is available through this connector session.

### Final Status

`REVIEW`
