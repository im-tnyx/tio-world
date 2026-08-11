# Screen Catalog And Module Plan

This catalog is the product-level reference for phone and Wear OS screens. It records what each screen is for, which package owns it, the visible sections, actions, states, and implementation boundaries.

Runtime source remains the truth for live behavior. A **Target** section is a planned contract, not a claim that the screen or data already works.

## Current Runtime Snapshot

- The phone starts at `/splash`, then routes to `/auth` after two seconds.
- Welcome and Login have real Flutter UI. Onboarding implements App Mode selection, and Settings implements App Mode editing. Home, Nutrition, Coach, Workout, Progress, and Profile still use placeholder content.
- The phone shell keeps five stable registered branches, while the visible guided bottom navigation is App Mode-driven. Coach is registered but unavailable before Phase 7.
- The Wear OS app has a static seven-item action list. Every tile currently shows a `coming soon` message.

## Module Map

| Product area | Primary owner | Catalog reference | Delivery boundary |
| :--- | :--- | :--- | :--- |
| App shell and route composition | `apps/app` | [Home](home.md), [Coach](coach.md) | Keep composition thin; do not place feature logic here. |
| Shared mode and cross-feature contracts | `apps/shared` | [Onboarding](onboarding.md), [Settings](settings.md) | Own `AppMode` and future pure-Dart destination/layout contracts without Flutter UI. |
| Shared UI and chrome | `apps/core` | [Home](home.md), [Profile](profile.md) | Own dynamic shell UI, generic action slots, persistent-activity chrome, Material 3 Expressive tokens, `TioAvatar`, and `TioButton`. |
| Onboarding | `apps/features/onboarding` | [Onboarding](onboarding.md) | First screen chooses App Mode; later steps depend on it. |
| Workout | `apps/features/workout` | [Workout](workout.md) | Own routines, Programs, logging, workout settings, muscle heatmap, radar map, and training calendar. |
| Nutrition | `apps/features/nutrition` | [Nutrition](nutrition.md) | Own diary, water, nutrition targets, and later Meal Plan. |
| Progress | `apps/features/progress` | [Progress](progress.md) | Own trends, measurements, photos, streaks, and achievements. |
| Recovery | future `apps/features/recovery` | [Recovery](recovery.md) | Create only for its first approved vertical slice; no empty package now. |
| Profile | `apps/features/profile` | [Profile](profile.md) | Own personal and fitness profile context, not another feature's calculations. |
| Settings | `apps/features/settings` | [Settings](settings.md) | Own app preferences and launch module-owned settings flows. |
| Coach | `apps/features/coaching` | [Coach](coach.md) | Add the primary tab only in Phase 7. |
| Wear OS companion | `apps/wear` | [Wear Home](wear-home.md) | Keep workout controls and nutrition quick actions compact and watch-first. |

## App Mode And Future Navigation Personalization

The implemented pure-Dart contract in `apps/shared` is:

```dart
enum AppMode { workout, nutrition, hybrid }
```

The `go_router` `StatefulShellRoute` shell derives its visible guided layout and route eligibility from the active mode. Stable branch identity is mapped explicitly instead of treating visible position as a branch index.

| Selected mode | Guided default tabs |
| :--- | :--- |
| `workout` | Home, Workout, Progress |
| `nutrition` | Home, Nutrition, Progress |
| `hybrid` | Home, Workout, Nutrition, Progress |

Coach becomes eligible in Phase 7. Profile and Settings remain launched from app chrome or an in-feature action in the guided layout.

A later Navigation & Tabs upgrade supports three to six eligible selections with Home fixed first. Root destinations remain distinct from promoted shortcuts: Workout Library and Meal Plan keep their canonical feature routes and may become custom shortcut destinations only after the owning feature exists. The selected layout may change Home/feature section prominence and action entry placement, but it never moves or duplicates feature business logic.

The first implementation uses the approved device-local App Mode preference and defers account sync until a Supabase profile contract exists. Later mode-conditional onboarding steps and manual restart verification remain open. See [App Mode foundation](../../.ai/tasks/app-mode-foundation.md).

## Profile-Derived Configuration

Profile inputs may inform module defaults, but ownership remains explicit:

- Profile collects and updates the user's personal and fitness context.
- Nutrition owns nutrition target calculations, overrides, validation, and presentation.
- Workout owns workout settings, training-plan defaults, validation, and presentation.
- Recovery may consume approved profile/workout/nutrition summaries through stable contracts when its module exists.
- Use a pure-Dart profile-context contract in `apps/shared` only when a cross-feature use case requires one; do not import Profile presentation code into another feature.

## Reading And Implementation Order

1. Complete the mode-conditional profile, Workout, Nutrition, review, and finish onboarding steps on top of the implemented App Mode foundation.
2. Introduce the smallest profile-context slice required by that onboarding flow and the first Workout or Nutrition vertical slice.
3. Deliver Workout, Nutrition, and Home summaries as independent vertical slices behind their owners.
4. Add Progress once at least one tracked data source exists.
5. Decide Recovery's initial data source before creating its package or screen.
6. Add Coach only in Phase 7 and evolve Wear after its phone contracts are stable.
7. Add custom navigation, adaptive Home composition, and action-entry placement only after the core root screens and workflows are stable.

For every source implementation, create a scoped task from [.ai/tasks/TEMPLATE.md](../../.ai/tasks/TEMPLATE.md), link the affected screen specification, and record validation truth in the task handoff.

## Screen References

| Surface | Screen | Current status |
| :--- | :--- | :--- |
| Entry | [Splash](splash.md) | Implemented transition; no session decision yet. |
| Entry | [Welcome](welcome.md) | Implemented UI and navigation. |
| Entry | [Login](login.md) | Implemented UI; authentication is mocked. |
| Phone | [Home](home.md) | Route placeholder; target specification. |
| Phone | [Workout](workout.md) | Route placeholder; target specification. |
| Phone | [Exercise Search](exercise-search.md) | Future nested Workout Routine/Program selection screen. |
| Phone | [Routine Library](routine-library.md) | Future nested Workout browse and editor flow. |
| Phone | [Programs](programs.md) | Future nested multi-week Workout program flow. |
| Phone | [Active Workout](active-workout.md) | Future selected Routine/Program execution flow. |
| Phone | [Workout Insights](workout-insights.md) | Future muscle heatmap, radar map, and calendar flow. |
| Phone | [Workout Settings](workout-settings.md) | Future Workout-owned configuration flow. |
| Phone | [Nutrition](nutrition.md) | Route placeholder; target specification. |
| Phone | [Meal Diary](meal-diary.md) | Future Nutrition MVP diary flow. |
| Phone | [Nutrition Targets](nutrition-targets.md) | Future Nutrition-owned target configuration. |
| Phone | [Meal Plan](meal-plan.md) | Future post-diary Nutrition flow. |
| Phone | [Progress](progress.md) | Route placeholder; target specification. |
| Phone | [Recovery](recovery.md) | Future module and screen. |
| Phone | [Coach](coach.md) | Route placeholder; primary tab deferred to Phase 7. |
| Phone | [Onboarding](onboarding.md) | App Mode selection implemented; later conditional steps planned. |
| Phone | [Profile](profile.md) | Route placeholder; target specification. |
| Phone | [Settings](settings.md) | App Mode editor implemented; remaining preferences planned. |
| Wear OS | [Wear Home](wear-home.md) | Static action list; actions are placeholders. |

## Shared Screen Quality Rules

- Each screen must have loading, empty, error, and offline behavior before real data is claimed as complete.
- Use `apps/core` tokens and reusable components; do not hardcode repeated phone UI values in feature packages.
- Preserve semantic labels, logical focus order, visible touch feedback, high contrast, and reduced-motion behavior.
- Health, workout, nutrition, recovery, and profile values are sensitive. Do not log personal data or put server credentials in mobile code.
- Screen documents describe outcomes and ownership. Repository, data, and sync contracts are added only through an approved feature task.
- Each adaptable screen separates stable purpose from App Mode variants, destination-placement variants, action-entry behavior, and fallback reachability. Do not create a separate screen for every navigation combination.
