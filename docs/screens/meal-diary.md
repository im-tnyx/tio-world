# Meal Diary Screen

**Surface:** Nested Phone Nutrition flow
**Route:** No route exists yet
**Primary owner:** `apps/features/nutrition`
**Status:** Planned as the Nutrition MVP; no diary source is verified in the current code.

## Purpose

Show today's meals and water entries, make approved entries easy to add or correct, and connect those entries to Nutrition-owned daily targets.

## Target Content

- Date selector and daily calorie/macro summary.
- Meal groups with individual entries and explicit add, edit, and remove actions.
- Water total and add-water action.
- Clear links to Nutrition Targets and, later, Meal Plan.

## Data And States

- Nutrition owns entries, totals, calculations, validation, and deletion rules.
- First release must define local persistence before it claims saved tracking.
- Empty day, no target, loading, malformed entry, save pending, failed save, delete confirmation, and offline/stale states are required.
- Use safe numeric/text alternatives for all macro progress visuals.

## Adaptive Entry Behavior

- Nutrition, Home, and future Meal Plan entries open the same Nutrition-owned meal-log workflow.
- An entry may provide meal period, date, or planned-meal context, but it cannot bypass validation or write a second data model.
- If Nutrition is eligible but not directly selected, Home may make Log Meal prominent; Diary remains the canonical daily record.

## Acceptance Criteria

- An entry change updates only through Nutrition-owned state/contracts.
- A user can tell whether an entry is saved locally, pending sync, or failed.
- Meal Plan is not required for the diary MVP.
- Meal additions from every approved entry surface update the same diary state and saved/pending status.

## Related

- [Nutrition](nutrition.md)
- [Nutrition Targets](nutrition-targets.md)
- [Meal Plan](meal-plan.md)
