# Issue #445 — C3g Nutrition Targets route extraction

**Status:** Active
**Owner authorization:** “Go agent.md follow kare”
**Base:** `main@f3646625fd9286b1f7b783f88afd25d36d86a8ea`
**GitHub:** #445
**Parents:** #357, #260
**Linear:** TNYX-201 planning mirror is Done; TNYX-69 owns Nutrition Targets product behavior.

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

## Next action

Implement the smallest behavior-preserving extraction, audit exact diff, open Draft PR, then wait for CI/Codex review.
