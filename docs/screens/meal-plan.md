# Meal Plan Screen

**Surface:** Future nested Phone Nutrition flow
**Route:** No route exists yet
**Primary owner:** `apps/features/nutrition`
**Status:** Deferred until after the first Nutrition diary MVP.

## Purpose

Let the user create, schedule, and reuse meal plans after the Meal Diary has a stable data model. Meal Plan is not a guided default tab; after implementation, a future custom layout may promote its canonical route as a shortcut.

## Target Content

- Plan list and plan detail with intended dates/meals.
- Create, edit, schedule, duplicate, and apply actions only after the diary contract is stable.
- A next-planned-meal summary that Home may preview and Wear may show only as a compact status.

## Data And Boundaries

- Nutrition owns plan content, schedule rules, validation, and diary application behavior.
- First define how applying a plan affects existing diary entries and whether an action is reversible.
- No full Meal Plan editing is permitted on Wear OS.
- Loading, empty plan, conflict, failed save, offline/pending, and delete/archive confirmation states are required.

## Adaptive Entry Behavior

- A `Log This Meal` action passes the planned meal/date/meal-period context to the same Nutrition-owned meal-log workflow used by Meal Diary.
- Promotion changes direct access and selected-destination presentation only; it does not create a separate diary, plan application rule, or save path.
- When Meal Plan is not promoted, Nutrition and Home may show a next-planned-meal preview after the feature exists.

## Acceptance Criteria

- Meal Plan arrives only after the first Nutrition diary MVP is complete.
- Applying a plan is explicit and cannot silently overwrite logged meals.
- Home and Wear receive only prepared compact status data through approved contracts.
- Nested and promoted-shortcut entry paths open the same plan state and preserve explicit apply/log behavior.

## Related

- [Nutrition](nutrition.md)
- [Meal Diary](meal-diary.md)
- [Wear Home](wear-home.md)
