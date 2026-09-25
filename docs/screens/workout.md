# Workout Screen

**Surface:** Phone primary tab for `workout` and `hybrid` modes
**Current route:** `/workout`
**Primary owner:** `apps/features/workout`
**Status:** Current route is a shared placeholder. The sections below are the target contract.

## Purpose

Let the user choose a Routine or structured Program, run the selected session, record its work, and understand training consistency. Workout owns all workout-specific decisions and settings.

## Target Content

The root app bar shows a non-interactive Workout streak status on the right. It
shows only the icon until real Workout history provides a positive count; it
never fabricates a number or routes to Progress.

1. **Current plan** — selected Routine or Program, its next scheduled session, session status, and a clear rest-day state. Do not offer a standalone Quick Start workout.
2. **Library** — one canonical Workout-owned route (`/workout/library`, W6A), reached from the Workout Home entry below the calendar, with capability-gated sections for Programs, Routines, Plans / Training Plans and Exercises. It is not a guided default tab or a Workout-local content tab; a future configurable navigation may promote the same route. See [Library](library.md).
3. **Routines and Programs** — browse, select, and later create reusable Routines and structured multi-week Programs, reached through Library sections. A Program defines the sequence of scheduled routine sessions; an active workout starts only from its selected Routine or Program session. See [Routines](routine-library.md) and [Programs](programs.md).
4. **Exercises** — a dedicated Exercises screen (Library → Exercises) for catalog, search and filters (W3A), with Exercise detail once W3B is ready, backed first by a local, versioned JSON catalog; the same capability also provides the exercise picker inside Routine/Program builders. It is not a direct workout-start surface. See [Exercises and Exercise Picker](exercise-search.md).
5. **Active Workout** — run one selected Routine or Program session with set input, rest timer, and finish review. See [Active Workout](active-workout.md).
6. **Weekly plan and history** — completed sessions, scheduled workouts, and a simple completion summary.
7. **Workout Insights** — the muscle heatmap, training radar map, and workout calendar, each backed by recorded history and accessible without colour-only meaning. See [Workout Insights](workout-insights.md).
8. **Workout Settings** — training goal, experience level, available equipment, schedule, preferred split, units, and other training defaults. Profile context may seed defaults; Workout owns edits, validation, and plan behavior. See [Workout Settings](workout-settings.md).

## Key Actions And Navigation

- Selecting a Routine or scheduled Program session opens [Active Workout](active-workout.md). There is no standalone Quick Start path.
- Workout Home provides a Library entry that opens the canonical Library route; an Explore entry is added only when Explore exists. Library, Routines, Programs and Exercises open inside `apps/features/workout`.
- Library → Exercises opens the dedicated Exercises screen. Add/replace exercise in a builder opens the exercise picker context, then returns to the Routine/Program editor; neither starts a session directly.
- A calendar day opens its session detail or scheduled-workout action.
- Workout Insights opens only when useful recorded evidence exists; its muscle-map or radar-map detail may not promise medical readiness.
- Workout Settings is launched from Workout or a Settings entry, but stays module-owned.
- The guided Workout tab is not visible in `nutrition` mode. Future custom navigation cannot expose Workout or Library there without a deliberate switch to Hybrid.
- If a future custom layout promotes Library, it opens the same Library route; the Workout Home → Library entry remains.

## Adaptive Entry Behavior

- When Workout is directly selected, Current Plan and the next valid Routine/Program session provide the primary start entry.
- When Library is promoted, Workout may compact the duplicate Library entry while keeping current-plan and history context.
- When Workout is eligible but not directly selected in a future custom layout, Home provides the prominent Routine/Program entry and an all-features path remains available.
- Start always launches the same Workout-owned command with selected Routine/Program context; no entry point creates a standalone Quick Start.
- During an active session, Home and shell chrome show a persistent Resume entry. Changing mode/layout cannot create a second session or discard the existing one.

## Data And State Boundaries

- Durable pure-Dart Workout IDs, value objects, canonical entities, and historical snapshot contracts belong in `apps/shared`; Workout-specific repository interfaces, data sources, controllers, composition, and presentation stay in the Workout feature ([ADR-0011](../adr/0011-workout-canonical-identities-and-exercise-catalog.md), [Module ownership](../MODULE_OWNERSHIP.md)). Other Workout logging and calculation code stays in the Workout feature unless it is a truly cross-feature pure-Dart contract. A local JSON exercise catalog is parsed through a Workout-owned data boundary, never read directly by UI widgets.
- The first Exercise Search catalog remains bundled/versioned JSON, not Supabase Storage. Use the private `workout` bucket only for a later approved user-attachment use case.
- Profile supplies approved context only through a stable contract. Nutrition, Profile, and Home must not import Workout presentation code.
- Muscle heatmap, radar map, and calendar use recorded workout history. With no history, show a neutral explanation and a Routine/Program browse action rather than zero-value analytics.
- Active workout, timer, and locally pending events must make their save/sync state clear once persistence is introduced.
- Loading, empty Library, permission/data error, and offline behavior are required before the feature is complete.

## Acceptance Criteria

- Workout is available only in the documented App Modes.
- Library, Routines, Programs, Exercises, active workout, history, muscle heatmap, radar map, calendar, and settings have separate route/state responsibilities as they grow.
- Profile-derived defaults never overwrite an explicit user workout preference without confirmation.
- Heatmap and calendar remain understandable with screen readers, high contrast, and no colour perception.
- Root-tab, promoted-Library, and hidden-but-eligible layouts reuse the same Workout routes (including the one canonical Library route), validation, and active-session controller.

## Related

- [Screen catalog](README.md)
- [Library](library.md)
- [Recovery](recovery.md)
- [Module ownership](../MODULE_OWNERSHIP.md)
- [Adaptive navigation and action entry](../../.ai/tasks/adaptive-navigation-and-actions.md)
