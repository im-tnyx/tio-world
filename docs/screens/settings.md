# Settings Screen

**Surface:** Phone full-screen preferences and account controls
**Current route:** `/settings`
**Primary owner:** `apps/features/settings`
**Status:** App Mode editing is implemented. Other settings and module-owned configuration entries remain planned.

## Purpose

Manage app-level preferences and route the user to module-owned configuration. Settings owns preferences and navigation, not Nutrition, Workout, Profile, Recovery, or Coach business logic.

## Current Implemented Boundary

- Profile exposes the Settings action; Home's app bar keeps only the Profile avatar account entry.
- Settings displays the current App Mode, previews the guided tabs for each choice, persists a confirmed change through the same controller used by Onboarding, and returns to a valid Home route.
- Navigation & Tabs personalization, confirmation-copy refinement, module settings links, account controls, and other preferences are not implemented.

## Target Content

- **App Mode** — display the current `workout`, `nutrition`, or `hybrid` selection and allow a deliberate change.
- **Navigation & Tabs** — final-stage preference for choosing and reordering three to six eligible destinations with Home fixed first. Hide this setting until the adaptive-navigation slice is implemented.
- App preferences such as theme, language, units, notifications, accessibility behavior, and privacy/account entries only when their underlying behavior exists.
- **Nutrition Targets** launch entry; target calculations remain in Nutrition.
- **Workout Settings** launch entry; training defaults remain in Workout.
- Profile/account entry and future data/export controls only after their contracts are approved.

## App Mode Change Flow

1. Show the current selection and its guided default tabs plus any future compatible custom-layout impact.
2. Let the user choose another mode with a confirmation that explains navigation changes.
3. Persist through the same App Mode preference boundary used by Onboarding.
4. Reconcile the visible navigation model and select a valid destination, normally Home when the current destination disappears.
5. Preserve feature data; mode changes navigation and setup expectations, not stored user history.

## Future Navigation And Tabs Flow

1. Start from the current mode's guided default or the saved valid layout.
2. Keep Home selected, first, and included in the three-to-six count.
3. Show only destinations allowed by App Mode, implemented feature availability, and release-stage policy.
4. Let the user select/reorder eligible root destinations and promoted shortcuts, preview the result, and reset to mode defaults.
5. Explain when adding a cross-domain destination requires switching to Hybrid.
6. Reconcile invalid/unreleased destinations and the active route without deleting feature data or active-session state.
7. Apply an approved accessible compact treatment when six saved selections cannot fit directly.

Navigation preference changes where sections/actions appear. It does not change Workout/Nutrition calculations, stored history, or feature ownership.

## Data And State Boundaries

- `apps/shared` owns the `AppMode` and preference contracts. The first platform adapter persists the confirmed selection device-locally; account sync remains deferred.
- Settings must not recalculate nutrition targets or workout plans.
- Each enabled preference must have a real state effect, loading/error behavior, and accessible confirmation where needed.
- Avoid presenting unavailable integrations, export, deletion, or notifications as completed functionality.

## Acceptance Criteria

- Settings is not a bottom tab and is reachable from Profile or approved in-feature entry points.
- Changing App Mode uses exactly the same state contract as Onboarding.
- The user understands which tabs will be added or removed before confirmation.
- Future custom layout accepts only three to six eligible selections, keeps Home first, previews the result, and offers reset-to-default.
- A mode/layout change preserves an active workout and falls back to a valid route.
- Module-owned settings links do not duplicate domain forms in Settings.

## Related

- [Onboarding](onboarding.md)
- [Nutrition](nutrition.md)
- [Workout](workout.md)
- [App Mode foundation](../../.ai/tasks/app-mode-foundation.md)
- [Adaptive navigation and action entry](../../.ai/tasks/adaptive-navigation-and-actions.md)
