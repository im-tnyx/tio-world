# tio-world

`tio-world` is the Flutter-first product monorepo for **TNYX / Tio**: an AI-powered health, fitness, workout, nutrition, progress, and coaching companion across mobile phones and smartwatches.

This repository follows one practical rule: **move fast on product, keep boundaries clean.**

The phone app and Wear OS companion use Flutter. Apple Watch stays native for platform integrations. Supabase is the current Auth/data foundation and owns approved Postgres/RLS, migrations, and Storage boundaries; protected AI and advanced server operations remain future server-side work until explicitly authorized.

## Project Overview

Tio is designed as a premium health and wellness platform that helps users manage:

- Personalized onboarding: goals, body metrics, preferences, training level, and nutrition targets.
- Nutrition diary: calories, macros, meals, water, food search, meal editing, and adherence insights.
- Workout management: routines, exercises, sets, reps, weight, rest timers, and workout history.
- Progress tracking: body weight, measurements, photos, streaks, trends, and goal progress.
- Watch companion: fast workout controls, set input, rest timer, heart rate, steps, calories, nutrition quick actions, and quick sync.
- AI coach: recovery guidance, sleep insights, HRV-aware suggestions, habit nudges, and personalized coaching.

## Platform Strategy

| Surface | Recommended stack | Why |
| :--- | :--- | :--- |
| Android phone | Flutter | Shared mobile UI, fast iteration, single Dart codebase. |
| iPhone | Flutter | Same mobile UI and feature flow as Android. |
| Wear OS | Flutter | Existing Flutter companion package sharing design tokens, contracts, and watch-first workflows. |
| Apple Watch | Swift + SwiftUI | Native watchOS integration, HealthKit, complications, and WatchConnectivity. |
| Auth, data, and media | Supabase | Active Auth/Postgres/RLS foundation with approved Storage added only through bounded feature slices. |
| Protected API | Future `services/api` — Node.js + TypeScript + Fastify | Locked modular-monolith destination for protected server work, created only when separately authorized. |

> **Watch strategy:** Wear OS remains a Flutter package (`apps/wear`) with watch-first UI, shared design tokens, and shared contracts where useful. Apple Watch uses native SwiftUI for close platform integration.

## Target Repository Shape

`tio-world` uses an apps-based modular Flutter workspace that mirrors the native `:app`, `:shared`, `:core`, and `:features:*` structure. The current checkout contains both the Flutter workspace and the active `supabase/` platform workspace. The accepted future protected server destination is `services/api`; it is architecture-only today and must be created only with its first explicitly authorized backend implementation slice.

The `supabase/` workspace owns approved Auth/platform configuration, schema migrations, RLS policies, Storage boundaries, and database functions. Future protected orchestration belongs under `services/api`; it is not the current database/authentication layer, and no `backend/api` alternate namespace should be introduced.

The current feature packages include `home`, `auth`, `onboarding`, `workout`, `nutrition`, `profile`, `settings`, `progress`, and `coaching`.

```text
tio-world/
├─ apps/
│  ├─ app/                         # Flutter Android + iOS phone app shell
│  ├─ wear/                        # Flutter Wear OS companion app
│  ├─ watchos/                     # Future native Swift + SwiftUI Apple Watch app
│  ├─ shared/                      # Pure Dart shared models/contracts/use cases
│  ├─ core/                        # Flutter design system, shell, route contracts
│  └─ features/
│     ├─ auth/
│     ├─ onboarding/
│     ├─ home/
│     ├─ workout/
│     ├─ nutrition/
│     ├─ profile/
│     ├─ settings/
│     ├─ progress/
│     └─ coaching/
├─ supabase/                       # ACTIVE config, migrations, policies, approved functions
├─ services/                       # Future runnable protected server processes
│  ├─ api/                         # Future Node.js + TypeScript + Fastify modular monolith
│  └─ worker/                      # Future only when a real async workload requires it
├─ packages/                       # Future reusable code only when a real extraction boundary exists
├─ docs/
├─ .github/
├─ .ai/
└─ README.md
```

The future paths above document accepted destinations only. Do not create empty `services/`, `worker/`, or package folders merely to match the tree.

## Native-Style To Flutter Module Mapping

| Native-style module | Flutter workspace path |
| :--- | :--- |
| `:app` | `apps/app` |
| `:wear` | `apps/wear` |
| `:shared` | `apps/shared` |
| `:core` | `apps/core` |
| `:features:home` | `apps/features/home` |
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
- `apps/features/home` owns the Home screen presentation slice; `apps/app` only composes it into the shell.
- Backend table/API shapes must not leak directly into widgets.
- Feature presentation layers must not import another feature's presentation layer.
- Watch apps own their own UI and platform integrations.
- Heavy AI, analytics, sync reconciliation, and protected credentials belong on the future `services/api` protected server boundary when explicitly implemented.
- Supabase Auth remains the identity authority; a future protected API verifies Supabase-issued access tokens rather than introducing a second canonical auth provider.

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

Tio keeps three `AppMode` values. The visible guided tabs are derived from the active mode, so the layout is mode-dependent rather than fixed:

| App mode | Guided default tabs |
| :--- | :--- |
| `workout` | Home, Workout, Progress |
| `nutrition` | Home, Nutrition, Progress |
| `hybrid` | Home, Workout, Nutrition, Progress |

Onboarding starts with App Mode selection, and Settings can change it later. A final-stage Navigation & Tabs upgrade will let the user keep Home fixed and manually choose three to six eligible destinations. Mode, feature availability, and release stage constrain the destination catalog.

The planned full onboarding keeps one `/onboarding` parent screen: top progress
and bottom actions remain fixed while a mode-derived child step changes. Draft
mode, confirmed App Mode, and onboarding completion are separate so the first
choice cannot open Home prematurely. See the
[Onboarding flow architecture](docs/ONBOARDING_ARCHITECTURE.md).

Workout Library and Meal Plan remain owned routes inside Workout and Nutrition. After their features exist, the custom layout may promote them as shortcuts without moving their business logic or duplicating screens. Coach becomes eligible only in Phase 7; You and future Social remain gated by their own approved product slices.

Profile remains the account launch surface in the guided Home chrome. Settings opens from Profile or an approved feature-owned entry, not from a separate Home top-bar icon. A future You destination may group personal and account flows without changing their owners.

```text
Home -> Profile avatar/account entry -> Profile -> Profile photo / Settings
```

## Reusable Profile Avatar

`apps/core` owns one reusable `TioAvatar` component for the mobile shell, lists,
cards, Profile, and profile-photo fallback. It exposes five semantic
sizes—`compact`, `small`, `medium`, `large`, and `extraLarge`—so each screen
chooses an intentional scale instead of hardcoding dimensions. It is circular by
default, supports a rounded Profile treatment, accepts an optional image, and
falls back safely to initials or an icon. Free avatars have no plan frame, Plus
may use the semantic gradient ring, and Pro may use the semantic hexagon frame;
`extraLarge` remains frame-free for the full-screen photo surface.

## Reusable Actions

`apps/core` owns `TioButton` primary, secondary, and ghost variants. Shared tokens define finite sizing, spacing, pressed/focus/hover/disabled states, outlines, and loading presentation. Loading prevents duplicate actions, exposes progress semantics, and uses a static treatment when reduced motion is active; feature screens provide business intent without rebuilding these states.

## Recommended Flutter Stack

```text
State: Riverpod
Navigation: go_router with typed routes
Data: offline-first repository pattern
Local persistence: Drift, Isar, or similar after the first real data slice is chosen
Code generation: freezed + json_serializable
HTTP/API: dio when remote APIs are introduced
Design system: Material 3 Expressive direction through `apps/core` tokens and components
Workspace: melos
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

- [Documentation index](docs/README.md)
- [Architecture](docs/ARCHITECTURE.md)
- [AI context and active tasks](.ai/README.md)
- [Onboarding flow architecture](docs/ONBOARDING_ARCHITECTURE.md)

For platform trust, data, recovery, environment, and future protected-service contracts, read:

- [Authentication architecture](docs/AUTH_ARCHITECTURE.md)
- [Supabase server access](docs/SUPABASE_SERVER_ACCESS.md)
- [Secrets & environment strategy](docs/SECRETS_AND_ENVIRONMENTS.md)
- [Data & privacy governance](docs/DATA_PRIVACY_GOVERNANCE.md)
- [Database backup & recovery](docs/DATABASE_BACKUP_RECOVERY.md)
- [API lifecycle & client compatibility](docs/API_LIFECYCLE.md)
- [Feature rollout & kill switch](docs/FEATURE_ROLLOUT.md)

For the phone and Wear OS screen-by-screen product plan, read:

- [Screen catalog](docs/screens/README.md)

For durable architecture decisions, the phone design-system contract, and MVP delivery gates, read:

- [Architecture Decision Records](docs/adr/README.md)
- [UX/UI system](docs/UX_UI_SYSTEM.md)
- [MVP acceptance gates](docs/MVP_ACCEPTANCE.md)

## License and source-use notice

Copyright © 2026 TNYX. All rights reserved.

`tio-world` is proprietary TNYX software. Public source visibility on GitHub does not make this project open source or free software and does not grant general permission to reuse, modify, redistribute, sublicense, sell, white-label, commercially host, or create derivative products from TNYX-owned code.

GitHub platform functionality, applicable law, and any separate written authorization from TNYX may provide limited rights beyond this notice. Third-party components remain governed by their own licenses and notices.

See [NOTICE.md](NOTICE.md) for the full repository source-use notice, including the historical MIT-license transition boundary.
