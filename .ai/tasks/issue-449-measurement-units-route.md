# Issue #449 — Measurement Units route extraction

**Status:** In progress
**Primary owner:** `apps/app` composition root
**Affected platforms:** Flutter phone routing

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Internal behavior- and pixel-preserving router refactor under existing #357 / #260 / TNYX-201 scope.
**Approved product/UI/data-shape boundaries:** No product-visible or data-shape change.
**Explicit non-changes:** Daily Wellness, Body & Weight, Account Settings, Nutrition Profile, feature UI, persistence, Supabase, API, schema.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Codex
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main@a77654532337111039dd3e2f8cd620b7c8c9b07e`
**Branch:** `tnyx/issue-449-measurement-units-route`
**HEAD SHA:** Branch created from verified main baseline; current head is tracked by GitHub.
**Observed working-tree state:** Connector-only execution; local working tree unavailable.
**Observed uncommitted/dirty files:** Not observable through connector.
**PR / tracker:** GitHub #449; parents #357/#260; Linear TNYX-201.
**Current implementation state:** Measurement Units route registration moved into existing Settings route module; exact scope audit passed.
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/settings_routes.dart`, existing router tests.
**Validation completed at SHA:** `f0ef82aa56fab3b0a7dc6daac5af83b5e4db54ad` — GitHub compare: 4 ahead / 0 behind; exactly this handoff plus two app routing files.
**Validation remaining:** Exact diff scope, hosted checks, exact-head Codex review.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Open Draft PR and request exact-head Codex review; hosted checks remain required if triggered.

## 1. Discovery

### User Outcome
Keep routing architecture maintainable without changing Measurement Units behavior or UI.

### Success Criteria
- One root `GoRouter` remains.
- `AppRoutes.measurementUnitsSettings` is registered by `buildSettingsRoutes`.
- Existing profile hydration, loading/error handling, save and provider invalidation remain unchanged.
- Existing route coverage remains valid.

### Scope
Only the Measurement Units route registration and dependencies needed by the existing settings route module.

### Non-Goals
No other route extraction or product/runtime behavior change.

## 2. Codebase Exploration

### Verified Evidence
- Source/config inspected: root/nested AGENTS, architecture ownership docs, router, settings route module, existing router coverage.
- Existing pattern to follow: prior behavior-preserving route extractions into `routing/routes/*`.
- Tests or validation already present: `apps/app/test/app/app_mode_router_test.dart` covers Measurement Units navigation/hydration.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Extract only Measurement Units | Made | Smallest coherent remaining settings-owned route | Architecture |
| Preserve route-local loading/error UI exactly | Made | Refactor must not alter product behavior | Architecture |

## 4. Architecture Design

### Chosen Approach
Move the existing `GoRoute` unchanged in behavior into `buildSettingsRoutes`; add only imports required for the same providers/repository.

### Ownership and Data Flow
```text
App route composition -> Settings page -> Profile/unit preference providers -> existing repository
```

### Alternative Rejected
Combining Daily Wellness, Body & Weight or Account Settings was rejected because those routes have broader ownership/security/data-flow concerns.

### Failure and Accessibility States
Preserve existing loading, error, retry/back and save behavior.

## 5. Implementation Plan
- [x] Move Measurement Units route registration.
- [x] Remove only now-unused root-router imports if proven unused.
- [x] Audit exact diff and existing coverage.
- [ ] Open Draft PR and request exact-head Codex review.

## 6. Quality Review

### Validation Run
```text
GitHub compare at `f0ef82aa56fab3b0a7dc6daac5af83b5e4db54ad`: 4 ahead / 0 behind; changed paths are only this handoff, `router.dart`, and `settings_routes.dart`. Existing `app_mode_router_test.dart` already covers Measurement Units navigation/hydration. Connector-only execution cannot claim local Flutter or git CLI validation.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files
- `.ai/tasks/issue-449-measurement-units-route.md`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/routes/settings_routes.dart`

### Actual Behavior
No intended behavior change: the existing Measurement Units `GoRoute` now registers through `buildSettingsRoutes` with the same root navigator, profile hydration/loading state, initial preferences, repository save, and profile-provider invalidation.

### Known Limitations
Local CLI validation unavailable through connector.

### Final Status
`REVIEW`
