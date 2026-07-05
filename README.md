# tio-world

`tio-world` is the Flutter-first product monorepo for **TNYX / Tio**: an AI-powered health, fitness, workout, nutrition, progress, and coaching companion across mobile phones and smartwatches.

This repository is built with one practical rule: **move fast on product, keep boundaries clean.** Mobile UI stays simple, feature logic stays inside feature/domain layers, watch apps stay native for performance, and backend or persistence details enter the app through repository contracts instead of leaking into screens.

> [!NOTE]
> **Documentation baseline:** This root `README.md` plus `docs/` are the source of truth for architecture, module ownership, setup, and future implementation work.

---

## 🎯 Project Overview

Tio is designed as a premium health and wellness platform that helps users manage:

- **📱 Personalized onboarding:** Goals, body metrics, preferences, training level, and nutrition targets.
- **🥗 Nutrition diary:** Calories, macros, meals, water, food search, meal editing, and adherence insights.
- **🏋️ Workout management:** Routines, exercises, sets, reps, weight, rest timers, and workout history.
- **📈 Progress tracking:** Body weight, measurements, photos, streaks, trends, and goal progress.
- **⌚ Watch companion:** Fast workout controls, set input, rest timer, heart rate, steps, calories, and quick sync.
- **🤖 AI coach:** Recovery guidance, sleep insights, HRV-aware suggestions, habit nudges, and personalized coaching.

> [!IMPORTANT]
> **Project tone:** Practical, clean, and contributor-friendly. New contributors should read the docs, understand module boundaries, and start with small focused PRs.

---

## 🧱 Product Platform Strategy

`tio-world` uses Flutter for the shared Android and iOS phone app, but keeps smartwatch apps native.

| Surface | Recommended stack | Why |
| :--- | :--- | :--- |
| Android phone | Flutter | Shared mobile UI, fast iteration, single Dart codebase. |
| iPhone | Flutter | Same mobile UI and feature flow as Android. |
| Wear OS | Kotlin + Compose for Wear OS | Fast, lightweight, battery-friendly, direct Health Services integration. |
| Apple Watch | Swift + SwiftUI | Native watchOS integration, HealthKit, complications, and WatchConnectivity. |
| Backend/API | Node/NestJS, Kotlin, Go, or existing backend choice | AI, analytics, persistence, sync, and heavy processing stay server-side. |

> [!IMPORTANT]
> **Watch rule:** Do not force Flutter onto watch apps for core fitness workflows. Watch UI should remain native. Share concepts, API contracts, and backend behavior, not watch UI code.

---

## 🏗️ Repository Shape

```text
tio-world/
├── README.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── LICENSE
├── .env.example
├── .gitignore
├── melos.yaml
├── pubspec.yaml
├── package.json
├── pnpm-workspace.yaml
├── turbo.json
│
├── apps/
│   ├── mobile/                         # Flutter Android + iOS phone app
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── app/
│   │   │   │   ├── app.dart
│   │   │   │   ├── bootstrap.dart
│   │   │   │   ├── router.dart
│   │   │   │   └── providers.dart
│   │   │   │
│   │   │   ├── core/
│   │   │   │   ├── config/
│   │   │   │   ├── constants/
│   │   │   │   ├── error/
│   │   │   │   ├── result/
│   │   │   │   ├── utils/
│   │   │   │   └── extensions/
│   │   │   │
│   │   │   ├── shared/
│   │   │   │   ├── widgets/
│   │   │   │   ├── theme/
│   │   │   │   ├── design_system/
│   │   │   │   └── services/
│   │   │   │
│   │   │   └── features/
│   │   │       ├── auth/
│   │   │       ├── onboarding/
│   │   │       ├── dashboard/
│   │   │       ├── workout/
│   │   │       ├── nutrition/
│   │   │       ├── progress/
│   │   │       ├── coaching/
│   │   │       ├── profile/
│   │   │       └── settings/
│   │   │
│   │   ├── android/
│   │   ├── ios/
│   │   ├── test/
│   │   ├── integration_test/
│   │   └── pubspec.yaml
│   │
│   ├── wear-os/                        # Native Wear OS app
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml
│   │   │   └── kotlin/com/tnyx/wear/
│   │   │       ├── MainActivity.kt
│   │   │       ├── app/
│   │   │       ├── navigation/
│   │   │       ├── screens/
│   │   │       │   ├── workout/
│   │   │       │   ├── health/
│   │   │       │   └── sync/
│   │   │       ├── components/
│   │   │       ├── healthservices/
│   │   │       ├── phonebridge/
│   │   │       ├── tiles/
│   │   │       └── complications/
│   │   └── build.gradle.kts
│   │
│   └── watchos/                        # Native Apple Watch app
│       └── TioWatch/
│           ├── TioWatchApp.swift
│           ├── Views/
│           ├── Components/
│           ├── HealthKit/
│           ├── WatchConnectivity/
│           └── Complications/
│
├── packages/                           # Reusable Dart packages
│   ├── core_models/
│   ├── api_client/
│   ├── design_system/
│   ├── sync_core/
│   ├── workout_engine/
│   ├── nutrition_engine/
│   └── analytics_core/
│
├── backend/
│   ├── api/
│   ├── ai-coach/
│   ├── jobs/
│   └── db/
│
├── docs/
│   ├── README.md
│   ├── ARCHITECTURE.md
│   ├── FLUTTER_GUIDE.md
│   ├── WATCH_STRATEGY.md
│   ├── API.md
│   ├── TESTING_GUIDE.md
│   └── adr/
│
└── tools/
    ├── scripts/
    ├── ci/
    └── release/
```

---

## 🧩 Architecture Overview

`tio-world` follows feature-based Clean Architecture for the Flutter mobile app.

### Core principles

- **Feature ownership:** Each feature owns its `data`, `domain`, and `presentation` layers.
- **Dumb UI:** Widgets render state and emit actions. They do not call APIs, databases, or repositories directly.
- **Repository contracts:** Domain defines contracts. Data implements them.
- **Package boundaries:** Shared engines and clients live in `packages/`, not inside random app folders.
- **Native watches:** Wear OS and Apple Watch are separate native apps focused on speed, sensors, and battery.
- **Backend-first AI:** Heavy coaching, analytics, recommendations, and model work stay on the backend.
- **No secrets in clients:** Public mobile/watch code must never contain service keys, admin keys, or private credentials.

---

## 📦 Flutter Feature Module Pattern

Each mobile feature should follow this shape:

```text
apps/mobile/lib/features/<feature>/
├── data/
│   ├── datasources/
│   ├── dto/
│   ├── mappers/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
└── presentation/
    ├── pages/
    ├── widgets/
    ├── controllers/
    └── state/
```

Example:

```text
apps/mobile/lib/features/workout/
├── data/
│   ├── datasources/workout_remote_datasource.dart
│   ├── dto/workout_dto.dart
│   ├── mappers/workout_mapper.dart
│   └── repositories/workout_repository_impl.dart
│
├── domain/
│   ├── entities/workout.dart
│   ├── repositories/workout_repository.dart
│   └── usecases/start_workout.dart
│
└── presentation/
    ├── pages/workout_page.dart
    ├── widgets/workout_card.dart
    ├── controllers/workout_controller.dart
    └── state/workout_state.dart
```

### Layer responsibilities

| Layer | Responsibility |
| :--- | :--- |
| `presentation` | Pages, widgets, controllers, state classes, user events. |
| `domain` | Entities, repository contracts, use cases, business rules. |
| `data` | API calls, local storage, DTOs, mappers, repository implementations. |
| `packages/*` | Shared reusable logic that can be consumed by multiple apps or features. |
| `backend/*` | Server APIs, AI coach, jobs, database migrations, and secure integrations. |

> [!IMPORTANT]
> **Hard rule:** `presentation` can depend on `domain`; `domain` must not depend on `presentation` or Flutter UI.

---

## 🧭 Routing Policy

Use `go_router` for mobile navigation.

Recommended route style:

```dart
final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/workout/:id',
      name: 'workout-detail',
      builder: (context, state) {
        final workoutId = state.pathParameters['id']!;
        return WorkoutDetailPage(workoutId: workoutId);
      },
    ),
  ],
);
```

Navigation guidelines:

- Keep route names centralized.
- Avoid hardcoded route strings inside widgets.
- Feature pages should expose clear entry points.
- Bottom tabs stay limited to primary app areas.
- Deep links should map to stable route contracts.
- Auth redirects should live near app-level routing, not inside leaf widgets.

---

## 🧠 State Management

Recommended default:

```text
Riverpod + immutable state + explicit actions
```

Suggested packages:

| Need | Package |
| :--- | :--- |
| State management | `flutter_riverpod` |
| Routing | `go_router` |
| Networking | `dio` |
| Models | `freezed`, `json_serializable` |
| Local database | `drift` or `isar` |
| Secure storage | `flutter_secure_storage` |
| Monorepo | `melos` |
| Crash/error reporting | `Sentry` or `Firebase Crashlytics` |

Controller pattern:

```text
Page -> Controller/Notifier -> UseCase -> Repository -> DataSource
```

Widgets should not know whether data came from cache, Supabase, REST, GraphQL, or local database.

---

## ⌚ Watch App Strategy

Watch apps are not small phone apps. They have different constraints: battery, sensors, glanceable UI, background limits, small screens, and platform-specific health APIs.

### Wear OS app

```text
apps/wear-os/
├── screens/workout/
├── screens/health/
├── screens/sync/
├── healthservices/
├── phonebridge/
├── tiles/
└── complications/
```

Wear OS should focus on:

- Start, pause, resume, and finish workout.
- Current set/reps/weight input.
- Rest timer.
- Heart rate, steps, calories.
- Offline active workout cache.
- Quick sync with phone/backend.
- Tiles and complications only where useful.

### Apple Watch app

```text
apps/watchos/TioWatch/
├── Views/
├── Components/
├── HealthKit/
├── WatchConnectivity/
└── Complications/
```

Apple Watch should focus on:

- Native SwiftUI screens.
- HealthKit integration.
- WatchConnectivity bridge to iPhone.
- Complications and widgets where needed.
- Fast, minimal workout interactions.

> [!IMPORTANT]
> **No heavy watch logic:** AI generation, large charts, full history analysis, image-heavy UI, and deep analytics belong on phone/backend, not watch.

---

## 🔄 Data and Sync Strategy

Target direction:

1. Define domain entities and repository contracts.
2. Use DTOs only inside `data` or `api_client` layers.
3. Keep UI rendering state, not raw API responses.
4. Store active workout and offline-critical data locally.
5. Sync lightweight events from watch to phone/backend.
6. Resolve conflicts server-side where possible.
7. Keep AI coaching and long-history analytics on backend.

Example event flow:

```text
Wear OS set completed
  -> phonebridge/sync queue
  -> mobile app or backend API
  -> workout repository
  -> progress/coaching update
```

---

## 🔐 Security and Secrets

Never commit:

- `.env`
- API secrets
- Supabase service-role keys
- Firebase private keys
- Signing keys
- Keystores
- Provisioning profiles
- APK/AAB/IPA builds
- Local caches or generated outputs

Use `.env.example` for documented variable names only.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK, stable channel.
- Dart SDK included with Flutter.
- Android Studio with Android SDK.
- Xcode for iOS and watchOS work.
- JDK 17 or 21 for Android builds.
- Git.
- Melos for monorepo package management.

Install Melos:

```bash
dart pub global activate melos
```

### Clone

```bash
git clone https://github.com/im-tnyx/tio-world.git
cd tio-world
```

### Bootstrap workspace

```bash
melos bootstrap
```

### Run mobile app

```bash
cd apps/mobile
flutter pub get
flutter run
```

### Run tests

From the root:

```bash
melos run test
```

Or from mobile app:

```bash
cd apps/mobile
flutter test
```

### Analyze code

```bash
melos run analyze
```

### Format code

```bash
melos run format
```

---

## 🧪 Testing Policy

Minimum expectations:

- Unit tests for domain use cases.
- Unit tests for workout and nutrition engines.
- Widget tests for critical UI states.
- Repository tests with mocked data sources.
- Integration tests for onboarding, login, workout start, food logging, and sync-critical flows.
- Native watch tests for sensor, sync, and active workout workflows where feasible.

Recommended test structure:

```text
apps/mobile/test/
├── features/
│   ├── workout/
│   ├── nutrition/
│   └── onboarding/
└── shared/

packages/workout_engine/test/
packages/nutrition_engine/test/
packages/api_client/test/
```

---

## 📚 Documentation Index

| Document | Purpose |
| :--- | :--- |
| `docs/README.md` | Documentation map and reading path. |
| `docs/ARCHITECTURE.md` | Module boundaries, dependency rules, and ownership. |
| `docs/FLUTTER_GUIDE.md` | Flutter app structure, state, routing, and feature patterns. |
| `docs/WATCH_STRATEGY.md` | Wear OS and Apple Watch strategy. |
| `docs/API.md` | API contracts and backend integration notes. |
| `docs/TESTING_GUIDE.md` | Testing expectations and commands. |
| `docs/adr/` | Architecture Decision Records. |

---

## 🤝 Contributing

Before opening a PR:

- Work from a focused branch.
- Keep changes small and reviewable.
- Follow feature boundaries.
- Keep widgets dumb and state explicit.
- Do not call APIs directly from UI widgets.
- Keep watch apps native and lightweight.
- Do not commit secrets, generated builds, or local caches.
- Update docs when architecture, routing, persistence, sync, or ownership changes.

See `CONTRIBUTING.md` for the full contribution guide.

---

## 🛡️ Code of Conduct

This project follows a contributor-friendly Code of Conduct. Be respectful, specific, and constructive. Disagreement is fine. Personal attacks are not.

See `CODE_OF_CONDUCT.md`.

---

## 📜 License

`tio-world` is licensed under the MIT License. See `LICENSE`.

---

_Last Updated: 2026-07-05. Maintained by TNYX Engineering._
