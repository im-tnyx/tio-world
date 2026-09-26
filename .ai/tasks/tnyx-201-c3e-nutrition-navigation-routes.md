# TNYX-201 C3e — Nutrition Navigation Route Extraction

**Status:** In progress
**Primary owner:** apps/app routing composition
**Affected platforms:** Flutter phone app
**Tracker:** GitHub #401; parent #357 / #260; Linear TNYX-201

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `Go` on 2026-09-26 after fresh current-main audit and later authorized governance reconciliation and continuation on 2026-09-26.
**Approved boundary:** Move only `AppRoutes.nutritionSettings` and `AppRoutes.mealDiarySettings` registrations into new `routing/routes/nutrition_routes.dart`, preserving paths, `rootNavigatorKey`, destination pages and callbacks exactly.
**Explicit non-changes:** Meal Categories/Archived Meal Categories; Nutrition Profile/Targets/Macros/Additional Goals; `_NutritionLoadFailure`; shell More-menu shortcut; Profile/Wellness/Body/Units/Account; UI; persistence/API/Supabase/schema.

## Active Handoff

**Implementation owner:** current C3e implementation session
**Implementation ownership state:** Complete
**Repository base last verified:** `main@2c143408be79ab969ad39e13e72e0234766e1f05`
**Branch:** `tnyx/tnyx-201-c3e-nutrition-navigation-routes`
**Validated source/docs head:** `65105180d2f5c11c36e7c879affb1916e254241b`
**Current implementation state:** implementation complete; only the two approved navigation-only registrations moved; mixed Nutrition routes and the Meal Diary shell shortcut remain untouched.
**Validation remaining:** verify current docs-only head required checks and exact-head review after governance reconciliation; confirm no source scope changed before merge.
**Current blocker:** No product/source blocker. Two PR #402 P1 governance findings are addressed by this docs-only reconciliation and remain pending exact-head verification/thread resolution. Supplemental GitHub AI code scanning remains affected by tracked non-required TNYX-256 infrastructure outage.
**Open review findings:** `PR402-P1-STATUS` (canonical task status) and `PR402-P1-APPROVAL-TRIGGER` (Owner Approval trigger classification), both addressed in this docs-only reconciliation and pending exact-head verification.
**Next exact action:** verify the current branch head required checks and exact-head review; resolve the two PR #402 governance threads only after the fix is confirmed. Merge only when current-head required checks are satisfied and no new review/scope blocker exists; then follow `docs/POST_MERGE_SYNC.md` and reconcile Linear/GitHub/archive state before starting another source slice.

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
- [x] reconcile final review-ready state with GitHub and Linear

## Quality Review

Validated exact head `65105180d2f5c11c36e7c879affb1916e254241b`: Flutter CI #2817 / `Analyze and test` full PASS (bootstrap, Flutter analyze, Dart analyze, Flutter tests, Dart tests); Commit attribution guard PASS; Attribution guard runner PASS; Codex exact-head review found no major issues; unresolved review threads 0; exact PR diff trailing whitespace 0 and conflict markers 0; API scope 6 ahead / 0 behind with exactly 4 owned paths; root target registrations 0/0; module registrations 1/1; mixed Nutrition routes remain root-owned; shell Meal Diary Settings shortcut unchanged; root `GoRouter(...)` 1; module `GoRouter(...)` 0; both moved `GoRoute` blocks equivalent ignoring indentation.

The later governance-only heads do not invalidate that source validation, but current-head required checks/review must pass before merge. PR #402 review at `d4472852c94db68b6e167ea478f3f015ee053e8f` identified two P1 task-governance findings: unsupported `In review` status and missing Owner Approval trigger classification. This reconciliation restores canonical `In progress` status and records `New independently scoped product task/feature slice` as the approved trigger without changing source scope.

Supplemental `github-advanced-security` failed before repository analysis at `Processing Request (Linux)` because GitHub's configured Copilot model returned `400 The requested model is not supported`. This is tracked separately as TNYX-256, is not a code/security finding, is not a security pass, and is not a required branch-protection context for `main`.

## Final Handoff

`REVIEW` — bounded implementation is complete and review-ready. Source/docs validation is complete at `65105180d2f5c11c36e7c879affb1916e254241b`; later changes are governance-only. The current branch head must satisfy required checks and exact-head review, and the two P1 governance threads must be resolved after verification, before merge. After merge, run the repository post-merge sync/archive/tracker flow before authorizing another source slice.
