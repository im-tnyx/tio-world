# Workout Screen

**Surface:** Phone primary tab for `workout` and `hybrid` modes
**Current route:** `/workout`
**Primary owner:** `apps/features/workout`
**Status:** Current route is a shared placeholder. The sections below are the target contract.

## Purpose

Let the user choose a Routine or structured Program, run the selected session, record its work, and understand training consistency. Workout owns all workout-specific decisions and settings.

## Target Content

1. **Current plan** — selected Routine or Program, its next scheduled session, session status, and a clear rest-day state. Do not offer a standalone Quick Start workout.
2. **Routine Library** — browse, search, filter, select, and later create or save single-session routines. It is a Workout-owned route and may become a future promoted shortcut after implementation; it is not a guided default tab. See [Routine Library](routine-library.md).
3. **Programs** — choose and follow structured multi-week training programs. A Program defines the sequence of scheduled routine sessions; an active workout starts only from its selected Routine or Program session. See [Programs](programs.md).
4. **Exercise Search** — a nested Routine/Program editing screen backed first by a local, versioned JSON catalog. It is reached only to add or replace an exercise; it is not a direct workout-start surface. See [Exercise Search](exercise-search.md).
5. **Active Workout** — run one selected Routine or Program session with set input, rest timer, and finish review. See [Active Workout](active-workout.md).
6. **Weekly plan and history** — completed sessions, scheduled workouts, and a simple completion summary.
7. **Workout Insights** — the muscle heatmap, training radar map, and workout calendar, each backed by recorded history and accessible without colour-only meaning. See [Workout Insights](workout-insights.md).
8. **Workout Settings** — training goal, experience level, available equipment, schedule, preferred split, units, and other training defaults. Profile context may seed defaults; Workout owns edits, validation, and plan behavior. See [Workout Settings](workout-settings.md).

## Key Actions And Navigation

- Selecting a Routine or scheduled Program session opens [Active Workout](active-workout.md). There is no standalone Quick Start path.
- Routine Library and Programs open inside `apps/features/workout`.
- Add/replace exercise opens the nested [Exercise Search](exercise-search.md) screen, then returns to the Routine/Program editor; it never starts a session directly.
- A calendar day opens its session detail or scheduled-workout action.
- Workout Insights opens only when useful recorded evidence exists; its muscle-map or radar-map detail may not promise medical readiness.
- Workout Settings is launched from Workout or a Settings entry, but stays module-owned.
- The guided Workout tab is not visible in `nutrition` mode. Future custom navigation cannot expose Workout or Library there without a deliberate switch to Hybrid.

## Adaptive Entry Behavior

- When Workout is directly selected, Current Plan and the next valid Routine/Program session provide the primary start entry.
- When Routine Library is promoted, Workout may compact the duplicate Library hero while keeping current-plan and history context.
- When Workout is eligible but not directly selected in a future custom layout, Home provides the prominent Routine/Program entry and an all-features path remains available.
- Start always launches the same Workout-owned command with selected Routine/Program context; no entry point creates a standalone Quick Start.
- During an active session, Home and shell chrome show a persistent Resume entry. Changing mode/layout cannot create a second session or discard the existing one.

## Data And State Boundaries

- Workout entities, logging, calculations, and repository contracts stay in the Workout feature or `apps/shared` when they are truly cross-feature pure-Dart contracts. A local JSON exercise catalog is parsed through a Workout-owned data boundary, never read directly by UI widgets.
- The first Exercise Search catalog remains bundled/versioned JSON, not Supabase Storage. Use the private `workout` bucket only for a later approved user-attachment use case.
- Profile supplies approved context only through a stable contract. Nutrition, Profile, and Home must not import Workout presentation code.
- Muscle heatmap, radar map, and calendar use recorded workout history. With no history, show a neutral explanation and a Routine/Program browse action rather than zero-value analytics.
- Active workout, timer, and locally pending events must make their save/sync state clear once persistence is introduced.
- Loading, empty Library, permission/data error, and offline behavior are required before the feature is complete.

## Acceptance Criteria

- Workout is available only in the documented App Modes.
- Routine Library, Programs, Exercise Search, active workout, history, muscle heatmap, radar map, calendar, and settings have separate route/state responsibilities as they grow.
- Profile-derived defaults never overwrite an explicit user workout preference without confirmation.
- Heatmap and calendar remain understandable with screen readers, high contrast, and no colour perception.
- Root-tab, promoted-Library, and hidden-but-eligible layouts reuse the same Workout routes, validation, and active-session controller.

## Related

- [Screen catalog](README.md)
- [Recovery](recovery.md)
- [Module ownership](../MODULE_OWNERSHIP.md)
- [Adaptive navigation and action entry](../../.ai/tasks/adaptive-navigation-and-actions.md)
