# Meal Diary Screen

**Surface:** Phone Nutrition primary tab
**Route:** `/nutrition` (the Nutrition shell branch renders `MealDiaryPage`)
**Primary owner:** `apps/features/nutrition`
**Status:** Date navigation, Add Food → Quick Add manual create, canonical manual MealLog persistence/read foundations, selected-day Meal Diary cards, and optimistic Quick Edit for manual entries are implemented. Delete/move, daily summary/calendar progress and the full Meal Editor remain later slices.

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
- No per-date calorie-progress decorations are supplied yet. Canonical MealLog history now exists, but the calendar ring belongs to N3's shared `DailyNutritionBudget(date)` contract; Meal Diary does not fabricate a target/denominator merely because logs can be read.
- Selected-day actual history is read through the canonical `MealLogRepository.listByLocalDate(MealLogLocalDate)` boundary and grouped through the retained Meal Categories configuration. The stored `consumedLocalDate` owns Diary-day placement; current device timezone changes do not recompute historical date identity.
- Meal Category sections use the current resolvable `MealCategory.displayName`, including retained archived categories still referenced by history. Sections are ordered by their latest actual `consumedAt`; within each section entries are newest first. User category reorder remains Settings/picker organization and does not replace actual-activity ordering.
- One durable `MealLogEntry` renders as one actionable `TioCard` with a fixed 120dp leading media area, clean title/detail content, and a near-edge top-trailing overflow action. The current runtime has no meal-image contract, so the media area truthfully renders the centered, muted `Icons.restaurant_outlined` fallback at governed `TioSize.dp40`. The persisted `mealName` is the title when present. For an unnamed entry whose `captureSource == quickAdd`, `Quick Add` is shown only as a presentation fallback; it is never persisted back into `MealLogEntry.mealName`. An unnamed entry from another source is not mislabeled as Quick Add.
- Section headers aggregate calories and protein only when every entry in that section has the nutrient fact. The header renders the governed Core apple asset before calories and the owner-approved protein asset before grams; card detail rows remain text-only. `NutritionSnapshot` distinguishes an absent nutrient from a known zero, so the Diary does not present a partial aggregate as though it were complete.
- Historical card time uses stored consumed-time context rather than `DateTime.toLocal()` on the current device. When an exact persisted UTC offset is available, the original wall-clock time is reconstructed from `consumedAt + consumedUtcOffsetMinutes` and rendered over a readable scrim at the bottom of the fixed media area without increasing card height. If only a timezone id is available and no timezone resolver can safely reconstruct it, the time label is omitted rather than guessed.
- N14 Meal Diary display preferences are live on cards. `showMealTimes` hides only the visible time label and never chronology; `mealNotesEnabled` hides note presentation without touching stored notes; `showMealNotePreview` can add at most one ellipsized note line. The default remains time ON, Meal Notes ON, preview OFF.
- History exposes explicit loading, empty and retryable error states. Changing selected dates creates a date-keyed read request, so a slower old-date response cannot overwrite a newer selected-date result.
- A contextual `+` floats at the bottom-trailing corner of the diary body. It sits above the bottom navigation by construction — the navigation is the shell `Scaffold`'s own slot — and respects the safe area when the shell hides that navigation. It steps aside while the calendar's month grid is expanded, so it never covers a date cell on a short viewport, and returns when the grid collapses. It is a Nutrition-owned composition built from core values; there is no floating action affordance in `apps/core` and `TioShell` has no action slot.
- `+` opens an **Add Food** sheet carrying the four N5 entry paths at the weights TNYX-62 specifies, not as a flat list. A describe-your-meal surface with a microphone comes first and is shaped like somewhere to type, because that is how most meals will eventually be logged; **Take a Photo** follows on a full-width card; **Quick Add** and **Search Food** share one compact row underneath as the manual fallbacks. **Quick Add** is the only one implemented. The other three are drawn as unavailable — dimmed, inert, saying `Not available yet` in their own copy, and reported as disabled to assistive technology — rather than hidden or wired to a stub. Nothing there is a live text field, so no sentence can be typed and lost.
- The Add Food sheet opts into the route's top safe area. Without that the route strips the top padding, and on a short or split-screen viewport a sheet tall enough to reach the top would put its title and close button under the status bar or a display cutout.
- **Quick Add** opens a **Manual Nutrition Editor** on the canonical `TioEditorSheet`, deliberately kept as its own screen rather than a mode of the future full Meal Editor: it is the path for someone who already knows the numbers. Its body is a large optional **Meal name** field — the governed larger rounded surface, capped at two lines because it is a title, not a notes field — then **Calories (kcal)**, **Carbs (g)**, **Protein (g)** and **Fat (g)** as simple label-left rows with a compact value box on the right.
- **Fiber and micronutrients are not rendered in Quick Add.** They are deferred from this owner-approved simple V1, not cancelled: TNYX-115 and TNYX-58 can add supported nutrients later through the shared nutrition-value contract.
- A blank optional Quick Add value means absent, not zero. Nothing typed is ever rewritten — there is no input formatter, because filtering does not reject bad input, it edits it into a different valid number. Negative, unparseable and non-finite values keep the text the reader typed and get a message on their own line beneath the row, never colour alone.
- The pinned action region is `MealLogActionFooter`, a Nutrition-owned reusable widget — not Core, because it knows meal categories, consumed date/time and that the commit is called `Log Meal`. The full Meal Editor can adopt it later, where create says `Log Meal` and edit says `Save Changes`. A single divider marks where the scrolling body ends and it begins.
- In the footer: the **Meal type** control consumes the same canonical active Meal Categories repository used by Settings. At the trailing edge, the calendar glyph shows the Quick Add draft's concrete local date and time. A brand-new editor snapshots the current local minute once, independent of the Diary day being viewed. Tapping the control opens the shared Core date/time picker presentation; future actual datetimes resolve back to the real current-local boundary rather than being retained.
- `Log Meal` now creates one canonical manual `MealLogEntry` through `MealLogRepository.createManual`. Calories is required for the V1 Quick Add commit; blank optional macros stay absent, `captureSource` is `quickAdd`, and no fake food/catalog item is fabricated. The controller owns one stable `clientMutationId` per logical create, blocks rapid duplicate submit while pending, and retries the same identity/payload when an outcome is uncertain. A failed save keeps the draft visible; an uncertain outcome locks the draft until that exact operation is reconciled. The existing `TioButton` loading contract is reused rather than introducing parallel save chrome.
- A confirmed Quick Add create closes the editor and invalidates only the affected `MealLogLocalDate` history request. If that date is currently selected the new card appears from canonical history; logging while the reader is viewing another historical Diary date never moves that selection. The create records the local calendar identity, canonical instant and exact local UTC offset without inventing an IANA timezone ID.
- Card tap and the overflow popup's only active action, `Edit`, both read the canonical row by ID immediately before opening the same Manual Nutrition Editor in `Quick Edit` mode. `Save Changes` updates the same MealLog ID with `expectedRevision`, preserves manual provenance, hidden note and unedited nutrition facts, reloads on a stale conflict before deliberate reapplication, and retries an ambiguous outcome with the exact same update facts. Confirmed success invalidates the old and new Diary dates without moving the selected date.
- Below the calendar, the selected day renders its persisted manual MealLog history when available. A successful empty read states only that nothing is logged for that day; it does not claim that the repository/history capability is unavailable.

## Target Content

- Date selector and daily calorie/macro summary.
- Meal groups with individual entries and explicit add/edit actions. Quick Add create and manual Quick Edit are implemented; delete/move and detailed Meal Editor navigation follow in later bounded slices.
- Water total and add-water action.
- Clear links to Nutrition Targets and, later, Meal Plan.

## Data And States

- Nutrition owns entries, totals, calculations, validation and deletion rules behind repository/domain contracts.
- Canonical manual MealLog persistence exists behind `MealLogRepository`, with Supabase-backed production composition and a non-durable in-memory adapter for local/test harnesses.
- The Diary selected-day read model consumes canonical actual history; it does not persist a second daily-total or presentation cache.
- Empty day, loading and read failure are implemented for selected-day history. Quick Add create and Quick Edit cover submit pending, confirmed success, retryable failure and ambiguous-outcome reconciliation; Quick Edit additionally reloads canonical state after optimistic conflict. Delete confirmation and durable offline replay remain owned by later mutation/reliability slices.
- Use safe numeric/text alternatives for all macro progress visuals.

## Adaptive Entry Behavior

- Nutrition, Home, and future Meal Plan entries open the same Nutrition-owned meal-log workflow.
- An entry may provide meal period, date, or planned-meal context, but it cannot bypass validation or write a second data model.
- If Nutrition is eligible but not directly selected, Home may make Log Meal prominent; Diary remains the canonical daily record.

## Acceptance Criteria

- An entry change updates only through Nutrition-owned state/contracts.
- Selected-day actual history groups by persisted Diary local-date identity and retained Meal Category identity.
- Meal cards preserve actual chronology even when visible meal times are hidden, and expose no action without a working contract.
- Quick Add creates through the canonical manual MealLog repository with duplicate-safe logical-operation identity and refreshes the affected Diary read model after confirmed success.
- Quick Edit updates the same canonical manual MealLog identity with optimistic revision safety and refreshes affected Diary dates without changing the current selection.
- Meal Plan is not required for the diary MVP.
- The date navigator never fabricates progress, targets, totals or entries; its calorie ring waits for the N3 budget contract.
- Meal additions from every approved entry surface eventually update the same canonical MealLog repository/read model; Quick Add is the first implemented durable create path.

## Related

- [Nutrition](nutrition.md)
- [Nutrition Targets](nutrition-targets.md)
- [Meal Plan](meal-plan.md)
