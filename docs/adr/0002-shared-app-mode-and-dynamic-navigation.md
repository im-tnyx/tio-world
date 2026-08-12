# ADR-0002: Shared App Mode and Dynamic Navigation

- **Status:** Accepted
- **Date:** 2026-08-11

## Context

Tio supports three user-selectable phone experiences: workout-only, nutrition-only, and hybrid. A fixed tab list shows irrelevant destinations for focused users and encourages separate mode logic in each feature.

The original Flutter shell exposed all five registered `StatefulShellRoute` branches as a fixed bottom bar. The implemented foundation now keeps those stable branches internally while deriving visible guided tabs and route eligibility from App Mode.

## Decision

- Define one pure-Dart contract in `apps/shared`:

  ```dart
  enum AppMode { workout, nutrition, hybrid }
  ```

- Build the visible `go_router` `StatefulShellRoute` tab model from the active `AppMode` while keeping registered branch identity stable.
- Onboarding begins with mode selection, later onboarding steps are mode-conditional, and Settings can change the selected mode.
- Persist the confirmed mode device-locally for the first slice through a pure-Dart preference contract in `apps/shared` and a platform adapter wired at the app composition boundary. Defer account sync until an approved Supabase profile contract exists.
- Keep Workout Library inside Workout and defer Meal Plan to the Nutrition flow after the diary MVP. Add Coach to every mode only in Phase 7.

| Mode | Guided primary tabs |
| :--- | :--- |
| `workout` | Home, Workout, Progress |
| `nutrition` | Home, Nutrition, Progress |
| `hybrid` | Home, Workout, Nutrition, Progress |

## Consequences

### Positive

- All feature packages use one mode vocabulary without importing another feature's presentation code.
- Focused users see only relevant primary destinations.
- New tabs can be introduced through the central mode-to-tab mapping rather than scattered numeric indexes.

### Constraints

- Missing or invalid local mode data must return the user to mode selection rather than silently inventing an account-backed value.
- The first slice must not add a Supabase schema, Storage bucket, backend endpoint, or cross-device merge behavior for App Mode.
- Navigation changes must preserve a valid selected tab when the mode changes.
- The enum, local preference boundary, first onboarding selection screen, Settings editor, and guided navigation are implemented. Later mode-conditional onboarding steps and manual device-restart verification remain open in the foundation task.

## Related

- [Architecture](../ARCHITECTURE.md)
- [Roadmap](../ROADMAP.md)
- [App Mode foundation task](../../.ai/tasks/app-mode-foundation.md)
- [Onboarding screen specification](../screens/onboarding.md)
- [Settings screen specification](../screens/settings.md)
- [ADR-0005: Adaptive Navigation And Action Entry](0005-adaptive-navigation-and-action-entry.md)
