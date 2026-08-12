# Onboarding Screen

**Surface:** Phone full-screen setup flow
**Current route:** `/onboarding`
**Primary owner:** `apps/features/onboarding`
**Status:** App Mode selection is implemented. Later common-profile, Workout, Nutrition, review, and finish steps remain planned.

## Purpose

Collect only the minimum context required to give a user the correct product experience. The first screen selects App Mode; every later step is conditional on that selection.

## Current Implemented Boundary

- The route presents all three modes, their guided tab preview, validation, saving state, and persistence errors.
- A confirmed selection is saved through the shared preference boundary and opens Home with the matching guided navigation.
- The page previews which setup branch comes next, but it does not yet collect profile, Workout, or Nutrition inputs and does not represent completed onboarding.

## Target Step Order

1. **App Mode selection** — `workout`, `nutrition`, or `hybrid`. Explain what each mode includes and let the user continue only after one choice.
2. **Common profile context** — only the personal and fitness information required by the selected MVP flows, with clear optional versus required fields.
3. **Workout branch** — shown for `workout` and `hybrid`; capture approved training goal, experience, equipment, and schedule defaults.
4. **Nutrition branch** — shown for `nutrition` and `hybrid`; capture approved nutrition-goal and preference inputs needed to propose targets.
5. **Review and finish** — make chosen mode and changeable defaults visible; then route to Home with the selected mode's guided navigation.

The exact personal-data fields, consent wording, and persistence method require the relevant approved task. Do not collect health data merely because a future module may use it.

## Navigation And Editing Rules

- Back retains entered values within the in-progress flow where safe.
- A user may change App Mode before finishing; no irrelevant branch data is required to complete.
- After completion, Settings changes mode and launches module-owned target/settings flows. It must not recreate a second onboarding implementation.
- If mode change would make stored feature data unavailable from navigation, preserve the data and explain the navigation change; do not delete it silently.

## Data And State Boundaries

- `AppMode` belongs in `apps/shared`; onboarding only selects it through the approved preference boundary.
- Profile owns profile context. Workout and Nutrition own their domain defaults, calculations, and validation.
- Form validation, partial progress, interruption, persistence error, and offline behavior are required before the flow is complete.

## Acceptance Criteria

- App Mode is visibly the first user decision.
- `workout`, `nutrition`, and `hybrid` show only the relevant later steps.
- Completion produces the documented guided mode navigation and a valid Home destination. Phase 9 custom tab personalization remains a later Settings flow.
- All sensitive inputs have purpose, editability, and privacy treatment defined before collection.

## Related

- [Settings](settings.md)
- [Profile](profile.md)
- [Screen catalog](README.md)
- [App Mode foundation](../../.ai/tasks/app-mode-foundation.md)
