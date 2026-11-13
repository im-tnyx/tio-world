# Workout Settings Screen

Document Status: Canonical Live Doc
Last Verified: 2026-11-13 (W10-A/B merged; W10-C in separate review-gated branch)
Owner: `apps/features/workout`
Truth Boundary: Authoritative for Workout Settings ownership and behavior; runtime source wins for actual implementation, and current PR/CI status is tracked independently.

**Surface:** Nested Phone Workout configuration
**Route:** `/settings/workout`
**Primary owner:** `apps/features/workout`
**Status:** W10-A and W10-B merged via PRs #753/#754; W10-C RPE Tracking is a separate approved, review-gated slice. Other Workout Settings remain planned.

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

## Rest Timer Vibration — W10-B (merged)

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

## RPE Tracking — W10-C (review-gated)

**RPE Tracking** is a device-local, authenticated-owner-scoped Workout
Settings switch, default **OFF**. It uses the existing SharedPreferencesAsync
Workout adapter and key `workout_rpe_tracking_enabled_v1_<ownerId>`.
It is not a cross-device or Supabase preference.

- **ON:** Show the existing RPE header and editable per-Set RPE picker in the
  Save-only Log Workout draft, including 320dp phones.
- **OFF:** Hide both RPE header and picker and return width to the existing Set
  fields. Previously entered draft, recovered or completed Set RPE values
  are not cleared; turning ON shows those values again.
- Missing, malformed or unreadable preference defaults to OFF; the Workout
  Settings row provides an independent Retry on read failure. Failure does not
  block Add Exercise, Rest Timer or Workout Save.
- Save-only Log Workout listens for live preference changes without creating
  another session or rewriting stored Set data.

The existing RPE picker and draft-to-completed-snapshot Save flow are reused.
Legacy online Active Workout has no per-Set RPE write implementation; W10-C
does not extend that path, History Edit or overall Workout RPE. No new RPE
scale, Supabase schema, migration, RLS or RPC is part of this slice.

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
