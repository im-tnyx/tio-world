# Module Ownership

This document defines where code should live in `tio-world`.

`tio-world` uses an apps-based Flutter workspace that mirrors the modular native structure from `Tio-hub`.

## Top-Level Ownership

| Path | Owner / Responsibility |
| :--- | :--- |
| `apps/app` | Flutter Android and iOS phone app shell, bootstrap, route composition, providers, and platform entry wiring. |
| `apps/wear` | Native Wear OS companion app. |
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
| `backend/api` | Public API surface and server-side route handlers. |
| `backend/ai-coach` | Coaching runtime, AI orchestration, prompt logic, safety boundaries, and server-only model integrations. |
| `backend/jobs` | Scheduled and background jobs. |
| `backend/db` | Database schema, migrations, seed data, and policies. |
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
| Dashboard | `apps/app` for shell composition; dashboard feature package can be introduced when it needs real ownership. |
| Workout | `apps/features/workout` |
| Nutrition | `apps/features/nutrition` |
| Coaching | `apps/features/coaching` and server runtime in `backend/ai-coach` |
| Progress | `apps/features/progress` |
| Profile | `apps/features/profile` |
| Settings | `apps/features/settings` |
| Wear workout flows | `apps/wear` with shared contracts/events from `apps/shared` when useful |
| Apple Watch flows | future `apps/watchos` if/when introduced |

## Ownership Rules

- `apps/app` is a thin shell. It wires routes, providers, app startup, and platform entry configuration.
- `apps/app` must not own workout, nutrition, onboarding, progress, profile, settings, or coaching business logic.
- `apps/core` owns reusable Flutter UI, theme tokens, shell components, and public route contracts.
- `apps/core` must not import feature packages.
- `apps/shared` must stay pure Dart and must not import Flutter UI, platform code, or feature presentation code.
- Feature packages own their own `domain`, `data`, and `presentation` layers.
- Profile is an account and fitness hub, not the owner of workout, nutrition, coaching, or progress logic.
- Workout owns workout plans, exercises, sets, reps, rest timers, routines, history, and workout settings.
- Nutrition owns meals, foods, calories, macros, water, targets, and nutrition settings.
- Progress owns weight, measurements, progress photos, streaks, trends, achievements, and analytics.
- Coaching may read workout, nutrition, progress, recovery, and profile data through clear contracts.
- Watch apps own their own UI and platform integrations.
- Backend owns server-side orchestration, protected operations, AI runtime, and database behavior.

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
- `wear` sends workout events using stable sync payloads and shared contracts.

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
- putting phone dashboard UI into watch apps
- putting server-only keys, admin keys, service-role keys, AI secrets, or private credentials into client apps
