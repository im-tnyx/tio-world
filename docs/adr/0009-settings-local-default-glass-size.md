# ADR-0009: Default Glass Size is a local Settings convenience preference

- **Status:** Accepted
- **Date:** 2026-08-29
- **Supersedes:** [ADR-0008](0008-settings-hydration-preferences-owner.md)

## Context

Default Glass Size supplies the amount for a future “add one glass” action. It
is not hydration history, a health target, or account data. Draft review of
S0-B2 found that an account-synced Supabase table would create unnecessary
schema and ownership surface before any hydration logging product exists.

## Decision

- `apps/features/settings` owns the bounded `HydrationPreferences` domain,
  repository and local `SharedPreferencesAsync` adapter.
- The stored key is device-local `default_glass_size_ml`; it stores canonical
  integer ml. Missing, corrupt or cleared state reads as the real 250 ml default.
- The editor offers 200/250/300/350/500 ml presets, valid 50–2000 ml custom
  values in 10 ml steps, and `Reset to Default`.
- `apps/app` only composes the repository and clears it at explicit successful
  account boundaries. Ordinary restart and restored sessions retain the value.
- No Supabase table, migration, RLS policy, Profile/App Preferences field,
  Shared domain owner, or hydration log is created by this decision.

## Alternatives

- Account-synced `public.user_hydration_preferences`: superseded before merge;
  the unmerged repository migration is removed. Remote migration history may
  remain stale from the earlier draft and requires a separate authorized repair.
- Progress, Nutrition, `WellnessTargetsData`, Profile or a new hydration package:
  each would broaden a domain owner without a hydration logging workflow.

## Consequences

Future logging must consume this local default until a separately approved
logging/storage design replaces it. Water Goal remains an independent Wellness
target, and global Volume Unit remains display-only.

## Links

- [TNYX-130](https://linear.app/tnyx/issue/TNYX-130)
- [Settings screen](../screens/settings.md)
- [Module ownership](../MODULE_OWNERSHIP.md)
- [Execution brief](../../.ai/tasks/settings-s0b2-default-glass-size.md)
