# Workout Settings Screen

Document Status: Canonical Live Doc
Last Verified: 2026-11-13 (W10-A merged on main; W10-B approved implementation in separate PR)
Owner: `apps/features/workout`
Truth Boundary: Authoritative for Workout Settings ownership and behavior; runtime source wins for actual implementation, and current PR/CI status is tracked independently.

**Surface:** Nested Phone Workout configuration
**Route:** `/settings/workout`
**Primary owner:** `apps/features/workout`
**Status:** W10-A Default Rest Timer is merged via PR #753; W10-B Rest Timer Vibration is a separately approved, review-gated slice. Other Workout Settings remain planned.

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

## Rest Timer Vibration — W10-B (review-gated)

Workout Settings adds a separate device-local **Rest Timer Vibration**
switch, default OFF. Its boolean preference uses an owner-scoped
`SharedPreferencesAsync` key and is never written to Supabase. A vibration
read/write failure must not block Default Rest, Add Exercise or Save. A
read failure remains retryable independently.

When enabled before a Rest starts, a successful foreground natural expiry
may send one best-effort platform vibration. Both the Save-only draft and
legacy online Active Workout paths share the same one-shot eligibility logic;
manual Skip, Cancel, OFF, countdown cancellation by adjustment, logged Set
removal, background expiry and restored already-expired countdowns stay
silent. No music/audio, background alarms, notification service or Wear/watch
haptics are included. The platform may suppress haptics; this does not affect
workout data or countdown state.

W10-B does not change the existing per-Exercise Rest Timer, UTC deadlines,
Draft recovery, Workout pause rules or Routine composition persistence.

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
