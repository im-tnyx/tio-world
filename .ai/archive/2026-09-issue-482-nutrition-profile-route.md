# GitHub #482 — Nutrition Profile route extraction

**Status:** Validated
**Completed:** 2026-09-30
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
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub `main@32d7ecabe9a09fe7b00e96f7aae239e567196fb8`
**Branch:** `tnyx/issue-482-nutrition-profile-route`
**HEAD SHA:** final PR head `227918ad1d9f1052634f85200193b1e2ba8e3078`; squash merge `32d7ecabe9a09fe7b00e96f7aae239e567196fb8`
**Observed working-tree state:** Connector-only execution; local worktree is unavailable and no local cleanliness claim is made.
**Observed uncommitted/dirty files:** Not observable through the GitHub connector.
**PR / tracker:** PR #483 merged; GitHub #482 closed; parents #357/#260 open; Linear TNYX-201 In Progress
**Current implementation state:** Merged and validated. Nutrition Profile route registration is owned by existing `nutrition_routes.dart`; root registration/import is removed; focused failed-read + Retry route coverage is merged.
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/nutrition_routes.dart`, `apps/app/test/app/nutrition_settings_route_test.dart`
**Validation completed at SHA:** final PR head `227918ad1d9f1052634f85200193b1e2ba8e3078`: Flutter CI run `36667055255` / #2869 PASS. Source/review head `bbd8c975118f0bf0f419cb1f511838be8ba44d2f` received a clean Codex review. Delayed final-head Codex review produced two handoff-only P2 findings after merge; both are resolved by GitHub #484 archive reconciliation.
**Validation remaining:** Docs-only archive follow-up #484 exact-head Codex review.
**Current blocker:** None.
**Open review finding IDs:** None. Resolved delayed findings: `PRRT_kwDOTOXwB86nYehR`, `PRRT_kwDOTOXwB86nYehf`.
**Next exact action:** Archive this validated brief through GitHub #484 and complete its docs-only Codex gate.

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
- [x] Open Draft PR #483.
- [x] Source/review head `bbd8c975...`: Flutter CI #2868 PASS + Codex clean.
- [x] Exact final PR head `227918ad...`: Flutter CI #2869 PASS.
- [x] PR #483 squash-merged as `32d7ecabe9a09fe7b00e96f7aae239e567196fb8`.
- [x] Reconcile delayed final-head Codex handoff findings through #484.

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
| — | — | Clean | Codex found no major issues on the unchanged production/test source | `bbd8c975118f0bf0f419cb1f511838be8ba44d2f` | Exact-head review comment on PR #483 |
| `PRRT_kwDOTOXwB86nYehR` | P2 | Resolved | Handoff had stale Draft/older-head validation snapshot | `227918ad1d9f1052634f85200193b1e2ba8e3078` | This #484 reconciliation records Ready/final head, CI #2869, and merge evidence |
| `PRRT_kwDOTOXwB86nYehf` | P2 | Resolved | Top-level `In review` status is unsupported | `227918ad1d9f1052634f85200193b1e2ba8e3078` | Status corrected to `Validated`; ownership state corrected to `Complete` |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/issue-482-nutrition-profile-route.md`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/routes/nutrition_routes.dart`
- `apps/app/test/app/nutrition_settings_route_test.dart`

### Actual Behavior

No intended behavior change. Nutrition Profile still uses the same route path/root navigator, canonical provider read/loading/failure/retry flow, `NutritionProfileSettingsPage`, repository `upsert`, and provider invalidation; only the registration owner moved from root router into the existing Nutrition route module.

### Known Limitations

Local worktree and local Flutter commands were unavailable in this connector-only execution; hosted Flutter CI #2869 is the recorded final runtime validation source. The delayed final-head Codex review identified only handoff-governance issues, not production/test behavior defects.

### Final Status

`PASS`
