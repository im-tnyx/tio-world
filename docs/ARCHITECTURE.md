# Architecture

`tio-world` is a Flutter-first product monorepo with native smartwatch apps and a root-level backend workspace.

## Core Promise

Move fast on product, but keep boundaries clean.

- `apps/app` owns the Flutter Android and iOS phone app shell.
- `apps/wear` owns the native Wear OS companion app.
- `apps/shared` owns pure Dart shared models, entities, repository contracts, use cases, results, errors, and utilities.
- `apps/core` owns Flutter design system, route contracts, shell components, reusable UI, tokens, constants, and extensions.
- `apps/features/*` owns feature packages such as workout, nutrition, onboarding, auth, profile, settings, progress, and coaching.
- `backend/*` owns API, jobs, AI coach runtime, database work, secure integrations, and server-only behavior.
- `docs/` owns architecture and implementation direction.
- `.ai/` owns short AI orientation files.

## Current Target Shape

```text
tio-world/
├─ apps/
│  ├─ app/                         # Flutter Android + iOS phone app shell
│  ├─ wear/                        # Native Wear OS companion app
│  ├─ shared/                      # Pure Dart shared models/contracts/use cases
│  ├─ core/                        # Flutter design system, shell, routing contracts
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
└─ .ai/
```

Some folders may be created later. Do not create empty future modules unless a real feature slice needs them.

## Platform Strategy

| Platform | Stack | Note |
| :--- | :--- | :--- |
| Android phone | Flutter | Shared mobile UI. |
| iPhone | Flutter | Shared mobile UI. |
| Wear OS | Kotlin + Compose for Wear OS | Native watch performance, Health Services, tiles, complications, and Data Layer APIs. |
| Apple Watch | Swift + SwiftUI | Native watchOS experience when introduced. |
| Backend | Server-side workspace | API, sync, coaching, database, jobs, and protected integrations. |

## Native-Style To Flutter Module Mapping

The Flutter workspace mirrors the native modular structure used in `Tio-hub`.

| Native-style module | Flutter workspace path | Responsibility |
| :--- | :--- | :--- |
| `:app` | `apps/app` | Flutter Android + iOS phone app shell, bootstrap, route composition, provider wiring. |
| `:wear` | `apps/wear` | Native Wear OS companion app. |
| `:shared` | `apps/shared` | Pure Dart models, repository contracts, use cases, results, errors, and shared utilities. |
| `:core` | `apps/core` | Design system, tokens, shared widgets, shell, route contracts, constants, extensions. |
| `:features:workout` | `apps/features/workout` | Workout feature package and all workout screens/flows. |
| `:features:nutrition` | `apps/features/nutrition` | Nutrition feature package and all nutrition screens/flows. |
| `:features:onboarding` | `apps/features/onboarding` | Onboarding feature package and all onboarding screens/flows. |
| `:features:auth` | `apps/features/auth` | Auth feature package and session entry flows. |
| `:features:profile` | `apps/features/profile` | Profile launcher, account, and fitness hub package. |
| `:features:settings` | `apps/features/settings` | App settings and account controls package. |
| `:features:progress` | `apps/features/progress` | Progress, measurements, photos, streaks, and analytics package. |
| `:features:coaching` | `apps/features/coaching` | Coaching UI package and backend-facing coaching contracts. |

## Flutter Feature Package Pattern

Each large product feature should be a complete Flutter/Dart package under `apps/features/<feature>`.

This keeps features manageable when workout, nutrition, onboarding, progress, or coaching grow to 20+ screens.

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

Use one-way dependencies.

```text
apps/app
  ↓
apps/features/*
  ↓
apps/core + apps/shared
```

Rules:

- `apps/app` wires app bootstrap, route composition, providers, and platform entry configuration.
- `apps/app` should not own feature business logic.
- Feature packages can depend on `apps/core` and `apps/shared`.
- `apps/core` must not import feature packages.
- `apps/shared` must stay pure Dart and must not import Flutter UI.
- Feature presentation layers must not import another feature's presentation layer.
- Cross-feature reads should go through stable contracts, repositories, or use cases.
- Backend API/table shapes must not leak directly into widgets or screens.

## Main Mobile Tabs

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

## Recommended Flutter Stack

```text
Riverpod
go_router
dio
freezed
json_serializable
melos
```

Use feature-owned routes and navigation registration. Keep app-level routing composition in `apps/app`, and keep feature internals inside the owning feature package.

## Watch Rules

Watch apps should stay small and fast.

Good watch responsibilities:

- workout start, pause, resume, finish
- active set input
- rest timer
- heart rate display
- steps and calories summary
- offline active workout snapshot
- quick sync
- tiles and complications where useful

Avoid putting heavy dashboards, long forms, full AI chat, large analytics flows, or image-heavy UI on watches.

## Naming Rules

The Flutter phone app folder is:

```text
apps/app
```

The Wear OS folder is:

```text
apps/wear
```

Keep these names consistent across docs, Melos config, CI, scripts, and future app config.

## More Detail

Read [`FLUTTER_MODULAR_STRUCTURE.md`](FLUTTER_MODULAR_STRUCTURE.md) for the full apps-based Flutter workspace structure and package naming rules.
