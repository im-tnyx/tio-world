# TNYX-201 C3e — Nutrition Navigation Route Extraction

**Status:** Validated
**Primary owner:** apps/app routing composition
**Affected platforms:** Flutter phone app
**Completed:** 2026-09-26
**Tracker:** GitHub #401; parent #357 / #260; Linear TNYX-201

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `Go` on 2026-09-26 after fresh current-main audit and later authorized governance reconciliation and continuation on 2026-09-26.
**Approved boundary:** Move only `AppRoutes.nutritionSettings` and `AppRoutes.mealDiarySettings` registrations into new `routing/routes/nutrition_routes.dart`, preserving paths, `rootNavigatorKey`, destination pages and callbacks exactly.
**Explicit non-changes:** Meal Categories/Archived Meal Categories; Nutrition Profile/Targets/Macros/Additional Goals; `_NutritionLoadFailure`; shell More-menu shortcut; Profile/Wellness/Body/Units/Account; UI; persistence/API/Supabase/schema.

## Active Handoff

**Planning owner:** current C3e post-merge/archive reconciliation session
**Implementation owner:** None active; bounded source implementation is complete
**Review owner:** None active; exact-head review completed before merge
**Implementation ownership state:** Complete
**Repository state last verified:** `main@1bb41dd8996494113e62e0d543df53584754d8a4` after PR #402 squash merge
**Branch:** source `tnyx/tnyx-201-c3e-nutrition-navigation-routes`; archive `tnyx/tnyx-201-c3e-archive`
**HEAD SHA:** exact final reviewed head `394ea5c58089fc82ff0322e4ea873f4593936423`; merged as `1bb41dd8996494113e62e0d543df53584754d8a4`
**Observed working-tree state:** Connector/API execution only; no local working tree is available to inspect
**Observed uncommitted/dirty files:** Not applicable / not observable from connector execution
**PR / tracker:** GitHub #401 / #357 / #260; Linear TNYX-201
**Current implementation state:** Nutrition Settings and Meal Diary Settings registrations are owned by `routing/routes/nutrition_routes.dart`; mixed Nutrition repository/loading/save routes and the Meal Diary shell shortcut remain intentionally root-owned and unchanged
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/nutrition_routes.dart`, existing Nutrition route tests
**Validation completed at SHA:** `394ea5c58089fc82ff0322e4ea873f4593936423`: Flutter CI #2819 / `Analyze and test` PASS; Commit attribution guard PASS; Attribution guard runner PASS; Codex exact-head review found no major issues; unresolved review threads 0; exact PR diff trailing whitespace 0 and conflict markers 0; exactly 4 owned paths; root target registrations 0/0; Nutrition route-module registrations 1/1; mixed Nutrition routes remain root-owned; shell Meal Diary Settings shortcut unchanged; root `GoRouter(...)` 1; route-module `GoRouter(...)` 0; both moved `GoRoute` blocks equivalent ignoring indentation
**Validation remaining:** None for C3e source behavior. Archive reconciliation is docs-only.
**Current blocker:** None
**Open review finding IDs:** None; both PR #402 governance findings were resolved before merge
**Next exact action:** None for C3e. No next source slice is authorized by this archive; a fresh current-main audit plus explicit owner authorization is required before another independently scoped source slice.

## Discovery

### User Outcome

Continue router modularization without pulling Nutrition repository/loading/save workflows into routing glue.

### Success Criteria

- `buildNutritionRoutes(...)` owns exactly Nutrition Settings + Meal Diary Settings registrations.
- Root router no longer directly registers those two routes.
- Paths, `rootNavigatorKey`, destination pages and callbacks remain unchanged.
- Mixed Nutrition routes remain root-owned.
- Meal Diary shell More-menu shortcut remains unchanged.
- Single root `GoRouter(...)` authority remains.
- Existing Nutrition route tests remain green.
- No product-visible or persistence change.

## Codebase Exploration

- Root `AGENTS.md`, workflow docs, #260/#357/#401 and TNYX-201 were reconciled before implementation.
- Source base was `main@2c143408be79ab969ad39e13e72e0234766e1f05`.
- `TNYX-153` classifies Nutrition Settings presentation/navigation as Nutrition-owned.
- `TNYX-137` freezes Settings as mode-aware entry/navigation while Nutrition pages/vocabulary remain Nutrition-owned.
- Existing `nutrition_settings_route_test.dart` covers Nutrition hub and shared Meal Diary Settings destination.
- Remaining Nutrition routes include repository/provider/loading/save behavior and were excluded from C3e.

## Architecture Design

Root `router.dart` assembles `buildNutritionRoutes(rootNavigatorKey: ...)`; the new module contains only navigation glue:
- `NutritionSettingsPage` callbacks to Profile, Targets, Meal Diary Settings
- `MealDiarySettingsPage` callback to Meal Categories

## Implementation Plan

- [x] add `nutrition_routes.dart`
- [x] replace two root registrations with `...buildNutritionRoutes(...)`
- [x] preserve registration position/order
- [x] verify mixed Nutrition registrations remain root-owned
- [x] verify shell shortcut unchanged
- [x] verify one-router authority
- [x] validate exact-head scope/diff/CI/review
- [x] resolve governance review findings
- [x] squash-merge source PR #402
- [x] reconcile post-merge tracker/archive state

## Quality Review

### Final Merge Validation

```text
Exact final reviewed head: 394ea5c58089fc82ff0322e4ea873f4593936423
Flutter CI #2819 / Analyze and test: PASS
Commit attribution guard: PASS
Attribution guard runner: PASS
Codex exact-head review: no major issues
Unresolved review threads: 0
Exact PR diff: trailing whitespace 0; conflict markers 0
Changed paths: exactly 4 C3e-owned paths
Supplemental GHAS: failed before analysis because configured Copilot model returned `400 The requested model is not supported`; known non-required TNYX-256 infrastructure outage, no code-scanning finding produced
PR #402 squash merge: 1bb41dd8996494113e62e0d543df53584754d8a4
GitHub #401: closed completed
```

### Governance Findings

| ID | Severity | Status | Finding | Resolution |
|---|---|---|---|---|
| `PR402-P1-STATUS` | P1 | Resolved | Task brief used unsupported `In review` status | Restored canonical `In progress`; exact-head review clean |
| `PR402-P1-APPROVAL-TRIGGER` | P1 | Resolved | Owner Approval trigger classification missing | Recorded `New independently scoped product task/feature slice`; exact-head review clean |

## Final Handoff

### Changed Source Files

- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/routes/nutrition_routes.dart`

### Governance Files In Source PR

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-201-c3e-nutrition-navigation-routes.md`

### Actual Behavior

`AppRoutes.nutritionSettings` and `AppRoutes.mealDiarySettings` still resolve through the same `rootNavigatorKey` to the same destination pages and callbacks. Only route-registration ownership moved. Mixed Nutrition repository/loading/save route blocks remain root-owned and the Meal Diary shell shortcut is unchanged.

### Known Limitations

The remaining mixed Nutrition route blocks are intentionally not extracted by C3e. Any later source slice requires a fresh audit and separate owner authorization.

### Final Status

`VALIDATED — MERGED VIA PR #402 (1bb41dd8)`

## Archive Handoff

C3e is complete. Nutrition Settings and Meal Diary Settings navigation-only registrations are now owned by `routing/routes/nutrition_routes.dart`. No UI, persistence, API, Supabase or schema behavior changed. A future source slice requires a fresh current-main audit and explicit owner authorization.
