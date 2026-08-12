# Wear Home Screen

**Surface:** Flutter Wear OS companion
**Primary owner:** `apps/wear`
**Status:** Implemented static action list; every action is currently a `coming soon` placeholder.

## Current Runtime Behavior

The Wear home screen uses a dark, scrollable list headed `Tio`. It currently renders these tiles:

1. Workout Routine
2. Workout This Week
3. Add Food
4. Add Water
5. View Summary
6. Nutrition
7. Settings

Selecting any tile shows a snack bar; no navigation, offline action queue, phone bridge, sensor access, or persistence is implemented.

## Target Purpose

Make fast, glanceable workout controls and nutrition quick actions available on the watch. The watch remains a compact companion, not a copy of phone screen layouts.

## Target Home Content

- **Workout lane:** routine selection, current/active workout entry, set input, rest timer, and compact weekly summary.
- **Nutrition lane:** quick food or meal add, water add, today’s nutrition summary, and later only the next planned-meal status after phone Meal Plan exists.
- **Settings:** watch-specific preferences, permissions, and phone-sync status when those capabilities are approved.

The companion should reflect the selected App Mode after an approved phone-to-watch mode contract exists:

| Phone App Mode | Target Wear emphasis |
| :--- | :--- |
| `workout` | Workout actions and compact workout summary; no nutrition diary features. |
| `nutrition` | Food/water quick actions and nutrition summary; no workout execution flows. |
| `hybrid` | Both compact lanes, ordered by current activity or user choice. |

Until mode sync exists, the current static list is not evidence of mode-aware watch behavior.

## Boundaries

- Keep full food search, meal diary editing, Meal Plan editing, long forms, heavy charts, and full AI chat on the phone.
- Reuse stable shared contracts and lightweight design primitives where useful; do not reuse phone pages directly.
- Sensor, health, permission, phone-sync, and pending-action contracts require their own approved task before source implementation.
- Watch UI must be fast, battery-aware, touch-target-safe, and usable with a short glance.

## States Required For A Live Tile

- Loading/connection state, unavailable phone state, safe offline pending state, action success, retryable failure, and permission-needed state.
- A clear last-sync timestamp when a tile depends on phone or backend data.
- A short fallback for unavailable health/sensor data; never invent a measurement.

## Acceptance Criteria

- Each actionable tile has a compact, single-purpose flow and truthful status.
- App Mode controls which lane is shown after the companion contract is implemented.
- Nutrition remains quick-action-only; Workout remains control-focused; neither claims live sync or sensors without evidence.

## Related

- [Nutrition](nutrition.md)
- [Workout](workout.md)
- [Screen catalog](README.md)
- [Wear strategy](../WATCH_STRATEGY.md)
