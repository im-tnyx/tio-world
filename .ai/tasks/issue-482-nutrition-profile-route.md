# GitHub #482 — Nutrition Profile route extraction

**Status:** In progress
**Primary owner:** `apps/app` routing composition
**Affected platforms:** Flutter Android + iOS

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `Go` on 2026-09-30 after the fresh current-main audit identified Nutrition Profile as the next bounded router-modularization slice.
**Approved product/UI/data-shape boundaries:** Behavior-preserving route-registration extraction only; focused regression coverage for the existing Nutrition Profile load-error/retry route state.
**Explicit non-changes:** No UI redesign, route/path change, Nutrition feature/package restructure, persistence semantics, Supabase/schema/RLS/API change, Daily Wellness, Body & Weight, Account Settings, Profile/Profile Avatar, or TNYX-153 implementation.

## Active Handoff

**Planning owner:** ChatGPT / repository architecture workflow
**Implementation owner:** ChatGPT
**Review owner:** Codex after PR creation
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub `main@6cec394956b37bd2901b9c21ca754b785e80e19c`
**Branch:** `tnyx/issue-482-nutrition-profile-route`
**HEAD SHA:** `925d67cf0ccb6bfc3eaa453d4e8b0a1df516ea79` after source + focused test implementation
**Observed working-tree state:** Connector-only execution; local worktree is unavailable and no local cleanliness claim is made.
**Observed uncommitted/dirty files:** Not observable through the GitHub connector.
**PR / tracker:** GitHub #482; parents #357/#260; Linear TNYX-201
**Current implementation state:** Nutrition Profile route registration moved into existing `nutrition_routes.dart`; root registration/import removed; focused failed-read + Retry route coverage added.
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/nutrition_routes.dart`, `apps/app/test/app/nutrition_settings_route_test.dart`
**Validation completed at SHA:** Audit only on `main@6cec3949...`
**Validation remaining:** hosted Flutter CI; exact-head Codex review; final merge-readiness audit.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Open Draft PR from the audited four-path branch, then use hosted Flutter CI and exact-head Codex review as merge gates.

## 1. Discovery

### User Outcome

Preserve the existing Nutrition Profile Settings behavior while reducing root router catch-all ownership by placing this Nutrition-owned route registration alongside the other Nutrition route registrations.

### Success Criteria

- `router.dart` no longer directly registers `AppRoutes.nutritionProfileSettings`.
- `nutrition_routes.dart` owns the registration with the same root navigator, read/loading/error/retry/save/invalidation behavior.
- Existing `_NutritionLoadFailure` presentation is reused through `NutritionLoadFailureBuilder`; no new presentation owner is created.
- Focused route coverage proves a failed Nutrition Profile read shows the existing error and Retry re-reads the canonical provider.
- Hosted Flutter CI and exact-head Codex review are clean before merge readiness.

### Scope

- Move the one Nutrition Profile route block.
- Remove root imports made unused by that move, only if proven unused.
- Add focused route-level load-failure/retry regression coverage.

### Non-Goals

- Daily Wellness, Body & Weight, Account Settings, Profile/Profile Avatar.
- Nutrition package feature-first restructure / TNYX-153.
- UI, copy, geometry, theme, route/path, deep-link, provider-lifetime, persistence, schema/RLS/API changes.
- Refactoring `_NutritionLoadFailure` into a feature-owned widget in this slice.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `apps/features/AGENTS.md`, #260, #357, TNYX-201, TNYX-137, TNYX-153, `MODULE_OWNERSHIP.md`, current `router.dart`, `nutrition_routes.dart`, Nutrition composition providers, and `nutrition_settings_route_test.dart`.
- Existing pattern to follow: `nutrition_routes.dart` already owns Nutrition Targets/Macros/Additional Goals using the same providers and injected `NutritionLoadFailureBuilder`.
- Tests or validation already present: route navigation + canonical save/data-preservation coverage exists; exact Nutrition Profile load-error/retry coverage does not.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep `_NutritionLoadFailure` root-owned and inject it | Approved | Avoids silently moving feature presentation while #357 explicitly requires classification first | App routing |
| Reuse existing `nutrition_routes.dart` | Approved | Stable owner module already exists; no new abstraction needed | App routing |
| Add focused error/retry test | Approved | Existing tests do not lock this route state | App tests |
| Leave TNYX-153 untouched | Approved | Package restructure is a separate Backlog architecture slice | Nutrition |

## 4. Architecture Design

### Chosen Approach

Move the existing `GoRoute` block verbatim in behavior into `buildNutritionRoutes`. Replace direct `_NutritionLoadFailure` construction with the already-existing `loadFailureBuilder` callback used by sibling Nutrition routes.

### Ownership and Data Flow

```text
apps/app router assembly
  -> buildNutritionRoutes(...)
    -> nutritionProfileDataProvider
      -> NutritionProfileRepository
    -> NutritionProfileSettingsPage
      -> onSave -> NutritionProfileRepository.upsert
      -> invalidate nutritionProfileDataProvider
```

### Alternative Rejected

Creating a new Nutrition-specific route module or moving loading/error UI into `apps/features/nutrition` would widen the approved slice and duplicate/reopen ownership decisions already separated by #357/TNYX-153.

### Failure and Accessibility States

Preserve the current loading scaffold and existing shared retryable Nutrition failure UI/copy exactly. No new visual state is introduced.

## 5. Implementation Plan

- [x] Move Nutrition Profile route registration into `nutrition_routes.dart`.
- [x] Remove only proven-unused root Nutrition imports.
- [x] Add focused failed-read + Retry route test.
- [x] Audit exact branch diff for scope.
- [ ] Open Draft PR and run hosted CI + Codex gate.

## 6. Quality Review

### Validation Run

```text
Static branch audit complete at `925d67cf0ccb6bfc3eaa453d4e8b0a1df516ea79`:
- 4 changed paths total (task brief + router + nutrition route module + focused app test)
- root direct Nutrition Profile registrations: 0
- Nutrition route module direct Nutrition Profile registrations: 1
- root `tio_feature_nutrition` import removed after becoming unused
- focused failed-read + Retry test present

Local Flutter commands were not run because connector-only execution has no local worktree/toolchain. Hosted CI remains required.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `.ai/tasks/issue-482-nutrition-profile-route.md`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/routes/nutrition_routes.dart`
- `apps/app/test/app/nutrition_settings_route_test.dart`

### Actual Behavior

No intended behavior change. Nutrition Profile still uses the same route path/root navigator, canonical provider read/loading/failure/retry flow, `NutritionProfileSettingsPage`, repository `upsert`, and provider invalidation; only the registration owner moved from root router into the existing Nutrition route module.

### Known Limitations

Local worktree and local Flutter commands are unavailable in this connector-only execution; hosted CI will be the recorded runtime validation source.

### Final Status

`PARTIAL`
