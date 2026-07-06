# tio-world

`tio-world` is the Flutter-first product monorepo for **TNYX / Tio**: an AI-powered health, fitness, workout, nutrition, progress, and coaching companion across mobile phones and smartwatches.

This repository follows one practical rule: **move fast on product, keep boundaries clean.**

The phone app uses Flutter. Watch apps stay native for performance, sensors, battery, tiles, complications, and platform integrations. Backend, AI, persistence, and protected operations stay server-side.

## Project Overview

Tio is designed as a premium health and wellness platform that helps users manage:

- Personalized onboarding: goals, body metrics, preferences, training level, and nutrition targets.
- Nutrition diary: calories, macros, meals, water, food search, meal editing, and adherence insights.
- Workout management: routines, exercises, sets, reps, weight, rest timers, and workout history.
- Progress tracking: body weight, measurements, photos, streaks, trends, and goal progress.
- Watch companion: fast workout controls, set input, rest timer, heart rate, steps, calories, and quick sync.
- AI coach: recovery guidance, sleep insights, HRV-aware suggestions, habit nudges, and personalized coaching.

## Platform Strategy

| Surface | Recommended stack | Why |
| :--- | :--- | :--- |
| Android phone | Flutter | Shared mobile UI, fast iteration, single Dart codebase. |
| iPhone | Flutter | Same mobile UI and feature flow as Android. |
| Wear OS | Kotlin + Compose for Wear OS | Fast, lightweight, battery-friendly, direct Health Services and Data Layer integration. |
| Apple Watch | Swift + SwiftUI | Native watchOS integration, HealthKit, complications, and WatchConnectivity. |
| Backend/API | Server-side workspace | AI, analytics, persistence, sync, protected operations, and heavy processing. |

> **Watch rule:** Do not force Flutter onto watch apps for core fitness workflows. Watch UI should remain native. Share contracts, API payloads, sync events, and backend behavior, not watch UI code.

## Current Target Repository Shape

`tio-world` uses an apps-based modular Flutter workspace that mirrors the native `:app`, `:shared`, `:core`, and `:features:*` structure.

```text
tio-world/
├─ apps/
│  ├─ app/                         # Flutter Android + iOS phone app shell
│  ├─ wear/                        # Native Wear OS companion app
│  ├─ shared/                      # Pure Dart shared models/contracts/use cases
│  ├─ core/                        # Flutter design system, shell, route contracts
│  └─ features/
│     ├─ auth/
│     ├─ onboarding/
│     ├─ workout/
│     ├─ nutrition/
│     ├─ profile/
│     ├─ settings/
│     ├─ progress/
│     └─ coaching/
├─ backend/
│  ├─ api/
│  ├─ ai-coach/
│  ├─ jobs/
│  └─ db/
├─ docs/
├─ tools/
├─ .github/
├─ .ai/
└─ README.md
```

## Native-Style To Flutter Module Mapping

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

## Architecture Principles

- `apps/app` is a thin Flutter app shell. It owns app startup, route composition, providers, and platform entry wiring.
- `apps/core` owns reusable Flutter UI, design tokens, shell components, and public route contracts.
- `apps/shared` stays pure Dart. It owns models, entities, repository contracts, use cases, result/error types, and shared utilities.
- `apps/features/*` packages own their own `domain`, `data`, and `presentation` layers.
- Backend table/API shapes must not leak directly into widgets.
- Feature presentation layers must not import another feature's presentation layer.
- Watch apps own their own UI and platform integrations.
- Heavy AI, analytics, sync reconciliation, and protected credentials belong on the backend.

## Feature Package Pattern

Each large feature should be a complete package. This keeps workout, nutrition, onboarding, progress, and coaching manageable when each grows to 20+ screens.

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

## Dependency Direction

```text
apps/app
  ↓
apps/features/*
  ↓
apps/core + apps/shared
```

Rules:

- `apps/core` must not import feature packages.
- `apps/shared` must not import Flutter UI.
- Feature packages can depend on `apps/core` and `apps/shared`.
- Cross-feature reads should use stable contracts, repositories, or use cases.

## Main Mobile Tabs

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

## Recommended Flutter Stack

```text
Riverpod
go_router
dio
freezed
json_serializable
melos
```

## Getting Started

Clone the repo:

```bash
git clone https://github.com/im-tnyx/tio-world.git
cd tio-world
```

After Flutter workspace files are configured:

```bash
dart pub global activate melos
flutter pub get
melos bootstrap
```

Run the Flutter phone app:

```bash
cd apps/app
flutter run
```

Run validation:

```bash
melos analyze
melos test
```

## Documentation

Start here:

| Document | Purpose |
| :--- | :--- |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Repository shape, architecture principles, app boundaries, and dependency direction. |
| [`docs/FLUTTER_MODULAR_STRUCTURE.md`](docs/FLUTTER_MODULAR_STRUCTURE.md) | Detailed Flutter apps-based modular structure. |
| [`docs/MODULE_OWNERSHIP.md`](docs/MODULE_OWNERSHIP.md) | Ownership rules for app shell, core, shared, feature packages, watch, and backend. |
| [`docs/DEVELOPMENT_SETUP.md`](docs/DEVELOPMENT_SETUP.md) | Local setup, required tools, bootstrap commands, and validation flow. |
| [`docs/WATCH_STRATEGY.md`](docs/WATCH_STRATEGY.md) | Wear OS and Apple Watch strategy. |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Practical MVP and phased product roadmap. |

## Security

This is a public repository. Never commit:

- `.env` files
- service-role keys or admin keys
- signing files or private certificates
- production logs
- real health records
- local database dumps
- APK, AAB, IPA, or archive artifacts
- screenshots containing personal information

## Roadmap Rule

Each phase should produce a working, testable slice before the next phase grows.
