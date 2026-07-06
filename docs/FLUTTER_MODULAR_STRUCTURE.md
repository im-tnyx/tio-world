# Flutter Modular Structure

This document defines the Flutter equivalent of the native `Tio-hub` modular structure.

The goal is simple: keep the Flutter app scalable when each product area grows to 20+ screens, while keeping the app shell thin and feature ownership clear.

## Decision

`tio-world` uses an apps-based modular Flutter workspace.

Native Gradle-style module names map to Flutter/Melos package folders like this:

| Native-style module | Flutter workspace path | Responsibility |
| :--- | :--- | :--- |
| `:app` | `apps/app` | Flutter Android + iOS phone app shell, bootstrap, routing composition, provider wiring. |
| `:wear` | `apps/wear` | Native Wear OS companion app. |
| `:shared` | `apps/shared` | Pure Dart models, entities, repository contracts, use cases, results, errors, and shared utilities. |
| `:core` | `apps/core` | Flutter design system, tokens, reusable UI, shell components, route contracts, app constants, extensions. |
| `:features:workout` | `apps/features/workout` | Workout feature package and all workout screens/flows. |
| `:features:nutrition` | `apps/features/nutrition` | Nutrition feature package and all nutrition screens/flows. |
| `:features:onboarding` | `apps/features/onboarding` | Onboarding feature package and all onboarding screens/flows. |
| `:features:auth` | `apps/features/auth` | Auth feature package and session entry flows. |
| `:features:profile` | `apps/features/profile` | Profile launcher/account/fitness hub package. |
| `:features:settings` | `apps/features/settings` | App settings and account controls package. |
| `:features:progress` | `apps/features/progress` | Progress, measurements, photos, streaks, and analytics package. |
| `:features:coaching` | `apps/features/coaching` | Coach UI package and backend-facing coaching contracts. |

## Repository Shape

```text
tio-world/
├─ apps/
│  ├─ app/                         # Flutter Android + iOS phone app shell
│  │  ├─ lib/
│  │  │  ├─ main.dart
│  │  │  └─ app/
│  │  │     ├─ app.dart
│  │  │     ├─ bootstrap.dart
│  │  │     └─ router.dart
│  │  ├─ android/
│  │  ├─ ios/
│  │  ├─ test/
│  │  └─ pubspec.yaml
│  │
│  ├─ wear/                        # Native Wear OS app
│  │  ├─ src/main/
│  │  │  ├─ AndroidManifest.xml
│  │  │  └─ kotlin/com/tnyx/wear/
│  │  └─ build.gradle.kts
│  │
│  ├─ shared/                      # Pure Dart shared models/contracts
│  │  ├─ lib/
│  │  │  ├─ shared.dart
│  │  │  └─ src/
│  │  │     ├─ entities/
│  │  │     ├─ models/
│  │  │     ├─ repositories/
│  │  │     ├─ usecases/
│  │  │     ├─ result/
│  │  │     ├─ error/
│  │  │     └─ utils/
│  │  ├─ test/
│  │  └─ pubspec.yaml
│  │
│  ├─ core/                        # Flutter design system, shell, routing contracts
│  │  ├─ lib/
│  │  │  ├─ core.dart
│  │  │  └─ src/
│  │  │     ├─ theme/
│  │  │     ├─ shell/
│  │  │     ├─ widgets/
│  │  │     ├─ routing/
│  │  │     ├─ constants/
│  │  │     └─ extensions/
│  │  ├─ test/
│  │  └─ pubspec.yaml
│  │
│  └─ features/
│     ├─ auth/
│     ├─ onboarding/
│     ├─ workout/
│     ├─ nutrition/
│     ├─ profile/
│     ├─ settings/
│     ├─ progress/
│     └─ coaching/
│
├─ backend/
│  ├─ api/
│  ├─ ai-coach/
│  ├─ jobs/
│  └─ db/
│
├─ docs/
├─ tools/
├─ melos.yaml
├─ pubspec.yaml
├─ package.json
├─ pnpm-workspace.yaml
├─ .env.example
├─ .gitignore
└─ README.md
```

## Dependency Direction

Use one-way dependencies.

```text
apps/app
  ↓
apps/features/*
  ↓
apps/core + apps/shared
```

Rules:

- `apps/app` wires routes, dependency injection/providers, shell, and platform bootstrap.
- `apps/app` should not own workout, nutrition, onboarding, progress, profile, settings, or coaching business logic.
- `apps/app/lib` should stay thin: `main.dart` plus app-level bootstrap/routing only.
- Feature packages can depend on `apps/core` and `apps/shared`.
- `apps/core` must not import feature packages.
- `apps/shared` must stay pure Dart and must not import Flutter UI.
- Feature presentation layers must not import another feature's presentation layer.
- Cross-feature reads should go through stable contracts, repositories, or use cases.

## Feature Package Pattern

Each large feature should be a complete package. This keeps 20+ screens per feature manageable.

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

## Workout Example

```text
apps/features/workout/
├─ lib/
│  ├─ workout.dart
│  └─ src/
│     ├─ domain/
│     │  ├─ entities/
│     │  │  ├─ workout.dart
│     │  │  ├─ workout_session.dart
│     │  │  ├─ workout_set.dart
│     │  │  ├─ set_type.dart
│     │  │  ├─ exercise.dart
│     │  │  └─ routine.dart
│     │  ├─ repositories/
│     │  │  └─ workout_repository.dart
│     │  └─ usecases/
│     │     ├─ start_workout.dart
│     │     ├─ complete_set.dart
│     │     ├─ finish_workout.dart
│     │     └─ calculate_volume.dart
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
│        │  ├─ workout_home_page.dart
│        │  ├─ routine_list_page.dart
│        │  ├─ routine_detail_page.dart
│        │  ├─ active_workout_page.dart
│        │  ├─ exercise_picker_page.dart
│        │  ├─ set_input_page.dart
│        │  ├─ rest_timer_page.dart
│        │  ├─ workout_summary_page.dart
│        │  └─ workout_history_page.dart
│        └─ widgets/
├─ test/
└─ pubspec.yaml
```

## App Shell Responsibilities

`apps/app` should stay small.

Allowed in `apps/app`:

- `main.dart`
- bootstrap
- app-level providers
- route composition
- root navigation
- environment loading
- platform entry configuration

Not allowed in `apps/app`:

- workout calculations
- nutrition macro logic
- onboarding question logic
- profile repository logic
- progress analytics
- AI coaching orchestration
- direct database table shape dependencies
- feature-owned screens or reusable widgets

## Main Tabs

Primary mobile tabs:

```text
Dashboard
Workout
Nutrition
Coach
Progress
```

Profile and Settings are launch surfaces, not primary bottom tabs.

```text
Profile  -> avatar/account entry
Settings -> gear/menu entry
```

## Melos Workspace

Root `melos.yaml` should include:

```yaml
name: tio_world

packages:
  - apps/app
  - apps/shared
  - apps/core
  - apps/features/**
```
