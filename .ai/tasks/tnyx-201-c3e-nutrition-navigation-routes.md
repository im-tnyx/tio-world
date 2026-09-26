# TNYX-201 C3e — Nutrition Navigation Route Extraction

**Status:** In progress
**Primary owner:** apps/app routing composition
**Affected platforms:** Flutter phone app
**Tracker:** GitHub #401; parent #357 / #260; Linear TNYX-201

## Owner Approval and Scope Boundary

**Approval status:** Approved
**Approval evidence:** Owner said `Go` on 2026-09-26 after fresh current-main audit.
**Approved boundary:** Move only `AppRoutes.nutritionSettings` and `AppRoutes.mealDiarySettings` registrations into new `routing/routes/nutrition_routes.dart`, preserving paths, `rootNavigatorKey`, destination pages and callbacks exactly.
**Explicit non-changes:** Meal Categories/Archived Meal Categories; Nutrition Profile/Targets/Macros/Additional Goals; `_NutritionLoadFailure`; shell More-menu shortcut; Profile/Wellness/Body/Units/Account; UI; persistence/API/Supabase/schema.

## Active Handoff

**Implementation owner:** current C3e implementation session
**Implementation ownership state:** Active
**Repository state last verified:** `main@2c143408be79ab969ad39e13e72e0234766e1f05`
**Branch:** `tnyx/tnyx-201-c3e-nutrition-navigation-routes`
**Current implementation state:** two navigation-only Nutrition route registrations moved into new `nutrition_routes.dart`; mixed Nutrition routes and shell shortcut untouched
**Validation remaining:** exact PR diff audit, exact-head Flutter CI, independent review
**Current blocker:** None
**Next exact action:** open focused Draft PR, validate exact-head diff/CI/review, then reconcile review state

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

- Root `AGENTS.md`, workflow docs, #260/#357/#401 and TNYX-201 reconciled.
- Base `main@2c143408be79ab969ad39e13e72e0234766e1f05`.
- No open PR overlap found in the preceding fresh audit.
- `TNYX-153` classifies Nutrition Settings presentation/navigation as Nutrition-owned.
- `TNYX-137` freezes Settings as mode-aware entry/navigation while Nutrition pages/vocabulary remain Nutrition-owned.
- Existing `nutrition_settings_route_test.dart` covers Nutrition hub and shared Meal Diary Settings destination.
- Remaining Nutrition routes include repository/provider/loading/save behavior and are excluded from C3e.

## Architecture Design

Root `router.dart` assembles `buildNutritionRoutes(rootNavigatorKey: ...)`; new module contains only navigation glue:
- `NutritionSettingsPage` callbacks to Profile, Targets, Meal Diary Settings
- `MealDiarySettingsPage` callback to Meal Categories

## Implementation Plan

- [x] add `nutrition_routes.dart`
- [x] replace two root registrations with `...buildNutritionRoutes(...)`
- [x] preserve registration position/order
- [x] verify mixed Nutrition registrations remain root-owned
- [x] verify shell shortcut unchanged
- [x] verify one-router authority
- [ ] validate exact-head scope/diff/CI/review

## Quality Review

API scope/invariant audit at source checkpoint: 4 ahead / 0 behind; exactly 4 owned paths; root target registrations 0/0; module registrations 1/1; mixed Nutrition routes remain root-owned; shell Meal Diary Settings shortcut count 1; root `GoRouter(...)` 1; module `GoRouter(...)` 0; source trailing whitespace 0; conflict markers 0; both moved `GoRoute` blocks equivalent ignoring indentation.

## Final Handoff

`REVIEW` — bounded implementation is complete; exact-head PR/CI/review remain.
