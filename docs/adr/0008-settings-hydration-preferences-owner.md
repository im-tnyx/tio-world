# ADR-0008: Settings owns the bounded HydrationPreferences contract

- **Status:** Superseded by [ADR-0009](0009-settings-local-default-glass-size.md)
- **Date:** 2026-08-29

## Context

> Historical record: this account-synced Supabase-table decision was superseded
> during Draft PR #170 review, before merge. The replacement is local-only
> `SharedPreferencesAsync` storage in [ADR-0009](0009-settings-local-default-glass-size.md).

S0-B2 needs an account-synced Default Glass Size preference. It is the amount
represented by a future +1 glass action, independent of Daily Water Goal and
global Volume Unit. No canonical hydration-logging package currently exists.
The owner explicitly approved Settings package ownership for this bounded slice.

## Decision

- `apps/features/settings/lib/src/domain` owns `HydrationPreferences` and
  `HydrationPreferencesRepository`; `lib/src/data` owns its Supabase adapter.
- Settings presentation owns the summary/editor. App only constructs repositories,
  supplies canonical read state, and injects dependencies.
- Dedicated storage target: `public.user_hydration_preferences`, own-row RLS,
  nullable integer ml. No row/null means Not set. No implicit default/backfill.
- This intentionally supersedes the generic Settings-consumer restriction ONLY
  for HydrationPreferences. Existing Wellness, Body, Units, Profile, App Mode and
  Nutrition owners remain unchanged.
- Future hydration logging consumes this contract; it must not introduce a second
  Glass Size store. Logging itself is not part of this decision's implementation.

## Alternatives

- Progress: would broaden ownership without an existing hydration workflow.
- New hydration package: premature for a single Settings preference.
- Shared, WellnessTargetsData, Profile, Nutrition, App Preferences or local
  SharedPreferences: would violate the approved semantic/storage boundary.

## Consequences

One small existing package owns validation and persistence, with an independent
repository despite Water Goal sharing its visual card. Future consumers depend
on the stable domain contract, not the Settings editor. Any later extraction
requires an explicit ownership change preserving this single canonical value.

Architecture acceptance does not mean database deployment or device acceptance.
Remote migration application remains separately authorized.

## Links

- [TNYX-130](https://linear.app/tnyx/issue/TNYX-130)
- [Settings screen](../screens/settings.md)
- [Module ownership](../MODULE_OWNERSHIP.md)
- [Execution brief](../../.ai/tasks/settings-s0b2-default-glass-size.md)
