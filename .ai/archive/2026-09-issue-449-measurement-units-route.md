# Issue #449 — Measurement Units route extraction

**Status:** Validated
**Completed:** 2026-09-28
**Primary owner:** `apps/app` routing composition

## Outcome

Behavior-preserving extraction completed. `AppRoutes.measurementUnitsSettings` registration moved from root `apps/app/lib/app/router.dart` into the existing `apps/app/lib/app/routing/routes/settings_routes.dart` assembly.

## Scope and ownership

The slice preserved the route path, root navigator identity, profile hydration/loading behavior, initial unit preferences, repository save callback, `profileDataProvider` invalidation, existing navigation, and one-root-`GoRouter` authority. Daily Wellness, Body & Weight, Account Settings, Nutrition Profile, UI, persistence, API, Supabase/schema, and feature business behavior were excluded.

## Validation and merge evidence

- GitHub issue #449 completed through PR #450.
- Exact final reviewed head: `ef61bae5024a258d425c43609472cf332c6970b6`.
- Hosted Flutter CI run `36414567880` / #2840: PASS.
- Earlier hosted CI correctly exposed two missing dependency imports and one later unused import; all were corrected before the final reviewed head.
- Codex exact-head review on `ef61bae502...`: no major issues.
- Unresolved review threads before merge: 0.
- Final PR state before merge: Ready, mergeable, exact head unchanged.
- PR #450 squash-merged as `b8dc48a8ddfd3dd6fadb994f964f305f7627c4ac`; GitHub #449 closed completed.
- Connector-only execution could not run or claim local `git status`, `flutter analyze`, or `flutter test`; hosted CI is the recorded validation source.

## Durable architecture

Route registration/composition remains app-shell ownership. Measurement Units presentation and preference behavior remain with their existing owners; this extraction did not introduce a second router authority or move feature business logic into routing.

## Tracker note

GitHub #357 and parent #260 remain open for the remaining router ownership audit. At archive time Linear TNYX-201 reads `Done` while its description still contains an older C3g-active snapshot; this archive does not treat that stale planning state as proof that #357/#260 acceptance is complete.

## Final Status

`PASS`
