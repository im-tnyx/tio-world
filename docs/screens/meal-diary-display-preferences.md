# Meal Diary Display Preferences

Document Status: Canonical Live Doc
Last Verified: 2026-09-27
Owner: `apps/features/nutrition`
Truth Boundary: Authoritative for Meal Diary display-preference product rules and ownership; runtime source wins for actual shipped behavior and trackers own delivery status.

**Owner:** `apps/features/nutrition`
**Runtime slice:** TNYX-198 / N14A
**Persistence:** device-local `SharedPreferencesAsync`

Meal Diary has one canonical runtime display-preference state:

```text
showMealTimes = true
mealNotesEnabled = true
showMealNotePreview = false
showMealSectionNutrition = true
```

These values control presentation/capability only. They never mutate durable `MealLogEntry.consumedAt` or `MealLogEntry.note` data, and `showMealSectionNutrition` never changes aggregate calculation, Daily Nutrition Summary, or Nutrition Targets.

`Meal Notes` OFF makes `Show note preview` unavailable while preserving the stored preview preference and any existing MealLog note. Re-enabling Meal Notes restores the saved preview choice.

`showMealSectionNutrition` (added TNYX-204 micro-extension, 2026-09-12) is one switch for the whole trailing Calories + Protein section-header aggregate group — never separate per-nutrient toggles. OFF hides the complete group so the divider/title reclaim the freed width; it never hides calories/protein inside an individual Meal Diary card. ON renders only the canonical aggregate values that are actually known; a section missing one of the two never fabricates the other as zero.

The preferences are intentionally device-local in V1 and do not create Supabase columns, RLS, migrations, or account-synced state.

Current Meal Diary runtime:

- canonical selected-day MealLog history is rendered as live sections/cards through `MealDiaryHistoryView`;
- display preferences have a runtime owner and device-local persistence and are consumed by current cards/section headers;
- Quick Add `Log Meal` creates canonical manual MealLog rows through `MealLogRepository.createManual()`, and confirmed saves refresh affected Diary history/summary truth;
- Quick Edit is also live for canonical manual rows;
- delete/move and the broader full Meal Editor remain later bounded slices.
