# Meal Diary Display Preferences

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

Current Meal Diary status after TNYX-197/TNYX-198:

- durable manual MealLog selected-day repository reads exist;
- display preferences now have a runtime owner and local persistence;
- the current Diary page still does not render actual MealLog cards/sections;
- Quick Add still opens its editor without enabling `Log Meal` persistence;
- TNYX-57 owns later Diary section/card rendering and consumes these preferences;
- TNYX-115 owns later Quick Add create/edit lifecycle activation.
