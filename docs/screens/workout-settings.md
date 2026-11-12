# Workout Settings Screen

Document Status: Canonical Live Doc
Last Verified: 2026-11-12 (W10-A source branch; PR/CI handoff pending)
Owner: `apps/features/workout`
Truth Boundary: Authoritative for Workout Settings ownership and behavior; runtime source wins for actual implementation, and the W10-A PR/CI handoff remains pending.

**Surface:** Nested Phone Workout configuration
**Route:** `/settings/workout`
**Primary owner:** `apps/features/workout`
**Status:** W10-A implements the bounded Default Rest Timer preference. Other Workout Settings remain planned and are not implied by this slice.

## Purpose

Let the user manage Workout-specific preferences and plan defaults. Root Settings exposes the page only when Workout is an active guided destination. Workout owns the form, behavior and persistence; Settings owns only navigation.

## Default Rest Timer — W10-A

The page contains a **Default Rest Timer** row showing `OFF` or the current
duration. It opens the existing `showRoutineRestTimerSheet` with
`hasWarmUpSets: false`; Done writes the selection and Cancel discards it.
Durations are OFF or 5-second steps up to 600 seconds.

The preference is a device-local Workout setting stored in owner-scoped
`SharedPreferencesAsync` under
`workout_default_rest_timer_seconds_v1_<ownerId>`. Missing/unset remains
distinct from a saved OFF value (`0`); unset resolves to OFF when initializing
a new Exercise. This value is never synced to Supabase.

Each newly added Exercise receives the current default once in:

- Routine Create.
- Routine Edit.
- Log Workout's existing account-bound Save-only active draft.

The Exercise's current Rest Timer wheel remains editable after initialization.
Changing it updates the Exercise's existing effective rest; OFF suppresses the
next eligible countdown. Later changes to the global default do not change
previously added Exercises, saved Routines, or active draft Exercises. Routine
values remain in canonical `SetPrescription.restSeconds`; explicit OFF is
persisted as `null`. Active Workout preserves the choice in its existing
`restPreset` and `hasRestOverride` draft/recovery fields. The existing
countdown engine and controls are reused.

No Supabase schema, migration, RLS, RPC or sync behavior is part of W10-A.

## Target Content

- Training goal and preferred split.
- Experience level, available equipment, training days, and session-duration preference.
- Training goal, preferred split, experience level, equipment, training days, session duration and workout units remain future scope.
- Profile-derived suggestions versus confirmed Workout overrides require their own approved scope.

## Data And Rules

- Profile context may provide defaults through a stable pure-Dart contract.
- An explicit Workout setting wins over a later profile change until the user accepts a new suggestion.
- Saving a setting must explain which future Routine/Program recommendations it can affect; it must not silently rewrite completed history or active sessions.
- Validation, discard confirmation, save success/failure, offline/pending state, and reset-to-profile-default behavior are required before release.

## Acceptance Criteria

- The root Settings row appears in Workout and Hybrid modes and is hidden in Nutrition mode.
- The initial Rest Time for new Exercises reflects the current device-local default and can be edited immediately.
- Default changes affect new additions only; Routine persistence and active draft recovery retain each Exercise's chosen value, including OFF.
- Remaining Workout preferences stay hidden until separately implemented.

## Related

- [Workout](workout.md)
- [Profile](profile.md)
- [Settings](settings.md)
