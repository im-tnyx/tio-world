# Workout Settings Screen

**Surface:** Nested Phone Workout configuration
**Route:** No route exists yet
**Primary owner:** `apps/features/workout`
**Status:** Planned only.

## Purpose

Let the user manage Workout-specific preferences and plan defaults. It is reachable from Workout and from a Settings launch entry, but Settings does not own the form, calculation, or validation.

## Target Content

- Training goal and preferred split.
- Experience level, available equipment, training days, and session-duration preference.
- Workout units and rest/default logging preferences when those behaviors are implemented.
- A clear indication of profile-derived suggestion versus a user-confirmed Workout override.

## Data And Rules

- Profile context may provide defaults through a stable pure-Dart contract.
- An explicit Workout setting wins over a later profile change until the user accepts a new suggestion.
- Saving a setting must explain which future Routine/Program recommendations it can affect; it must not silently rewrite completed history or active sessions.
- Validation, discard confirmation, save success/failure, offline/pending state, and reset-to-profile-default behavior are required before release.

## Acceptance Criteria

- The form contains only Workout-owned choices.
- Profile values and user overrides are visibly distinguishable.
- Settings launches this screen instead of duplicating its controls.

## Related

- [Workout](workout.md)
- [Profile](profile.md)
- [Settings](settings.md)
