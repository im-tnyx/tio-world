# ADR-0005: Adaptive Navigation And Action Entry

- **Status:** Accepted
- **Date:** 2026-08-11

## Context

The three App Modes provide useful guided defaults, but a mature Tio app may contain more eligible destinations than every user wants in primary navigation. Promoting feature routes such as Routine Library or Meal Plan also changes where start-workout and meal-log actions should appear. If each screen directly checks raw tab indexes or duplicates these workflows, the number of mode/layout combinations becomes difficult to maintain.

The current runtime implements the three App Modes and their guided layouts. It does not implement navigation personalization, adaptive Home sections, or feature action placement. This ADR records those final-stage capabilities only.

## Decision

- Keep exactly three `AppMode` values: `workout`, `nutrition`, and `hybrid`.
- Use each App Mode's documented tab list as the guided default for the first implementation.
- Add a later Navigation & Tabs setting that saves three to six eligible destinations, with Home required and first.
- Determine destination eligibility from App Mode, implemented feature availability, and release-stage policy.
- Distinguish root destinations from promoted shortcuts. Routine Library remains Workout-owned; Meal Plan remains Nutrition-owned.
- Derive Home and feature surface composition from App Mode, navigation layout, feature availability, and prepared user-data state rather than numeric tab indexes.
- Keep each feature action canonical. Tab layout may change where a command is presented, but the owning feature retains validation, state, persistence, and workflow behavior.
- Preserve an active workout through a persistent resume entry even when Workout is hidden or reordered.

Conceptual target contracts include stable destination identity, navigation layout preference, feature availability, and action-entry placement. Their exact Dart API and persistence owner must be approved in the implementation task; this ADR does not define executable source.

## Consequences

### Positive

- Guided App Mode delivery can ship before custom navigation.
- Home and feature pages can be built from reusable sections instead of separate screens for every combination.
- A promoted Library or Meal Plan entry reuses its canonical route and feature controller.
- Long-running workout state remains reachable independently from tab order.

### Constraints

- Home counts toward the three-to-six selection range and cannot be removed or moved from first position.
- A Workout-only layout cannot expose Nutrition or Meal Plan without a deliberate switch to Hybrid; the inverse applies to Nutrition-only mode.
- Six saved destinations need responsive validation on compact phones and may require an overflow/More presentation.
- A mode or layout change must reconcile the active destination to a valid route without deleting stored feature data or active-session state.
- Coach, You, Social, Meal Plan, and promoted shortcuts cannot become selectable before their actual feature and ownership boundary exist.
- Selected destination identity cannot rely only on `StatefulShellRoute` branch index because a promoted shortcut may map to an existing owner route.

## Alternatives Rejected

- Adding more `AppMode` enum values for every tab combination was rejected because product scope and navigation preference are different concerns.
- Building a separate screen for every mode/layout combination was rejected because it duplicates content and workflow behavior.
- Copying start-workout or meal-log logic into Home or the shell was rejected because it breaks feature ownership and creates inconsistent state.

## Related

- [ADR-0002: Shared App Mode And Dynamic Navigation](0002-shared-app-mode-and-dynamic-navigation.md)
- [Architecture](../ARCHITECTURE.md)
- [UI/UX System](../UX_UI_SYSTEM.md)
- [Screen Catalog](../screens/README.md)
- [Adaptive navigation task](../../.ai/tasks/adaptive-navigation-and-actions.md)
