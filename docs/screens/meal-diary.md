# Meal Diary Screen

**Surface:** Phone Nutrition primary tab
**Route:** `/nutrition` (the Nutrition shell branch renders `MealDiaryPage`)
**Primary owner:** `apps/features/nutrition`
**Status:** Date navigation is implemented and live. Meal logging, totals and persistence are not; no diary data source exists yet.

## Purpose

Show today's meals and water entries, make approved entries easy to add or correct, and connect those entries to Nutrition-owned daily targets.

## Implemented Today

- The reusable core `TioDateCalendar` is the diary's date navigator: a compact horizontal date strip that expands, from its centered transparent notch and distinct grabber, into an inline month grid on the same screen.
- Both renderings navigate only by horizontal swipe: compact pages by week and expanded pages by month. The calendar has no month title or previous/next arrow row.
- Tapping outside an expanded calendar collapses it to the compact week rendering; interactions inside the calendar do not dismiss it.
- The localized `SUN` header and Sunday date numerals use semantic danger styling; selected/Today Sundays are full-strength while ordinary Sundays are softer.
- Nutrition owns only the thin adapter — `selectedDate`, `localToday`, a bounded history window and `maxDate = localToday`, so future dates are unreachable.
- When another day is selected or the calendar is paged away from the range containing Today, the Nutrition top bar shows the approved calendar glyph immediately left of the fixed right-side streak without a redundant gap. Today's day number appears inside the glyph; tapping it selects Today and returns the viewport to Today's week/month. It is absent only when Today is selected and visible, and its appearance never moves the streak.
- First day of week is not owned here. It is one app-global Calendar Preferences value; until that resolver exists the calendar falls back to the platform locale.
- No per-date decorations are supplied, because no meal-log data exists. Missing progress stays missing rather than being drawn as zero.
- Below the calendar the selected day shows its date and states plainly that meal logging is not available yet.

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
- The date navigator never fabricates progress, totals or entries before a real data source exists.
- Meal additions from every approved entry surface update the same diary state and saved/pending status.

## Related

- [Nutrition](nutrition.md)
- [Nutrition Targets](nutrition-targets.md)
- [Meal Plan](meal-plan.md)
