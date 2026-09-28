# Issue #445 — C3g Nutrition Targets route extraction

**Status:** In progress
**Owner authorization:** “Go agent.md follow kare”
**Base:** `main@f3646625fd9286b1f7b783f88afd25d36d86a8ea`
**GitHub:** #445
**Parents:** #357, #260
**Linear:** TNYX-201 is In Progress for active C3g; TNYX-69 owns Nutrition Targets product behavior.

## Goal

Extract only Nutrition Targets, Macros, and Additional Goals route registration/composition from `apps/app/lib/app/router.dart` into existing `routing/routes/nutrition_routes.dart` while preserving runtime behavior and ownership.

## Audit classification

- App shell owns route registration and concrete provider/repository injection.
- Nutrition feature owns pages, editor behavior, target semantics and validation.
- Existing route-local loading/error/retry composition must remain behavior-equivalent; do not redesign UI or migrate business rules.
- If a clean composition seam cannot preserve this boundary, stop and split a new approved ownership slice.

## In scope

- `AppRoutes.nutritionTargetsSettings`
- `AppRoutes.nutritionMacrosSettings`
- `AppRoutes.nutritionAdditionalGoalsSettings`
- explicit composition inputs required by those routes
- focused route/reference validation

## Out of scope

Nutrition Profile/Settings/Meal Diary routes; feature/domain/controller redesign; UI/copy/theme changes; provider lifetime changes; Supabase/API/schema/persistence changes; unrelated router cleanup.

## Required invariants

Paths, root navigator key, loading/error/retry/save behavior, target repository/provider invalidation, child navigation, and one-root-GoRouter authority remain unchanged.

## Validation

Hosted Flutter CI + exact parent/head diff/reference audit + Codex review. Local git/Flutter commands are unavailable in this connector session and must not be claimed.

## Review findings

Use only `Open`, `Resolved`, or `Deferred`.

| ID | Severity | Status | Finding | Resolution |
|---|---|---|---|---|

## Implementation state

Implemented the bounded extraction. The three target route registrations now live in `routing/routes/nutrition_routes.dart`. Root injects the existing `_NutritionLoadFailure` presentation through `NutritionLoadFailureBuilder`, so C3g does not relocate or duplicate that UI. `profileDataProvider` remains app composition and is imported narrowly for the read-only Additional Goals dependency.

API audit against base: 3 commits ahead / 0 behind before this handoff sync; effective diff is exactly this brief, `router.dart`, and `nutrition_routes.dart`. Root no longer registers the three target routes; the Nutrition route module does. No local git/Flutter commands were claimed.

## Validation completed at reviewed source head `cd6ba69fea2742357aa5a098ff10a909faaed391`

- Hosted Flutter CI run `36369097629`: PASS.
- Codex exact-head review: no major issues.
- Unresolved review threads: 0.
- Parent compare: 5 ahead / 0 behind with exactly this brief, `router.dart`, and `routing/routes/nutrition_routes.dart`.

## Validation completed at handoff head `dd2f76e6f929f61c3be3785d54b0adc703c28883`

- Hosted Flutter CI run `36369961738`: PASS.
- Codex exact-head review: no major issues.
- Unresolved review threads: 0.
- Current parent compare: 6 ahead / 0 behind with exactly this brief, `router.dart`, and `routing/routes/nutrition_routes.dart`.
- Runtime source is unchanged since reviewed source head `cd6ba69fea2742357aa5a098ff10a909faaed391`; the intervening change was handoff evidence only.

## Validation remaining

This documentation-only reconciliation commit requires exact-head hosted CI/Codex validation before merge readiness.

## Next action

Request exact-head CI/Codex on this documentation-only reconciliation. If clean with 0 unresolved threads and unchanged scope, mark PR Ready for Review; merge still requires explicit owner authorization.
