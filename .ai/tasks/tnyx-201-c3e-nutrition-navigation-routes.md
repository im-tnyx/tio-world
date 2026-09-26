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
**Implementation ownership state:** Complete
**Repository state last verified:** `main@2c143408be79ab969ad39e13e72e0234766e1f05`
**Branch:** `tnyx/tnyx-201-c3e-nutrition-navigation-routes`
**Current implementation state:** implementation complete and validated at source/docs head `32dc360a4819770c196f7e0af0a27f42d061a4b6`; mixed Nutrition routes and shell shortcut untouched
**Validation remaining:** final governance-only head revalidation after this handoff update
**Current blocker:** None
**Next exact action:** revalidate final governance-only head, then mark PR #402 Ready for Review; do not merge without explicit owner instruction

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
- [x] validate source/docs exact-head scope/diff/CI/review

## Quality Review

Validated source/docs head `32dc360a4819770c196f7e0af0a27f42d061a4b6`: Flutter CI #2816 full PASS (bootstrap, Flutter analyze, Dart analyze, Flutter tests, Dart tests); Commit attribution guard PASS; Attribution guard runner PASS; Codex exact-head review found no major issues; unresolved review threads 0; exact PR diff trailing whitespace 0 and conflict markers 0; API scope 5 ahead / 0 behind with exactly 4 owned paths; root target registrations 0/0; module registrations 1/1; mixed Nutrition routes remain root-owned; shell Meal Diary Settings shortcut count 1; root `GoRouter(...)` 1; module `GoRouter(...)` 0; both moved `GoRoute` blocks equivalent ignoring indentation; supplemental GHAS failed before analysis with `400 The requested model is not supported` (known TNYX-256 external outage, no security finding produced).

## Final Handoff

`REVIEW` — bounded implementation is validated; final governance-only head revalidation remains.
