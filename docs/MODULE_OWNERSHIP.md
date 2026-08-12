# Module Ownership

This document defines where code should live in `tio-world`.

`tio-world` uses an apps-based Flutter workspace that mirrors the modular native structure from `Tio-hub`.

## Top-Level Ownership

| Path | Owner / Responsibility |
| :--- | :--- |
| `apps/app` | Flutter Android and iOS phone app shell, bootstrap, route composition, providers, and platform entry wiring. |
| `apps/wear` | Flutter Wear OS companion app. |
| `apps/shared` | Pure Dart models, entities, repository contracts, use cases, result/error types, and shared utilities. |
| `apps/core` | Flutter design system, app shell UI, route contracts, reusable widgets, theme tokens, constants, and extensions. |
| `apps/features/auth` | Auth feature package and session entry flows. |
| `apps/features/onboarding` | Onboarding feature package and all onboarding screens/flows. |
| `apps/features/workout` | Workout feature package and all workout screens/flows. |
| `apps/features/nutrition` | Nutrition feature package and all nutrition screens/flows. |
| `apps/features/profile` | Profile launcher, account summary, personal info UI, and fitness hub entry points. |
| `apps/features/settings` | App preferences, account controls, units, notifications, export, about, and settings navigation. |
| `apps/features/progress` | Weight, measurements, progress photos, streaks, trends, achievements, and analytics screens. |
| `apps/features/coaching` | Coach UI package and backend-facing coaching contracts. |
| future `apps/features/recovery` | Recovery, readiness, and rest context after its first approved vertical slice. |
| future `supabase/` | Supabase Auth, Postgres migrations, RLS policies, private Storage buckets, seed data, and approved server functions. |
| future `backend/api` | Protected service endpoints and integrations when a separate backend upgrade is required. |
| future `backend/ai-coach` | Gemini/provider runtime, AI orchestration, prompt logic, safety boundaries, and server-only response shaping. |
| future `backend/jobs` | Long-running scheduled/background work after the backend upgrade is required. |
| `docs` | Canonical architecture and process docs. |
| `.github` | GitHub templates, CODEOWNERS, PR, push, and issue workflow. |
| `.ai` | Short AI orientation files. |

Create missing paths only when a real implementation slice needs them.

## Native-Style Module Mapping

| Native-style module | Flutter workspace path |
| :--- | :--- |
| `:app` | `apps/app` |
| `:wear` | `apps/wear` |
| `:shared` | `apps/shared` |
| `:core` | `apps/core` |
| `:features:workout` | `apps/features/workout` |
| `:features:nutrition` | `apps/features/nutrition` |
| `:features:onboarding` | `apps/features/onboarding` |
| `:features:auth` | `apps/features/auth` |
| `:features:profile` | `apps/features/profile` |
| `:features:settings` | `apps/features/settings` |
| `:features:progress` | `apps/features/progress` |
| `:features:coaching` | `apps/features/coaching` |

## Product Feature Ownership

| Feature | Primary owner |
| :--- | :--- |
| Auth | `apps/features/auth` |
| Onboarding | `apps/features/onboarding` |
| Home | `apps/app` for shell composition; a dedicated home feature package can be introduced when it needs real ownership. |
| Workout | `apps/features/workout`, including the Workout Library route and workout screens/flows. |
| Nutrition | `apps/features/nutrition`, including the future Meal Plan route after nutrition diary MVP. |
| Supabase Auth/data/Storage | future `supabase/` with feature repositories and client-safe contracts |
| Coaching | `apps/features/coaching` and future protected Gemini/server runtime |
| Progress | `apps/features/progress` |
| Recovery | future `apps/features/recovery`; create only after its first data source and privacy/sync boundary are approved |
| Profile | `apps/features/profile` |
| Settings | `apps/features/settings` |
| Wear workout and nutrition quick-action flows | `apps/wear` with shared contracts/events from `apps/shared` when useful |
| Apple Watch flows | future `apps/watchos` if/when introduced |

## Ownership Rules

- `apps/app` is a thin shell. It wires routes, providers, app startup, and platform entry configuration.
- `apps/app` must not own workout, nutrition, onboarding, progress, profile, settings, or coaching business logic.
- `apps/core` owns reusable Flutter UI, theme tokens, shell components, public route contracts, and the future reusable `TioAvatar` component.
- `apps/core` must not import feature packages.
- `apps/shared` must stay pure Dart and must not import Flutter UI, platform code, or feature presentation code.
- `apps/shared` owns the single `AppMode` enum (`workout`, `nutrition`, `hybrid`), guided destination mapping, and pure-Dart mode preference boundary so every Flutter feature package reads the same contracts.
- Future pure-Dart destination identity, eligible-layout, and navigation-preference contracts belong in `apps/shared`; they must not encode Flutter widgets or feature business decisions.
- `apps/core` may own generic navigation, action-slot, and persistent-activity UI components, but it must not decide whether a workout can start or a meal can be logged.
- `apps/app` composes registered destinations, prepared Home sections, and feature-owned action descriptors. It must not implement Workout, Nutrition, Progress, Coach, or Social rules.
- Feature packages own their own `domain`, `data`, and `presentation` layers.
- Profile is an account and fitness hub, not the owner of workout, nutrition, coaching, or progress logic.
- Workout owns workout plans, exercises, sets, reps, rest timers, routines, history, and workout settings.
- Workout is Routine/Program-first: an active session starts from a selected Routine or Program session, not a standalone Quick Start. Workout also owns its local exercise catalog, muscle heatmap, training radar map, and workout calendar when recorded history is available.
- Workout owns one canonical start/resume workflow. Home, Workout, Routine Library, or a persistent shell entry may launch it, but no other module duplicates its validation or active-session state.
- Nutrition owns meals, foods, calories, macros, water, targets, and nutrition settings.
- Nutrition owns one canonical meal-log workflow. Home, Nutrition, Meal Diary, or future Meal Plan may launch it with context, but no other module duplicates its save or target logic.
- Profile provides approved personal and fitness context; Nutrition owns Nutrition Target calculations and overrides, while Workout owns Workout Settings and training defaults. Cross-feature reads use stable contracts only.
- Wear OS may initiate nutrition quick actions through stable nutrition contracts, but it does not own the full nutrition diary or Meal Plan editing.
- Progress owns weight, measurements, progress photos, streaks, trends, achievements, and analytics.
- Recovery will own readiness and rest calculations/presentation when its first vertical slice is approved. No other feature calculates Recovery locally.
- Coaching may read workout, nutrition, progress, recovery, and profile data through clear contracts.
- Promoting Routine Library or Meal Plan into a future custom navigation slot does not create a new feature owner or duplicate the route/screen.
- Watch apps own their own UI and platform integrations.
- Supabase owns the planned first Auth, data, private Storage, migrations, and RLS boundary. A future backend owns protected Gemini/AI orchestration, advanced integrations, and long-running work only when needed.

## Feature Package Rules

Each large feature should follow this structure:

```text
apps/features/<feature>/
├─ lib/
│  ├─ <feature>.dart
│  └─ src/
│     ├─ domain/
│     │  ├─ entities/
│     │  ├─ repositories/
│     │  └─ usecases/
│     ├─ data/
│     │  ├─ datasources/
│     │  ├─ dto/
│     │  ├─ mappers/
│     │  └─ repositories/
│     └─ presentation/
│        ├─ routes/
│        ├─ navigation/
│        ├─ controllers/
│        ├─ state/
│        ├─ pages/
│        └─ widgets/
├─ test/
└─ pubspec.yaml
```

This shape is required when a feature grows beyond a simple screen or when it is expected to reach many screens, such as workout, nutrition, onboarding, progress, or coaching.

## Cross-Feature Rules

When one feature needs another feature's data:

1. Define a stable domain contract.
2. Use repository/use case boundaries.
3. Avoid importing another feature's presentation layer.
4. Avoid direct database or API shape leaking into UI.
5. Document the ownership decision if it changes architecture.

Allowed examples:

- `coaching` reads workout summaries through a workout domain contract.
- `profile` launches a progress route but does not own progress analytics.
- `settings` launches nutrition target settings but does not own nutrition calculations.
- `wear` sends workout events and nutrition quick actions using stable sync payloads and shared contracts.

## Anti-Patterns

Avoid:

- putting feature business logic in the global app shell
- putting feature business logic in `apps/core`
- importing feature presentation code from another feature
- putting Flutter UI code in `apps/shared`
- creating empty packages for future ideas before a real slice exists
- letting screens call APIs directly
- leaking database table shape into widgets
- putting watch-specific UI into phone app widgets
- putting phone home UI into watch apps
- putting server-only keys, admin keys, service-role keys, AI secrets, or private credentials into client apps
