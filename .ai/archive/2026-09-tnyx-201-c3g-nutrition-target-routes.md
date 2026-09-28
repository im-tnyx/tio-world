# TNYX-201 C3g — Nutrition Targets route extraction

**Status:** Validated
**Completed:** 2026-09-28
**Primary owner:** `apps/app` routing composition

## Outcome

Behavior-preserving extraction completed. Nutrition Targets, Macros, and Additional Goals route registrations moved from root `apps/app/lib/app/router.dart` into existing `apps/app/lib/app/routing/routes/nutrition_routes.dart`.

## Scope and ownership

The slice preserved paths, root navigator identity, loading/error/retry/save behavior, provider invalidation, child navigation, and one-root-`GoRouter` authority. Existing `_NutritionLoadFailure` presentation stayed root-owned through an explicit builder callback; `profileDataProvider` remained app composition. UI, persistence, Supabase/API/schema, and feature-domain redesign were excluded.

## Validation and merge evidence

- GitHub issue #445 completed through PR #446.
- Exact final reviewed head `7f1df1342098c5ee7f8f535b6cddf4dfcb91b44c`.
- Hosted Flutter CI run `36372861624` / #2834: PASS.
- Codex exact-head review: no major issues.
- Unresolved review threads before merge: 0.
- Pre-merge compare: 7 ahead / 0 behind with exactly three scoped paths.
- PR #446 squash-merged as `d82609e25388178763c6e3e74962725c83105702`; GitHub #445 closed completed.

## Durable architecture

Route registration/composition remains app-shell ownership; Nutrition pages/domain behavior remain Nutrition-owned. The extraction did not create a new router authority or move feature business rules into app routing.

## Final Status

`PASS`
