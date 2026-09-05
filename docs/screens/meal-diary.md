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
- `+` opens an **Add Food** sheet carrying the four N5 entry paths at the weights TNYX-62 specifies, not as a flat list. A describe-your-meal surface with a microphone comes first and is shaped like somewhere to type, because that is how most meals will eventually be logged; **Take a Photo** follows on a full-width card; **Quick Add** and **Search Food** share one compact row underneath as the manual fallbacks. **Quick Add** is the only one implemented. The other three are drawn as unavailable — dimmed, inert, saying `Not available yet` in their own copy, and reported as disabled to assistive technology — rather than hidden or wired to a stub. Nothing there is a live text field, so no sentence can be typed and lost.
- The Add Food sheet opts into the route's top safe area. Without that the route strips the top padding, and on a short or split-screen viewport a sheet tall enough to reach the top would put its title and close button under the status bar or a display cutout.
- **Quick Add** opens a **Manual Nutrition Editor** on the canonical `TioEditorSheet`, deliberately kept as its own screen rather than a mode of the future full Meal Editor: it is the path for someone who already knows the numbers. Its body is a large optional **Meal name** field — the governed larger rounded surface, capped at two lines because it is a title, not a notes field — then **Calories (kcal)**, **Carbs (g)**, **Protein (g)** and **Fat (g)** as simple label-left rows with a compact value box on the right.
- **Fiber and micronutrients are not rendered.** They are deferred from this owner-approved simple V1, not cancelled: TNYX-115 and TNYX-58 can add supported nutrients later through the shared nutrition-value contract.
- A blank optional value means absent, not zero. Nothing typed is ever rewritten — there is no input formatter, because filtering does not reject bad input, it edits it into a different valid number. Negative, unparseable and non-finite values keep the text the reader typed and get a message on their own line beneath the row, never colour alone.
- The pinned action region is `MealLogActionFooter`, a Nutrition-owned reusable widget — not Core, because it knows meal categories, consumed date/time and that the commit is called `Log Meal`. The full Meal Editor can adopt it later, where create says `Log Meal` and edit says `Save Changes`. A single divider marks where the scrolling body ends and it begins.
- In the footer: a neutral **Meal type** control with its chevron, visible but **disabled** — TNYX-67 owns category identity, so no Breakfast/Lunch/Dinner/Snacks state is invented here; and at the trailing edge the calendar glyph with the diary's **selected** date and an unresolved `· Time`, also **disabled**, because TNYX-114 owns consumed-time semantics and there is no correct time to show. Neither control can be changed, and neither can move the diary's selected day. The earlier standalone disabled Date field is superseded by this footer.
- `Log Meal` spans the footer width and is permanently disabled, above one short line saying that saving is not available yet. Nothing in this flow persists anything — no entry, no draft, no local store, no Supabase write — so backing out of either sheet leaves no history and no retained input. Durable history arrives through TNYX-113 → TNYX-114 → TNYX-115.
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
