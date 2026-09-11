# Meal Diary Display Preferences

**Owner:** `apps/features/nutrition`
**Runtime slice:** TNYX-198 / N14A
**Persistence:** device-local `SharedPreferencesAsync`

Meal Diary has one canonical runtime display-preference state:

```text
showMealTimes = true
mealNotesEnabled = true
showMealNotePreview = false
```

These values control presentation/capability only. They never mutate durable `MealLogEntry.consumedAt` or `MealLogEntry.note` data.

`Meal Notes` OFF makes `Show note preview` unavailable while preserving the stored preview preference and any existing MealLog note. Re-enabling Meal Notes restores the saved preview choice.

The preferences are intentionally device-local in V1 and do not create Supabase columns, RLS, migrations, or account-synced state.

Current Meal Diary status after TNYX-197/TNYX-198:

- durable manual MealLog selected-day repository reads exist;
- display preferences now have a runtime owner and local persistence;
- the current Diary page still does not render actual MealLog cards/sections;
- Quick Add still opens its editor without enabling `Log Meal` persistence;
- TNYX-57 owns later Diary section/card rendering and consumes these preferences;
- TNYX-115 owns later Quick Add create/edit lifecycle activation.
