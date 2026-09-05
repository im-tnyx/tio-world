# ADR-0010: Calendar first day of week is a local Settings preference

- **Status:** Accepted
- **Date:** 2026-09-05
- **Supersedes:** None

## Context

Calendars across Tio need one consistent week-start policy, while individual
features still own their selected dates, visible ranges and date availability.
The V1 product contract offers every day of the week with Monday as the
default. Monday, Sunday and Saturday cover most conventions in use, and the
other four are offered because a reader may prefer one and the reusable
calendar's week arithmetic already accepts any
`DateTime.monday`..`DateTime.sunday` start.

This value is the reader's preferred calendar week boundary. It is deliberately
not derived from any feature's cycle: a training block or meal plan beginning
on a Wednesday is a domain concept, and coupling it to the global calendar
preference would need a separate product decision.

A display convention does not need account data, remote sync or a new Supabase
schema.

## Decision

- `apps/features/settings` owns the bounded `CalendarPreferences` model,
  repository contract and device-local `SharedPreferencesAsync` adapter.
- V1 stores stable machine values `monday` through `sunday` under the local
  key `calendar_first_day_of_week`; missing, unknown or corrupt state resolves
  to Monday. Display names are formatted from the locale, never persisted.
- `apps/app` constructs and hydrates one reactive controller, resolves the
  saved preference to a `DateTime.monday`..`DateTime.sunday` value, and passes
  that generic value through composition to every calendar consumer.
- The discoverable path is `Settings → App Preferences → Calendar → First day
  of week`, with immediate apply and no Save button. The chosen value is
  published before the device-local write completes and rolled back if the
  write fails, so a slow store cannot hold the UI on the old week start.
- `MealDiaryPage` forwards the resolved value to `TioDateCalendar` but does
  not persist, resolve locale behavior, or cache a second preference.
- Core retains its nullable `resolvedFirstDayOfWeek` locale fallback for
  callers that supply no explicit resolved value. That fallback is not exposed
  as a V1 Settings option; there is no `automatic` persisted value.
- No Supabase table, migration, RLS policy, account preference field, remote
  sync or backend API is part of this decision.

## Alternatives

- Per-feature week-start preferences: rejected because they would let
  Nutrition, Workout, Meal Plan or Progress calendars disagree.
- Automatic/System as a V1 choice: rejected by the locked product contract;
  the reusable Core fallback remains only for generic callers.
- Monday and Sunday only: rejected after review. It cannot express a plan whose
  week starts mid-cycle, and restricting the option list bought nothing because
  Core already lays out any start day.
- Supabase/account persistence: rejected because a device display convention
  does not require account data and the owner explicitly chose local-only V1.

## Consequences

The app has one source of truth and runtime changes can reframe all consumers
without changing selected-date or feature-range ownership. The setting is
device-specific rather than account-synced, and future support for an explicit
automatic mode would require a separate product decision while preserving the
saved-versus-resolved boundary.

## Links

- [TNYX-72 execution brief](../../.ai/tasks/tnyx-72-global-calendar-preferences.md)
- [Settings screen](../screens/settings.md)
- [Meal Diary screen](../screens/meal-diary.md)
- [Module ownership](../MODULE_OWNERSHIP.md)
