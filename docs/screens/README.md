# Screen Catalog And Module Plan

Document Status: Canonical Live Doc
Last Verified: 2026-09-28
Owner: screen/product architecture
Truth Boundary: Authoritative for the screen catalog, module ownership, state/navigation planning, and implementation order; runtime source proves shipped behavior and trackers own live delivery status.

This catalog is the product-level reference for phone and Wear OS screens. It records what each screen is for, which package owns it, the visible sections, actions, states, and implementation boundaries.

Runtime source remains the truth for live behavior. A **Target** section is a planned contract, not a claim that the screen or data already works.

## Current Runtime Snapshot

- The phone starts at `/splash`; app-level session/bootstrap state decides the next destination and Splash exposes recoverable failure/retry rather than a fixed two-second redirect.
- Welcome routes fresh-account Get Started into pre-auth App Mode selection and Sign In/Skip into Login. Login uses real Auth use cases and returns successful authentication to app-level bootstrap.
- Onboarding is one parent flow with durable Supabase draft persistence/resume and Supabase-backed completion composition.
- Home renders the Home feature page. Workout renders `WorkoutHomePage` with the Library entry, and Nutrition renders `MealDiaryPage`.
- Library, Programs and Exercises are shipped nested Workout routes. Profile loads canonical profile/account/body data, exposes persisted editing and avatar management. Coach and Progress remain the shell branches whose current feature depth is still limited relative to their target contracts.
- The phone shell keeps five stable registered branches while visible guided bottom navigation is App Mode-driven. Coach is registered but unavailable before its approved release stage.
- The Wear OS app remains an early companion surface; runtime source is the authority for which actions are currently implemented.

## Module Map

| Product area | Primary owner | Catalog reference | Delivery boundary |
| :--- | :--- | :--- | :--- |
| App shell and route composition | `apps/app` | [Home](home.md), [Coach](coach.md) | Keep composition thin; do not place feature logic here. |
| Shared mode and cross-feature contracts | `apps/shared` | [Onboarding](onboarding.md), [Settings](settings.md) | Own `AppMode` and future pure-Dart destination/layout contracts without Flutter UI. |
| Shared UI and chrome | `apps/core` | [Home](home.md), [Profile](profile.md) | Own dynamic shell UI, generic action slots, persistent-activity chrome, Material 3 Expressive tokens, `TioAvatar`, and `TioButton`. |
| Onboarding | `apps/features/onboarding` | [Onboarding](onboarding.md) | First route child chooses App Mode; later steps depend on it. |
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

Coach becomes eligible in Phase 7. Profile launches from the Home avatar; Settings launches from Profile or an approved in-feature action.

A later Navigation & Tabs upgrade supports three to six eligible selections with Home fixed first. Root destinations remain distinct from promoted shortcuts: Workout Library (one canonical route, see [Library](library.md)) and Meal Plan keep their canonical feature routes and may become custom shortcut destinations only after the owning feature exists. The selected layout may change Home/feature section prominence and action entry placement, but it never moves or duplicates feature business logic.

Pre-auth App Mode selection is held as local pending setup state until authentication/account setup completes. For authenticated accounts, canonical App Mode and active-tab preferences are persisted in `public.user_app_preferences` through `SupabaseAppPreferencesRepository`. Session bootstrap reads that canonical state and `AppModeController.restoreCanonical()` publishes it; the legacy device-local `AppModePreference` is only a best-effort cache and must not override valid remote account state.

Product Onboarding still uses one `/onboarding` parent after account setup. Draft mode, canonical authenticated mode, and onboarding completion status remain distinct ownership/state concepts.
See [Onboarding Flow Architecture](../architecture/ONBOARDING_ARCHITECTURE.md), the
[onboarding task](../../.ai/archive/2026-09-mode-conditional-onboarding-flow.md), and the
[App Mode foundation](../../.ai/tasks/app-mode-foundation.md).

## Profile-Derived Configuration

Profile inputs may inform module defaults, but ownership remains explicit:

- Profile collects and updates the user's personal and fitness context.
- Nutrition owns nutrition target calculations, overrides, validation, and presentation.
- Workout owns workout settings, training-plan defaults, validation, and presentation.
- Recovery may consume approved profile/workout/nutrition summaries through stable contracts when its module exists.
- Use a pure-Dart profile-context contract in `apps/shared` only when a cross-feature use case requires one; do not import Profile presentation code into another feature.

## Reading And Implementation Order

1. Maintain the implemented/frozen routed Product Onboarding flow and evolve owner-specific onboarding behavior only through separately approved feature slices.
2. Introduce the smallest profile-context slice required by that onboarding flow and the first Workout or Nutrition vertical slice.
3. Deliver Workout, Nutrition, and Home summaries as independent vertical slices behind their owners.
4. Add Progress once at least one tracked data source exists.
5. Decide Recovery's initial data source before creating its package or screen.
6. Add Coach only in Phase 7 and evolve Wear after its phone contracts are stable.
7. Add custom navigation, adaptive Home composition, and action-entry placement only after the core root screens and workflows are stable.

For every source implementation, create a scoped task from [.ai/tasks/TEMPLATE.md](../../.ai/tasks/TEMPLATE.md), link the affected screen specification, and record validation truth in the task handoff.

## Screen References

Repository-implemented status is not proof of a distributed app release. The 2026-10-17 focused Workout-status verification covers **Workout**, **Library**, **Exercises/Exercise picker**, **Program-owned Routines**, and **Programs** against `main@633dbf38` and merged PR #551/#566/#570/#577/#581; it does not re-verify unrelated catalog rows or certify device QA. The earlier 2026-10-15 focused status verification reconciled **Profile**, **Profile Photo**, **Nutrition Targets**, and **Settings** with their owning source/routes; other rows retain separately documented evidence and should be rechecked before related work.

| Surface | Screen | Current status |
| :--- | :--- | :--- |
| Entry | [Splash](splash.md) | Implemented bootstrap surface; app-level session/bootstrap state owns destination decisions and recoverable retry. |
| Entry | [Welcome](welcome.md) | Implemented UI and navigation. |
| Entry | [Login](login.md) | Implemented Phone-first auth entry backed by real Supabase Auth use cases; Email and Google remain supported through the canonical auth composition. |
| Phone | [Home](home.md) | Routed Home feature placeholder; current `HomePage` intentionally renders an empty surface while Home-owned content remains future work. |
| Phone | [Workout](workout.md) | Implemented Workout Home with Library entry; owner-verified nested Library/Programs/Exercises plus Program-scoped Routine Create/Edit flows are available behind runtime repository/auth gates. Active Workout, TrainingPlan execution and Insights remain gated. |
| Phone | [Library](library.md) | Implemented Programs collection with Program Detail, owner-scoped Routine rows, Program-scoped Add Routine via expanded empty Program or Program overflow (PR #566), and Exercises entry. Routine card actions use a Core bottom sheet with real Edit only where verified (#581); direct Library-root `My Program` quick-create and Your Plan remain gated. |
| Phone | [Exercises and Exercise Picker](exercise-search.md) | Dedicated unified Exercises browse/create/edit is reachable via Library; canonical Routine-context Exercise picker is implemented in merged Create/Edit (#551). Standalone Exercise Detail, Favorites and Folders remain gated. |
| Phone | [Program-owned Routines](routine-library.md) | Program-owned persisted Routine metadata, read-only Detail, guarded Exercise/Set Create/Edit (#551), atomic Name+composition Update (#577) and Routine-card Core Edit bottom sheet (#581) are source-implemented. Move/Delete and Workout Start remain separate gated capabilities. |
| Phone | [Programs](programs.md) | Persisted Program collection/create/rename, Program Detail and scoped Routine Create are source-implemented; Library dotted Add Routine and Program 3-dot Add New Routine merged in #566. Program Delete, TrainingPlan scheduling/following and direct Library-root default-Program quick-create remain gated. |
| Phone | [Active Workout](active-workout.md) | Future selected Routine or scheduled PlannedWorkout execution flow. |
| Phone | [Workout Insights](workout-insights.md) | Future muscle heatmap, radar map, and calendar flow. |
| Phone | [Workout Settings](workout-settings.md) | Future Workout-owned configuration flow. |
| Phone | [Nutrition](nutrition.md) | `/nutrition` now renders the Nutrition-owned Meal Diary date-navigation surface; later Nutrition sections remain target work. |
| Phone | [Meal Diary](meal-diary.md) | Meal Diary date navigation, manual create/read foundations, selected-day cards, Quick Edit, daily summary and primary calorie-progress ring are implemented; later mutation/editor slices remain. |
| Phone | [Nutrition Targets](nutrition-targets.md) | Settings-launched Nutrition-owned targets configuration is implemented with repository-backed load/save, Macronutrients and Additional Nutrition child flows. Recommendation and override UX may evolve separately. |
| Phone | [Meal Plan](meal-plan.md) | Future post-diary Nutrition flow. |
| Phone | [Progress](progress.md) | Route placeholder; target specification. |
| Phone | [Recovery](recovery.md) | Future module and screen. |
| Phone | [Coach](coach.md) | Registered shell branch only; current App Modes do not expose Coach as a guided destination, and direct `/coach` access redirects to an allowed destination. Phase 7 remains the product gate. |
| Phone | [Onboarding](onboarding.md) | Implemented/frozen Product Onboarding flow with mode-specific Profile, Body/Wellness, Nutrition, Workout, Targets, optional Health Connections, Review, and durable completion. |
| Phone | [Profile](profile.md) | Profile shows canonical profile/account/body information with persisted Profile Settings editing, Settings access and Profile-owned avatar management. Additional cross-feature content stays with its owner. |
| Phone | [Profile Photo](profile-avatar.md) | 1:1 preview and Profile-owned Supabase avatar upload/delete are implemented through the existing user-owned media path; Download remains unavailable. |
| Phone | [Settings](settings.md) | Settings hub includes App Mode, Theme, Measurement Units and Calendar Preferences, plus Health & Goals / Daily Wellness and device-local Glass Size. Broader Settings readiness and Daily Wellness device/layout acceptance remain separately gated. |
| Wear OS | [Wear Home](wear-home.md) | Static action list; actions are placeholders. |

## Shared Screen Quality Rules

- Each screen must have loading, empty, error, and offline behavior before real data is claimed as complete.
- Use `apps/core` tokens and reusable components; do not hardcode repeated phone UI values in feature packages.
- Preserve semantic labels, logical focus order, visible touch feedback, high contrast, and reduced-motion behavior.
- Health, workout, nutrition, recovery, and profile values are sensitive. Do not log personal data or put server credentials in mobile code.
- Screen documents describe outcomes and ownership. Repository, data, and sync contracts are added only through an approved feature task.
- Each adaptable screen separates stable purpose from App Mode variants, destination-placement variants, action-entry behavior, and fallback reachability. Do not create a separate screen for every navigation combination.
