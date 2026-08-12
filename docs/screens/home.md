# Home Screen

**Surface:** Phone primary tab
**Route:** `/`
**Primary owner:** `apps/app` for current shell composition; introduce a dedicated Home package only when its real domain logic warrants one.
**Status:** Current route is a shared placeholder. The sections below are the target contract.

## Purpose

Give the user a short, useful daily overview and one clear next action. Home summarizes owned feature data; it does not become the owner of workout, nutrition, progress, or recovery business logic.

## Target Content

Common content:

- App bar with product identity and one profile/account entry using the reusable `TioAvatar`; do not add a separate Settings icon here.
- Date-aware greeting and a concise daily summary.
- One primary next action, such as continuing an active selected session, choosing a Routine/Program, or adding the next meal.
- Small, actionable preview cards that navigate to their owning feature. Cards must not duplicate full diary, workout, or analytics screens.

Mode-specific content:

| App Mode | Required summary cards |
| :--- | :--- |
| `workout` | Today’s workout or rest state, workout streak/weekly completion, and a Progress preview. |
| `nutrition` | Today’s calories/macros or target status, water/meal quick action, and a Progress preview. |
| `hybrid` | The current workout/rest card and the nutrition target/meal card, then a Progress preview. |

When Recovery is approved, Home may show one compact readiness or recovery card. It must link into Recovery and must not calculate recovery in the Home layer.

## Adaptive Section Composition

Home is fixed as the first destination, but it is not one static screen for every mode/layout. Its prepared surface model uses:

```text
AppMode + NavigationLayout + FeatureAvailability + UserDataState
```

- App Mode defines which feature summaries and setup prompts are eligible.
- The guided layout uses the mode-specific cards above.
- If an eligible feature has its own selected root destination, Home may show a compact status/next-action preview instead of a large entry section.
- If an eligible feature is not directly selected, Home may promote its entry card so the feature remains reachable.
- If Routine Library or Meal Plan is promoted as a future shortcut, Home reduces duplicate browse/plan hero treatment but may still show time-sensitive status.
- Active workout, failed/pending save, and other important ongoing states are not hidden because a destination was removed or reordered.

Sections are reusable feature-summary components backed by prepared contracts. Home does not read a raw tab index or implement domain calculations.

## Key Actions And Navigation

- Workout actions open the owning Workout flow to choose a Routine/Program or continue an active selected session; Home does not expose a standalone Quick Start workout.
- When Workout is not directly selected but the mode allows it, Home may provide the prominent Routine/Program entry. During an active workout, Home and shell chrome expose Resume rather than starting a second session.
- Meal, water, or nutrition-summary actions open the same owning Nutrition workflows used by Nutrition/Meal Diary.
- When Nutrition is not directly selected but Hybrid mode allows it, Home may expose a prominent Log Meal or Add Water entry. A planned-meal action passes plan context to the canonical Nutrition log flow.
- Progress cards open Progress.
- Avatar opens Profile; Profile owns the Settings launch entry.
- The guided primary navigation follows `AppMode`; future custom navigation keeps Home first and selected while other eligible destinations change.

## Data And State Boundaries

- Home reads prepared summaries through feature-safe contracts; it does not query a database or API directly.
- Missing profile context shows a setup prompt that launches the owning Profile or Onboarding flow.
- Empty feature data uses an encouraging first-action state, not fabricated metrics.
- Loading uses stable card placeholders; errors identify the failed source and offer retry; offline mode labels stale or locally available data honestly.

## Acceptance Criteria

- Every selected App Mode produces only its relevant cards and actions.
- Guided and representative custom layouts produce the documented expanded/compact section behavior without duplicating feature workflows.
- Removing a direct Workout or Nutrition destination does not remove the user's valid Home entry to that eligible feature.
- Active workout Resume remains reachable and cannot become a second Start action.
- Home still offers a meaningful first action with no workout, nutrition, or progress history.
- A card launches its owning feature without importing feature presentation code into the shell.
- Profile, Settings, dark mode, high contrast, reduced motion, and screen-reader traversal are verified when implemented.

## Related

- [Screen catalog](README.md)
- [App Mode foundation](../../.ai/tasks/app-mode-foundation.md)
- [Adaptive navigation and action entry](../../.ai/tasks/adaptive-navigation-and-actions.md)
- [Architecture: App Mode and navigation](../ARCHITECTURE.md#app-mode-navigation-layout-and-surface-composition)
