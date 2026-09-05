# Meal Diary Screen

**Surface:** Phone Nutrition primary tab
**Route:** `/nutrition` (the Nutrition shell branch renders `MealDiaryPage`)
**Primary owner:** `apps/features/nutrition`
**Status:** Date navigation is implemented and live, and the Add Food → Quick Add entry flow now exists as a UI shell. Saving a meal, totals and persistence are not implemented; no diary data source exists yet.

## Purpose

Show today's meals and water entries, make approved entries easy to add or correct, and connect those entries to Nutrition-owned daily targets.

## Implemented Today

- Top bar: `Diary` on the left, the currently visible calendar month and year in the centre (`Sep ’26`), then the Today action and the streak on the right. The centre answers *where am I in the calendar*, which is a different question from the Today action's *take me back to now*, and it follows the visible page rather than the selection — a reader can keep August 18 selected while swiping through September. A week split across two months reports the month its midpoint falls in.
- Naming: the bottom-navigation tab keeps the domain name **Nutrition**; the screen's own root top-bar title is **Diary**. `Meal Diary` remains the canonical feature identity used by the folder, the page class and these docs — `Diary` is only the compact visible title.
- The reusable core `TioDateCalendar` is the diary's date navigator: a compact horizontal date strip that expands, from its centered transparent notch and distinct grabber, into an inline month grid on the same screen.
- Both renderings navigate only by horizontal swipe: compact pages by week and expanded pages by month. The calendar has no month title or previous/next arrow row.
- Tapping outside an expanded calendar collapses it to the compact week rendering; interactions inside the calendar do not dismiss it.
- The localized `SUN` header and Sunday date numerals use semantic danger styling; selected/Today Sundays are full-strength while ordinary Sundays are softer.
- Nutrition owns only the thin adapter — `selectedDate`, `localToday`, a bounded history window and `maxDate = localToday`, so future dates are unreachable.
- When another day is selected or the calendar is paged away from the range containing Today, the Nutrition top bar shows the approved calendar glyph immediately left of the fixed right-side streak without a redundant gap. Today's day number appears inside the glyph; tapping it selects Today and returns the viewport to Today's week/month. It is absent only when Today is selected and visible, and its appearance never moves the streak.
- The local day advances without leaving the screen: the page owns a one-shot timer aimed at the next local calendar boundary and also refreshes on app resume. A historical selection is never moved by the rollover; only `localToday` and `maxDate` advance.
- First day of week is not owned here. `apps/app` resolves the Settings-owned app-global Calendar Preferences value and passes it through `MealDiaryPage` as `resolvedFirstDayOfWeek`; Nutrition forwards it to `TioDateCalendar` without persisting, resolving or caching a second preference. Core's nullable input still permits its locale fallback when no resolved value is supplied.
- No per-date decorations are supplied, because no meal-log data exists. Missing progress stays missing rather than being drawn as zero.
- A contextual `+` floats at the bottom-trailing corner of the diary body. It sits above the bottom navigation by construction — the navigation is the shell `Scaffold`'s own slot — and respects the safe area when the shell hides that navigation. It steps aside while the calendar's month grid is expanded, so it never covers a date cell on a short viewport, and returns when the grid collapses. It is a Nutrition-owned composition built from core values; there is no floating action affordance in `apps/core` and `TioShell` has no action slot.
- `+` opens an **Add Food** sheet showing the four N5 entry paths. **Quick Add** is the only one implemented. Natural-language entry, photo capture and food-database search are drawn as unavailable — dimmed, chevron-less, inert, labelled `Not available yet`, and reported as disabled to assistive technology — rather than hidden or wired to a stub.
- **Quick Add** opens a **Manual Nutrition Editor** on the canonical `TioEditorSheet`: optional meal name, calories, and optional protein, carbs, fat and fiber. A blank optional field means the value is absent, not zero. Negative and unparseable values are rejected with a message under the field, not by colour alone.
- The editor is handed the diary's selected date **by value** and shows it read-only. It is never given the date controller, so opening, typing in, or dismissing either sheet cannot move the selected day. Meal category is absent because no canonical `MealCategory` exists yet (N13 owns it), and consumed time is absent because TNYX-114 owns time and local-date semantics.
- `Log Meal` is rendered and permanently disabled, above a line saying that saving is not available yet. Nothing in this flow persists anything — no entry, no draft, no local store, no Supabase write — so backing out of either sheet leaves no history and no retained input. Durable history arrives through TNYX-113 → TNYX-114 → TNYX-115.
- Below the calendar the selected day shows its date and states plainly that nothing is logged for it and that meals cannot be saved yet.

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
